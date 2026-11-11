const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Pengirim pengumuman (konsisten dengan fase sebelumnya).
const ROLE_PENGURUS = ['KETUA_RT', 'BENDAHARA'];

// Penerima broadcast sesuai spesifikasi: role WARGA dengan status AKTIF.
// Role lain (KOORDINATOR, BENDAHARA, KETUA_RT) TIDAK ikut menerima.
// Untuk memasukkan mereka, tambahkan role-nya di sini, contoh: ['WARGA', 'KOORDINATOR'].
const ROLE_PENERIMA = ['WARGA'];

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

// 1. Ketua RT / Bendahara mengirim pengumuman ke semua warga aktif
exports.broadcast = async (req, res) => {
  try {
    if (!ROLE_PENGURUS.includes(req.user.role)) {
      throw new HttpError(403, "Hanya Ketua RT atau Bendahara yang bisa mengirim pengumuman.");
    }

    const { judul, pesan } = req.body ?? {};
    const judulBersih = teksWajib(judul, 'judul', 100);
    const pesanBersih = teksWajib(pesan, 'pesan', 1000);

    const penerima = await prisma.user.findMany({
      where: { role: { in: ROLE_PENERIMA }, status: 'AKTIF' },
      select: { id: true }
    });

    if (penerima.length === 0) {
      return res.status(200).json({
        message: "Tidak ada warga aktif yang dapat menerima pengumuman. Tidak ada notifikasi yang dikirim.",
        jumlahPenerima: 0
      });
    }

    // Satu perintah INSERT untuk semua penerima (atomik: semua berhasil atau tidak sama sekali).
    const hasil = await prisma.notification.createMany({
      data: penerima.map((u) => ({
        userId: u.id,
        judul: judulBersih,
        pesan: pesanBersih
      }))
    });

    res.status(201).json({
      message: `Pengumuman berhasil dikirim ke ${hasil.count} warga!`,
      jumlahPenerima: hasil.count
    });
  } catch (error) {
    kirimError(res, error);
  }
};

// 2. Semua role: melihat notifikasi milik sendiri (terbaru di atas)
exports.getMyNotifications = async (req, res) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' }
    });

    res.status(200).json({
      message: "Notifikasi berhasil dimuat.",
      belumDibaca: notifications.filter((n) => !n.isRead).length,
      data: notifications
    });
  } catch (error) {
    kirimError(res, error);
  }
};

// 3. Semua role: menandai notifikasi MILIK SENDIRI sebagai sudah dibaca
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;

    // Kepemilikan divalidasi di dalam query (id DAN userId dari token), bukan sesudahnya.
    // Notifikasi milik orang lain dan id yang tidak ada sama-sama menghasilkan 404,
    // jadi keberadaan notifikasi orang lain tidak bocor.
    const hasil = await prisma.notification.updateMany({
      where: { id, userId: req.user.id },
      data: { isRead: true }
    });

    if (hasil.count === 0) {
      throw new HttpError(404, "Notifikasi tidak ditemukan.");
    }

    const notification = await prisma.notification.findUnique({ where: { id } });

    res.status(200).json({ message: "Notifikasi ditandai sudah dibaca.", data: notification });
  } catch (error) {
    kirimError(res, error);
  }
};