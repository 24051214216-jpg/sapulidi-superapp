const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// 1. Koordinator mengajukan anggaran
exports.createBudgetRequest = async (req, res) => {
  try {
    const { eventId, judul, totalDiajukan, items } = req.body;
    const userId = req.user.id;

    if (req.user.role === 'WARGA') {
      return res.status(403).json({ message: "Hanya pengurus yang bisa mengajukan anggaran." });
    }

    const budget = await prisma.budgetRequest.create({
      data: {
        eventId,
        userId,
        judul,
        totalDiajukan,
        status: 'DIAJUKAN',
        items: {
          create: items // Array of { namaItem, qty, hargaSatuan }
        }
      },
      include: { items: true }
    });

    res.status(201).json({ message: "Pengajuan anggaran berhasil dibuat!", data: budget });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
  }
};

// 2. Ketua RT menyetujui / menolak
exports.approveBudget = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body; // 'DISETUJUI' atau 'DITOLAK'

    if (req.user.role !== 'KETUA_RT') {
      return res.status(403).json({ message: "Hanya Ketua RT yang bisa menyetujui anggaran." });
    }

    const budget = await prisma.budgetRequest.update({
      where: { id },
      data: { status }
    });

    res.status(200).json({ message: `Anggaran berhasil di-${status.toLowerCase()}`, data: budget });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
  }
};

// 3. Bendahara mencairkan dana (Uang keluar dari kas)
exports.disburseBudget = async (req, res) => {
  try {
    const { id } = req.params;

    if (req.user.role !== 'BENDAHARA') {
      return res.status(403).json({ message: "Hanya Bendahara yang bisa mencairkan dana." });
    }

    const budget = await prisma.budgetRequest.findUnique({ where: { id } });
    
    if (budget.status !== 'DISETUJUI') {
      return res.status(400).json({ message: "Anggaran belum disetujui Ketua RT!" });
    }

    // Transaksi Database: Ubah status anggaran & Catat di Buku Kas
    const result = await prisma.$transaction([
      prisma.budgetRequest.update({
        where: { id },
        data: { status: 'DICAIRKAN' }
      }),
      prisma.cashLedger.create({
        data: {
          tipe: 'KELUAR',
          kategori: 'Kegiatan RT',
          jumlah: budget.totalDiajukan,
          keterangan: `Pencairan dana: ${budget.judul}`,
          refId: budget.id
        }
      })
    ]);

    res.status(200).json({ message: "Dana berhasil dicairkan dan dicatat di Buku Kas!", data: result[0] });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
  }
};