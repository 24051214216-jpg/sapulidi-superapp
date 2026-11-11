const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// CATATAN DESAIN
// Model Asset di schema.prisma TIDAK punya kolom status (hanya namaAset & kondisi).
// Maka status alat DITURUNKAN dari tabel AssetLoan, bukan disimpan:
//   - alat 'DIPINJAM'  = ada AssetLoan dengan status 'DIPINJAM' untuk alat itu
//   - alat 'TERSEDIA'  = tidak ada AssetLoan berstatus 'DIPINJAM'
// Jadi "mengubah status alat" cukup dengan mengubah status AssetLoan.
const STATUS_DIPINJAM = 'DIPINJAM';
const STATUS_DIKEMBALIKAN = 'DIKEMBALIKAN';
const STATUS_TERSEDIA = 'TERSEDIA';

// Pengelola inventaris (konsisten dengan Fase 2: "Admin/RT" = Ketua RT & Bendahara).
const ROLE_PENGURUS = ['KETUA_RT', 'BENDAHARA'];

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
  // P2034 = konflik transaksi (dua orang meminjam alat yang sama pada saat bersamaan)
  if (error.code === 'P2034') {
    return res.status(409).json({ message: "Alat sedang diproses peminjam lain. Silakan coba lagi." });
  }
  return res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
}

// Transaksi Serializable + retry otomatis.
// Tanpa kolom status di Asset, kita tidak bisa "mengunci" alat lewat update bersyarat.
// Serializable membuat PostgreSQL menggagalkan salah satu dari dua peminjaman bersamaan;
// percobaan ulang membuat peminjam kedua melihat pinjaman pertama lalu menerima 409 yang jelas.
async function transaksiSerializable(fn, maksPercobaan = 3) {
  for (let percobaan = 1; ; percobaan++) {
    try {
      return await prisma.$transaction(fn, { isolationLevel: 'Serializable' });
    } catch (error) {
      if (error.code === 'P2034' && percobaan < maksPercobaan) continue;
      throw error;
    }
  }
}

const SELECT_ASET = { id: true, namaAset: true, kondisi: true };
const SELECT_EVENT = { id: true, judul: true };

// 1. Ketua RT / Bendahara menambah alat ke inventaris
exports.createAsset = async (req, res) => {
  try {
    if (!ROLE_PENGURUS.includes(req.user.role)) {
      throw new HttpError(403, "Hanya Ketua RT atau Bendahara yang bisa menambah inventaris.");
    }

    const { namaAset, kondisi } = req.body ?? {};

    if (typeof namaAset !== 'string' || !namaAset.trim()) {
      throw new HttpError(400, "namaAset wajib diisi.");
    }

    let kondisiAset = 'BAIK'; // default sesuai schema
    if (kondisi !== undefined && kondisi !== null && kondisi !== '') {
      if (typeof kondisi !== 'string' || !kondisi.trim()) {
        throw new HttpError(400, "kondisi harus berupa teks, contoh: BAIK.");
      }
      kondisiAset = kondisi.trim();
    }

    const asset = await prisma.asset.create({
      data: { namaAset: namaAset.trim(), kondisi: kondisiAset }
    });

    // Alat baru belum punya pinjaman, jadi otomatis TERSEDIA.
    res.status(201).json({
      message: "Alat berhasil ditambahkan ke inventaris!",
      data: { ...asset, status: STATUS_TERSEDIA }
    });
  } catch (error) {
    kirimError(res, error);
  }
};

// 2. Semua role: daftar alat yang TERSEDIA (tidak sedang dipinjam)
exports.getAvailableAssets = async (req, res) => {
  try {
    const assets = await prisma.asset.findMany({
      where: { loans: { none: { status: STATUS_DIPINJAM } } },
      orderBy: { namaAset: 'asc' }
    });

    res.status(200).json({
      message: "Daftar alat tersedia berhasil dimuat.",
      data: assets.map((a) => ({ ...a, status: STATUS_TERSEDIA }))
    });
  } catch (error) {
    kirimError(res, error);
  }
};

// 3. Warga mengajukan pinjaman alat untuk sebuah event
//    Body: { assetId, eventId, tglKembali }  -> tglKembali = rencana kembali (ISO 8601,
//    contoh dari Flutter: DateTime.toIso8601String())
exports.createLoan = async (req, res) => {
  try {
    const { assetId, eventId, tglKembali } = req.body ?? {};

    if (!assetId || typeof assetId !== 'string') {
      throw new HttpError(400, "assetId wajib diisi.");
    }
    if (!eventId || typeof eventId !== 'string') {
      throw new HttpError(400, "eventId wajib diisi.");
    }
    if (!tglKembali || typeof tglKembali !== 'string') {
      throw new HttpError(400, "tglKembali wajib diisi (format tanggal ISO 8601).");
    }
    const rencanaKembali = new Date(tglKembali);
    if (Number.isNaN(rencanaKembali.getTime())) {
      throw new HttpError(400, "tglKembali bukan tanggal yang valid.");
    }
    if (rencanaKembali <= new Date()) {
      throw new HttpError(400, "tglKembali harus berada di masa depan.");
    }

    // Kolom AssetLoan.peminjam adalah teks biasa (bukan relasi ke User), jadi simpan nama.
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { nama: true }
    });
    if (!user) throw new HttpError(401, "User tidak ditemukan.");

    const loan = await transaksiSerializable(async (tx) => {
      const asset = await tx.asset.findUnique({ where: { id: assetId } });
      if (!asset) throw new HttpError(404, "Alat tidak ditemukan.");

      const event = await tx.event.findUnique({ where: { id: eventId } });
      if (!event) throw new HttpError(404, "Event tidak ditemukan.");

      // Validasi ketersediaan: alat TERSEDIA = tidak ada pinjaman aktif.
      const aktif = await tx.assetLoan.findFirst({
        where: { assetId, status: STATUS_DIPINJAM }
      });
      if (aktif) throw new HttpError(409, "Alat sedang dipinjam dan belum tersedia.");

      // Membuat AssetLoan berstatus DIPINJAM = alat otomatis berstatus DIPINJAM.
      return tx.assetLoan.create({
        data: {
          assetId,
          eventId,
          peminjam: user.nama,
          tglKembali: rencanaKembali,
          status: STATUS_DIPINJAM
        },
        include: {
          asset: { select: SELECT_ASET },
          event: { select: SELECT_EVENT }
        }
      });
    });

    res.status(201).json({
      message: "Pinjaman berhasil diajukan! Status alat kini DIPINJAM.",
      data: loan
    });
  } catch (error) {
    kirimError(res, error);
  }
};

// 4. Ketua RT / Bendahara melihat semua peminjaman yang sedang aktif
exports.getActiveLoans = async (req, res) => {
  try {
    if (!ROLE_PENGURUS.includes(req.user.role)) {
      throw new HttpError(403, "Hanya Ketua RT atau Bendahara yang bisa melihat daftar peminjaman.");
    }

    const loans = await prisma.assetLoan.findMany({
      where: { status: STATUS_DIPINJAM },
      orderBy: { tglPinjam: 'desc' },
      include: {
        asset: { select: SELECT_ASET },
        event: { select: SELECT_EVENT }
      }
    });

    res.status(200).json({ message: "Daftar peminjaman aktif berhasil dimuat.", data: loans });
  } catch (error) {
    kirimError(res, error);
  }
};

// 5. Ketua RT / Bendahara menandai alat sudah dikembalikan
exports.returnLoan = async (req, res) => {
  try {
    if (!ROLE_PENGURUS.includes(req.user.role)) {
      throw new HttpError(403, "Hanya Ketua RT atau Bendahara yang bisa mencatat pengembalian alat.");
    }

    const { id } = req.params;

    const loan = await prisma.$transaction(async (tx) => {
      const ada = await tx.assetLoan.findUnique({ where: { id } });
      if (!ada) throw new HttpError(404, "Data peminjaman tidak ditemukan.");

      // Klaim atomik: hanya satu request yang bisa mengubah DIPINJAM -> DIKEMBALIKAN.
      // tglKembali ditimpa dengan waktu kembali SEBENARNYA (rencana kembali tidak tersimpan lagi).
      const klaim = await tx.assetLoan.updateMany({
        where: { id, status: STATUS_DIPINJAM },
        data: { status: STATUS_DIKEMBALIKAN, tglKembali: new Date() }
      });
      if (klaim.count === 0) {
        throw new HttpError(409, "Alat ini sudah dicatat dikembalikan sebelumnya.");
      }

      return tx.assetLoan.findUnique({
        where: { id },
        include: {
          asset: { select: SELECT_ASET },
          event: { select: SELECT_EVENT }
        }
      });
    });

    res.status(200).json({
      message: "Alat berhasil dikembalikan. Status alat kini TERSEDIA.",
      data: loan
    });
  } catch (error) {
    kirimError(res, error);
  }
};