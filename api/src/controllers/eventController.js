const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// --- BUAT EVENT BARU (Khusus Pengurus) ---
exports.createEvent = async (req, res) => {
  try {
    const { judul, deskripsi, kategori, latCenter, lngCenter, radiusM, mulaiAt, selesaiAt } = req.body;
    
    // Cek apakah yang membuat adalah pengurus (bukan WARGA biasa)
    if (req.user.role === 'WARGA') {
      return res.status(403).json({ message: "Akses ditolak. Hanya pengurus yang bisa membuat event." });
    }

    const newEvent = await prisma.event.create({
      data: {
        judul,
        deskripsi,
        kategori,
        latCenter,
        lngCenter,
        radiusM: radiusM || 100, // Default radius 100 meter
        mulaiAt: new Date(mulaiAt),
        selesaiAt: new Date(selesaiAt),
        status: 'DRAFT' // Awalnya draft, nanti bisa di-publish
      }
    });

    res.status(201).json({ message: "Event kerja bakti berhasil dibuat!", data: newEvent });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
  }
};

// --- LIHAT SEMUA EVENT (Bisa diakses semua warga yang login) ---
exports.getAllEvents = async (req, res) => {
  try {
    const events = await prisma.event.findMany({
      orderBy: { mulaiAt: 'desc' } // Urutkan dari yang terbaru
    });
    res.status(200).json({ data: events });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
  }
};