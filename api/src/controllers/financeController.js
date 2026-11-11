const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Role pengurus yang boleh mengelola keuangan.
// (Schema hanya punya: WARGA, KOORDINATOR, BENDAHARA, KETUA_RT - tidak ada role "ADMIN".)
const ROLE_KEUANGAN = ['BENDAHARA', 'KETUA_RT'];
const PERIODE_REGEX = /^\d{4}-(0[1-9]|1[0-2])$/; // contoh: "2026-11"
const STATUS_VERIFIKASI = ['TERVERIFIKASI', 'DITOLAK'];

// Error yang membawa status HTTP. Dilempar dari dalam transaksi agar otomatis rollback.
class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function kirimError(res, error) {
  if (error instanceof HttpError) {
    return res.status(error.status).json({ message: error.message });
  }
  return res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
}

// Token JWT hanya berisi { id, role }, jadi unitId harus diambil dari database.
async function ambilUnitId(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { unitId: true }
  });
  return user ? user.unitId : null;
}

// 1. Bendahara / Ketua RT membuat tagihan iuran bulanan untuk satu unit
exports.createInvoice = async (req, res) => {
  try {
    if (!ROLE_KEUANGAN.includes(req.user.role)) {
      throw new HttpError(403, "Hanya Bendahara atau Ketua RT yang bisa membuat tagihan.");
    }

    const { unitId, periode, jumlah } = req.body ?? {};
    const nominal = typeof jumlah === 'string' ? Number(jumlah.trim()) : jumlah;

    if (!unitId || typeof unitId !== 'string') {
      throw new HttpError(400, "unitId wajib diisi.");
    }
    if (typeof periode !== 'string' || !PERIODE_REGEX.test(periode)) {
      throw new HttpError(400, "periode wajib berformat YYYY-MM, contoh: 2026-11.");
    }
    if (typeof nominal !== 'number' || !Number.isFinite(nominal) || nominal <= 0) {
      throw new HttpError(400, "jumlah harus berupa angka lebih dari 0.");
    }

    const unit = await prisma.unit.findUnique({ where: { id: unitId } });
    if (!unit) throw new HttpError(404, "Unit tidak ditemukan.");

    // Schema tidak punya unique (unitId, periode), jadi duplikat dicegah di level aplikasi.
    const sudahAda = await prisma.invoice.findFirst({ where: { unitId, periode } });
    if (sudahAda) {
      throw new HttpError(409, `Tagihan periode ${periode} untuk unit ini sudah ada.`);
    }

    const invoice = await prisma.invoice.create({
      data: { unitId, periode, jumlah: nominal, status: 'BELUM_BAYAR' },
      include: { unit: { select: { blok: true, nomor: true } } }
    });

    res.status(201).json({ message: "Tagihan iuran berhasil dibuat!", data: invoice });
  } catch (error) {
    kirimError(res, error);
  }
};

// 2. Warga melihat tagihan unitnya; Bendahara / Ketua RT melihat semua tagihan
//    Filter opsional: ?periode=2026-11&status=BELUM_BAYAR
exports.getInvoices = async (req, res) => {
  try {
    const { periode, status } = req.query;
    const where = {};
    if (typeof periode === 'string' && periode) where.periode = periode;
    if (typeof status === 'string' && status) where.status = status;

    if (!ROLE_KEUANGAN.includes(req.user.role)) {
      const unitId = await ambilUnitId(req.user.id);
      if (!unitId) {
        return res.status(200).json({
          message: "Akun Anda belum terhubung ke unit rumah. Hubungi pengurus RT.",
          data: []
        });
      }
      where.unitId = unitId;
    }

    const invoices = await prisma.invoice.findMany({
      where,
      orderBy: { periode: 'desc' },
      include: {
        unit: { select: { blok: true, nomor: true } },
        payments: {
          orderBy: { createdAt: 'desc' },
          include: { user: { select: { id: true, nama: true } } }
        }
      }
    });

    res.status(200).json({ message: "Data tagihan berhasil dimuat.", data: invoices });
  } catch (error) {
    kirimError(res, error);
  }
};

// 3. Warga mengunggah bukti transfer (status Payment: MENUNGGU)
exports.createPayment = async (req, res) => {
  try {
    const { invoiceId, buktiPath } = req.body ?? {};

    if (!invoiceId || typeof invoiceId !== 'string') {
      throw new HttpError(400, "invoiceId wajib diisi.");
    }
    if (!buktiPath || typeof buktiPath !== 'string' || !buktiPath.trim()) {
      throw new HttpError(400, "buktiPath (bukti transfer) wajib diisi.");
    }

    const unitId = await ambilUnitId(req.user.id);
    if (!unitId) {
      throw new HttpError(403, "Akun Anda belum terhubung ke unit rumah. Hubungi pengurus RT.");
    }

    const invoice = await prisma.invoice.findUnique({ where: { id: invoiceId } });
    if (!invoice) throw new HttpError(404, "Tagihan tidak ditemukan.");

    // Cegah warga membayar/mengklaim tagihan milik unit lain.
    if (invoice.unitId !== unitId) {
      throw new HttpError(403, "Tagihan ini bukan milik unit Anda.");
    }
    if (invoice.status === 'LUNAS') {
      throw new HttpError(400, "Tagihan ini sudah lunas.");
    }

    // Satu bukti aktif per tagihan. Jika yang lama DITOLAK, warga boleh upload ulang.
    const menunggu = await prisma.payment.findFirst({
      where: { invoiceId, status: 'MENUNGGU' }
    });
    if (menunggu) {
      throw new HttpError(409, "Bukti pembayaran untuk tagihan ini masih menunggu verifikasi.");
    }

    const payment = await prisma.payment.create({
      data: {
        invoiceId,
        userId: req.user.id,
        buktiPath: buktiPath.trim(),
        status: 'MENUNGGU'
      }
    });

    res.status(201).json({
      message: "Bukti pembayaran terkirim! Menunggu verifikasi Bendahara.",
      data: payment
    });
  } catch (error) {
    kirimError(res, error);
  }
};

// 4. Bendahara memverifikasi pembayaran
//    Body: { "status": "TERVERIFIKASI" }  atau  { "status": "DITOLAK" }
exports.verifyPayment = async (req, res) => {
  try {
    if (req.user.role !== 'BENDAHARA') {
      throw new HttpError(403, "Hanya Bendahara yang bisa memverifikasi pembayaran.");
    }

    const { id } = req.params;
    const { status } = req.body ?? {};
    if (!STATUS_VERIFIKASI.includes(status)) {
      throw new HttpError(400, "status harus 'TERVERIFIKASI' atau 'DITOLAK'.");
    }

    const hasil = await prisma.$transaction(async (tx) => {
      const payment = await tx.payment.findUnique({
        where: { id },
        include: { invoice: { include: { unit: true } } }
      });
      if (!payment) throw new HttpError(404, "Pembayaran tidak ditemukan.");

      // Klaim atomik: hanya SATU request yang bisa mengubah MENUNGGU -> status final.
      // Mencegah klik ganda / dua pengurus yang memverifikasi bersamaan (kas tercatat dobel).
      const klaim = await tx.payment.updateMany({
        where: { id, status: 'MENUNGGU' },
        data: { status }
      });
      if (klaim.count === 0) {
        throw new HttpError(409, "Pembayaran ini sudah diproses sebelumnya.");
      }

      if (status === 'TERVERIFIKASI') {
        // Hanya lanjut jika invoice belum LUNAS (mis. sudah dilunasi lewat bukti lain).
        const lunas = await tx.invoice.updateMany({
          where: { id: payment.invoiceId, status: { not: 'LUNAS' } },
          data: { status: 'LUNAS' }
        });
        if (lunas.count === 0) {
          throw new HttpError(409, "Tagihan ini sudah lunas lewat pembayaran lain.");
        }

        const { periode, jumlah, unit } = payment.invoice;
        await tx.cashLedger.create({
          data: {
            tipe: 'MASUK',
            kategori: 'Iuran',
            jumlah,
            keterangan: `Iuran ${periode} - Blok ${unit.blok} No. ${unit.nomor}`,
            refId: payment.invoiceId
          }
        });
      }

      return tx.payment.findUnique({ where: { id }, include: { invoice: true } });
    });

    const pesan = status === 'TERVERIFIKASI'
      ? "Pembayaran terverifikasi. Tagihan LUNAS dan tercatat di Buku Kas!"
      : "Pembayaran ditolak. Warga dapat mengunggah ulang bukti transfer.";

    res.status(200).json({ message: pesan, data: hasil });
  } catch (error) {
    kirimError(res, error);
  }
};

// 5. Bendahara / Ketua RT melihat seluruh riwayat Buku Kas
exports.getCash = async (req, res) => {
  try {
    if (!ROLE_KEUANGAN.includes(req.user.role)) {
      throw new HttpError(403, "Hanya Bendahara atau Ketua RT yang bisa melihat Buku Kas.");
    }

    const [riwayat, masuk, keluar] = await Promise.all([
      prisma.cashLedger.findMany({ orderBy: { tanggal: 'desc' } }),
      prisma.cashLedger.aggregate({ where: { tipe: 'MASUK' }, _sum: { jumlah: true } }),
      prisma.cashLedger.aggregate({ where: { tipe: 'KELUAR' }, _sum: { jumlah: true } })
    ]);

    const totalMasuk = masuk._sum.jumlah || 0;
    const totalKeluar = keluar._sum.jumlah || 0;

    res.status(200).json({
      message: "Riwayat Buku Kas berhasil dimuat.",
      ringkasan: { totalMasuk, totalKeluar, saldo: totalMasuk - totalKeluar },
      data: riwayat
    });
  } catch (error) {
    kirimError(res, error);
  }
};