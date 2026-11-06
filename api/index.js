require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const path = require('path');
const session = require('express-session');
const multer = require('multer');
const fs = require('fs');

// 1. Import Routes API
const authRoutes = require('./src/routes/authRoutes');
const eventRoutes = require('./src/routes/eventRoutes');
const attendanceRoutes = require('./src/routes/attendanceRoutes');
const budgetRoutes = require('./src/routes/budgetRoutes');
const newsRoutes = require('./src/routes/newsRoutes');

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(session({
  secret: 'rahasia_admin_sapulidi',
  resave: false,
  saveUninitialized: true
}));

// Setup Upload Foto
if (!fs.existsSync('./uploads')) { fs.mkdirSync('./uploads'); }
app.use('/uploads', express.static('uploads'));
const storage = multer.diskStorage({
  destination: function (req, file, cb) { cb(null, './uploads/'); },
  filename: function (req, file, cb) { cb(null, Date.now() + '-' + file.originalname.replace(/\s+/g, '-')); }
});
const upload = multer({ storage: storage });

app.post('/api/upload', upload.single('foto'), (req, res) => {
  if (!req.file) return res.status(400).json({ message: "Tidak ada file yang diupload" });
  const fileUrl = `http://localhost:3000/uploads/${req.file.filename}`;
  res.status(200).json({ message: "Upload berhasil", url: fileUrl });
});

// 2. Daftarkan Route API
app.use('/api/auth', authRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/news', newsRoutes);

// 3. Route Health Check
app.get('/', (req, res) => { res.json({ pesan: "API SapuLidi Berjalan!" }); });

// =====================================================================
// 4. ROUTE WEB ADMIN
// =====================================================================

// ---------- DASHBOARD PAGE ----------
app.get('/admin', async (req, res) => {
  try {
    // --- Statistik umum ---
    const totalWarga = await prisma.user.count({ where: { status: 'AKTIF' } });
    const totalEvent = await prisma.event.count();
    const kasMasuk = await prisma.cashLedger.aggregate({ where: { tipe: 'MASUK' }, _sum: { jumlah: true } });
    const kasKeluar = await prisma.cashLedger.aggregate({ where: { tipe: 'KELUAR' }, _sum: { jumlah: true } });
    const totalKas = (kasMasuk._sum.jumlah || 0) - (kasKeluar._sum.jumlah || 0);

    // --- Pengajuan Anggaran (status DIAJUKAN) ---
    const pengajuanAnggaran = await prisma.budgetRequest.findMany({
      where: { status: 'DIAJUKAN' },
      include: { event: true, user: true, items: true }
    });

    // --- Warga Pending (belum diaktifkan) ---
    const pendingUsers = await prisma.user.findMany({
      where: { status: 'PENDING' },
      include: { unit: true },
      orderBy: { createdAt: 'desc' }
    });

    // --- Galeri Verifikasi Absensi ---
    const attendances = await prisma.attendance.findMany({
      include: { user: { include: { unit: true } }, event: true },
      orderBy: { waktuAbsen: 'desc' },
      take: 50 // batasi 50 terbaru agar tidak lambat
    });

    res.render('dashboard', {
      totalWarga,
      totalEvent,
      totalKas,
      pengajuanAnggaran,
      pendingUsers,
      attendances,
    });
  } catch (error) {
    console.error('Admin dashboard error:', error);
    res.status(500).send('Terjadi kesalahan: ' + error.message);
  }
});

// ---------- ADMIN ACTION: Approve Budget ----------
app.post('/admin/approve-budget/:id', async (req, res) => {
  try {
    await prisma.budgetRequest.update({
      where: { id: req.params.id },
      data: { status: 'DISETUJUI' }
    });
    res.redirect('/admin');
  } catch (e) {
    console.error('Approve budget error:', e);
    res.status(500).send('Gagal menyetujui anggaran: ' + e.message);
  }
});

// ---------- ADMIN ACTION: Reject Budget ----------
app.post('/admin/reject-budget/:id', async (req, res) => {
  try {
    await prisma.budgetRequest.update({
      where: { id: req.params.id },
      data: { status: 'DITOLAK' }
    });
    res.redirect('/admin');
  } catch (e) {
    console.error('Reject budget error:', e);
    res.status(500).send('Gagal menolak anggaran: ' + e.message);
  }
});

// ---------- ADMIN ACTION: Activate User ----------
app.post('/admin/activate-user/:id', async (req, res) => {
  try {
    await prisma.user.update({
      where: { id: req.params.id },
      data: { status: 'AKTIF' }
    });
    res.redirect('/admin');
  } catch (e) {
    console.error('Activate user error:', e);
    res.status(500).send('Gagal mengaktifkan akun: ' + e.message);
  }
});

// ---------- ADMIN ACTION: Reject User ----------
app.post('/admin/reject-user/:id', async (req, res) => {
  try {
    await prisma.user.update({
      where: { id: req.params.id },
      data: { status: 'DITOLAK' }
    });
    res.redirect('/admin');
  } catch (e) {
    console.error('Reject user error:', e);
    res.status(500).send('Gagal menolak akun: ' + e.message);
  }
});

// =====================================================================
// 5. START SERVER
// =====================================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server SapuLidi berjalan di http://localhost:${PORT}`);
});
