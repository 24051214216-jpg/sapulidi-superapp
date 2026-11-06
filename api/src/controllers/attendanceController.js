const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Rumus Haversine untuk menghitung jarak (dalam meter) antara 2 titik koordinat
function hitungJarak(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Radius bumi dalam meter
  const p1 = lat1 * Math.PI / 180;
  const p2 = lat2 * Math.PI / 180;
  const deltaP = (lat2 - lat1) * Math.PI / 180;
  const deltaL = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(deltaP / 2) * Math.sin(deltaP / 2) +
            Math.cos(p1) * Math.cos(p2) *
            Math.sin(deltaL / 2) * Math.sin(deltaL / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Hasil dalam meter
}

exports.absenKerjaBakti = async (req, res) => {
  try {
    const { eventId, lat, lng, fotoPath, isMock } = req.body;
    const userId = req.user.id; // Didapat dari Token JWT

    // 1. Cek apakah event ada
    const event = await prisma.event.findUnique({ where: { id: eventId } });
    if (!event) return res.status(404).json({ message: "Event tidak ditemukan!" });

    // 2. Hitung jarak warga ke titik pusat event
    const jarak = hitungJarak(lat, lng, event.latCenter, event.lngCenter);

    // 3. Validasi: Apakah di luar radius?
    if (jarak > event.radiusM) {
      return res.status(400).json({ 
        message: `Absen gagal! Anda berada di luar radius (${Math.round(jarak)}m dari lokasi, maksimal ${event.radiusM}m).` 
      });
    }

    // 4. Validasi: Mock Location (Fake GPS)
    if (isMock) {
      return res.status(400).json({ message: "Absen gagal! Terdeteksi Fake GPS." });
    }

    // 5. Simpan Absensi
    const absensi = await prisma.attendance.create({
      data: {
        eventId,
        userId,
        lat,
        lng,
        jarakM: Math.round(jarak),
        fotoPath,
        status: 'HADIR'
      }
    });

    res.status(201).json({ 
      message: "Absen berhasil! Terima kasih sudah hadir.", 
      data: absensi 
    });

  } catch (error) {
    // Tangkap error jika warga absen 2 kali di event yang sama
    if (error.code === 'P2002') {
      return res.status(400).json({ message: "Anda sudah melakukan absen untuk event ini." });
    }
    res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
  }
};