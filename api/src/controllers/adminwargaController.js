const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// "Admin/RT" = Ketua RT & Bendahara (konsisten dengan Fase 2 dan 3).
// Jika persetujuan surat ingin dibatasi hanya Ketua RT, ubah konstanta ini.
const ROLE_PENGURUS = ['KETUA_RT', 'BENDAHARA'];

const STATUS_SURAT = ['PENDING', 'DISETUJUI', 'DITOLAK']; // enum LetterStatus di schema
const NIK_REGEX = /^\d{16}$/; // longgarkan di sini jika perlu menerima tamu WNA / anak tanpa KTP

// ISO 8601: tanggal saja ("2026-11-15") ATAU tanggal+jam DENGAN zona waktu
// ("2026-11-15T10:00:00Z" / "2026-11-15T17:00:00+07:00").
// Jam tanpa zona sengaja ditolak karena akan dibaca sebagai waktu lokal SERVER (bisa geser berjam-jam).
const ISO_8601 = /^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}(:\d{2}(\.\d{1,9})?)?(Z|[+-]\d{2}:\d{2}))?$/;

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

function pastikanPengurus(req, pesan) {
  if (!ROLE_PENGURUS.includes(req.user.role)) {
    throw new HttpError(403, pesan);
  }
}

function teksWajib(nilai, namaField, maks) {
  if (typeof nilai !== 'string' || !nilai.trim()) {
    throw new HttpError(400, `${namaField} wajib diisi.`);
  }
  const bersih = nilai.trim();
  if (bersih.length > maks) {
    throw new HttpError(400, `${namaField} maksimal ${maks} karakter.`);
  }
  return bersih;
}

function parseTanggalISO(nilai, namaField) {
  const contoh = "contoh: 2026-11-15T10:00:00Z atau 2026-11-15";
  if (typeof nilai !== 'string' || !ISO_8601.test(nilai.trim())) {
    throw new HttpError(400, `${namaField} wajib berformat ISO 8601 dengan zona waktu (${contoh}).`);
  }
  const teks = nilai.trim();

  // Date JS diam-diam mengubah "2026-02-31" menjadi 3 Maret, jadi bagian tanggal dicek manual.
  const [th, bl, tg] = teks.slice(0, 10).split('-').map(Number);
  const cek = new Date(Date.UTC(th, bl - 1, tg));
  if (cek.getUTCFullYear() !== th || cek.getUTCMonth() !== bl - 1 || cek.getUTCDate() !== tg) {
    throw new HttpError(400, `${namaField} bukan tanggal yang valid.`);
  }

  const tanggal = new Date(teks);
  if (Number.isNaN(tanggal.getTime())) {
    throw new HttpError(400, `${namaField} bukan tanggal yang valid.`);
  }
  return tanggal;
}

const INCLUDE_PELAPOR = {
  user: {
    select: {
      id: true,
      nama: true,
      unit: { select: { blok: true, nomor: true } }
    }
  }
};

// 1. Warga melaporkan tamu yang menginap
exports.createGuest = async (req, res) => {
  try {
    const { namaTamu, noKtpTamu, hubungan, mulaiMenginap, selesaiMenginap } = req.body ?? {};

    const nama = teksWajib(namaTamu, 'namaTamu', 100);
    const relasi = teksWajib(hubungan, 'hubungan', 50);

    // Harus string: angka 16 digit di JSON bisa kehilangan presisi di sisi klien/server.
    if (typeof noKtpTamu !== 'string' || !NIK_REGEX.test(noKtpTamu.trim())) {
      throw new HttpError(400, "noKtpTamu wajib berupa teks 16 digit angka (kirim sebagai string, bukan angka).");
    }

    const mulai = parseTanggalISO(mulaiMenginap, 'mulaiMenginap');
    const selesai = parseTanggalISO(selesaiMenginap, 'selesaiMenginap');
    if (selesai <= mulai) {
      throw new HttpError(400, "selesaiMenginap harus setelah mulaiMenginap.");
    }

    const guest = await prisma.guestLog.create({
      data: {
        userId: req.user.id,
        namaTamu: nama,
        noKtpTamu: noKtpTamu.trim(),
        hubungan: relasi,
        mulaiMenginap: mulai,
        selesaiMenginap: selesai
      }
    });

    res.status(201).json({ message: "Laporan tamu berhasil dikirim!", data: guest });
  } catch (error) {
    kirimError(res, error);
  }
};

// 2. Ketua RT / Bendahara melihat semua tamu yang dilaporkan
exports.getGuests = async (req, res) => {
  try {
    pastikanPengurus(req, "Hanya Ketua RT atau Bendahara yang bisa melihat daftar tamu.");

    const guests = await prisma.guestLog.findMany({
      orderBy: { createdAt: 'desc' },
      include: INCLUDE_PELAPOR
    });

    res.status(200).json({ message: "Daftar tamu berhasil dimuat.", data: guests });
  } catch (error) {
    kirimError(res, error);
  }
};

// 3. Warga mengajukan surat (status awal: PENDING)
exports.createLetter = async (req, res) => {
  try {
    const { jenisSurat, keperluan } = req.body ?? {};

    const jenis = teksWajib(jenisSurat, 'jenisSurat', 50);
    const perlu = teksWajib(keperluan, 'keperluan', 500);

    const letter = await prisma.letterRequest.create({
      data: {
        userId: req.user.id,
        jenisSurat: jenis,
        keperluan: perlu,
        status: 'PENDING'
      }
    });

    res.status(201).json({
      message: "Pengajuan surat berhasil dikirim! Menunggu persetujuan pengurus RT.",
      data: letter
    });
  } catch (error) {
    kirimError(res, error);
  }
};

// 4. Ketua RT / Bendahara melihat daftar pengajuan surat
//    Filter opsional: ?status=PENDING | DISETUJUI | DITOLAK
exports.getLetters = async (req, res) => {
  try {
    pastikanPengurus(req, "Hanya Ketua RT atau Bendahara yang bisa melihat pengajuan surat.");

    const { status } = req.query;
    const where = {};
    if (status !== undefined && status !== '') {
      if (typeof status !== 'string' || !STATUS_SURAT.includes(status)) {
        throw new HttpError(400, `status harus salah satu dari: ${STATUS_SURAT.join(', ')}.`);
      }
      where.status = status;
    }

    const letters = await prisma.letterRequest.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: INCLUDE_PELAPOR
    });

    res.status(200).json({ message: "Daftar pengajuan surat berhasil dimuat.", data: letters });
  } catch (error) {
    kirimError(res, error);
  }
};

// Dipakai bersama oleh approve & reject. Hanya surat berstatus PENDING yang boleh diproses.
async function prosesSurat(req, res, statusBaru, pesanSukses) {
  try {
    pastikanPengurus(req, "Hanya Ketua RT atau Bendahara yang bisa memproses pengajuan surat.");

    const { id } = req.params;

    // Klaim atomik: hanya satu request yang bisa mengubah PENDING -> status final
    // (mencegah approve dan reject berjalan bersamaan dan saling menimpa).
    const klaim = await prisma.letterRequest.updateMany({
      where: { id, status: 'PENDING' },
      data: { status: statusBaru }
    });

    if (klaim.count === 0) {
      const ada = await prisma.letterRequest.findUnique({ where: { id } });
      if (!ada) throw new HttpError(404, "Pengajuan surat tidak ditemukan.");
      throw new HttpError(409, `Pengajuan ini sudah diproses sebelumnya (status: ${ada.status}).`);
    }

    const letter = await prisma.letterRequest.findUnique({
      where: { id },
      include: INCLUDE_PELAPOR
    });

    res.status(200).json({ message: pesanSukses, data: letter });
  } catch (error) {
    kirimError(res, error);
  }
}

// 5. Menyetujui surat
exports.approveLetter = (req, res) =>
  prosesSurat(req, res, 'DISETUJUI', "Pengajuan surat berhasil disetujui!");

// 6. Menolak surat
exports.rejectLetter = (req, res) =>
  prosesSurat(req, res, 'DITOLAK', "Pengajuan surat ditolak.");