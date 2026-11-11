require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const path = require('path');
const session = require('express-session');
const multer = require('multer');
const fs = require('fs');

// =====================================================================
// 1. IMPORT ROUTES & MIDDLEWARE
// =====================================================================
const authRoutes = require('./src/routes/authRoutes');
const eventRoutes = require('./src/routes/eventRoutes');
const attendanceRoutes = require('./src/routes/attendanceRoutes');
const budgetRoutes = require('./src/routes/budgetRoutes');
const newsRoutes = require('./src/routes/newsRoutes');
const financeRoutes = require('./src/routes/financeRoutes');
const assetRoutes = require('./src/routes/assetRoutes');
const adminWargaRoutes = require('./src/routes/adminWargaRoutes'); // <-- FASE 4 IMPORT

const { verifyToken } = require('./src/middlewares/verifyToken');

const app = express();
const prisma = new PrismaClient();

// =====================================================================
// 2. MIDDLEWARE DASAR
// =====================================================================
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

// =====================================================================
// 3. SETUP UPLOAD FOTO (MULTER)
// =====================================================================
if (!fs.existsSync('./uploads')) { fs.mkdirSync('./uploads'); }
app.use('/uploads', express.static('uploads'));

const storage = multer.diskStorage({
  destination: function (req, file, cb) { cb(null, './uploads/'); },
  filename: function (req, file, cb) { cb(null, Date.now() + '-' + file.originalname.replace(/\s+/g, '-')); }
});
const upload = multer({ storage: storage });

// Endpoint Upload (Wajib Login)
app.post('/api/upload', verifyToken, upload.single('foto'), (req, res) => {
  if (!req.file) return res.status(400).json({ message: "Tidak ada file yang diupload" });
  const fileUrl = `/uploads/${req.file.filename}`;
  res.status(200).json({ message: "Upload berhasil", url: fileUrl });
});

// =====================================================================
// 4. DAFTARKAN ROUTE API
// =====================================================================
app.use('/api/auth', authRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/news', newsRoutes);
app.use('/api/finance', financeRoutes);
app.use('/api/assets', assetRoutes);
app.use('/api/admin-warga', adminWargaRoutes); // <-- FASE 4 DAFTARKAN ROUTE

// Route Health Check
app.get('/', (req, res) => { res.json({ pesan: "API SapuLidi Berjalan!" }); });

// =====================================================================
// 5. ROUTE WEB ADMIN (EJS)
// =====================================================================
app.get('/admin', async (req, res) => {
  try {
    const totalWarga = await prisma.user.count({ where: { status: 'AKTIF' } });
    const totalEvent = await prisma.event.count();
    
    const kasMasuk = await prisma.cashLedger.aggregate({ where: { tipe: 'MASUK' }, _sum: { jumlah: true } });
    const kasKeluar = await prisma.cashLedger.aggregate({ where: { tipe: 'KELUAR' }, _sum: { jumlah: true } });
    const totalKas = (kasMasuk._sum.jumlah || 0) - (kasKeluar._sum.jumlah || 0);

    const pengajuanAnggaran = await prisma.budgetRequest.findMany({
      where: { status: 'DIAJUKAN' },
      include: { event: true, user: true, items: true }
    });

    const pendingUsers = await prisma.user.findMany({
      where: { status: 'PENDING' },
      include: { unit: true },
      orderBy: { createdAt: 'desc' }
    });

    const attendances = await prisma.attendance.findMany({
      include: { user: { include: { unit: true } }, event: true },
      orderBy: { waktuAbsen: 'desc' },
      take: 50
    });

    res.render('dashboard', { totalWarga, totalEvent, totalKas, pengajuanAnggaran, pendingUsers, attendances });
  } catch (error) {
    console.error('Admin dashboard error:', error);
    res.status(500).send('Terjadi kesalahan: ' + error.message);
  }
});

// Aksi Web Admin: Approve Budget
app.post('/admin/approve-budget/:id', async (req, res) => {
  try {
    await prisma.budgetRequest.update({ where: { id: req.params.id }, data: { status: 'DISETUJUI' } });
    res.redirect('/admin');
  } catch (e) { res.status(500).send('Gagal menyetujui anggaran'); }
});

// Aksi Web Admin: Reject Budget
app.post('/admin/reject-budget/:id', async (req, res) => {
  try {
    await prisma.budgetRequest.update({ where: { id: req.params.id }, data: { status: 'DITOLAK' } });
    res.redirect('/admin');
  } catch (e) { res.status(500).send('Gagal menolak anggaran'); }
});

// Aksi Web Admin: Activate User
app.post('/admin/activate-user/:id', async (req, res) => {
  try {
    await prisma.user.update({ where: { id: req.params.id }, data: { status: 'AKTIF' } });
    res.redirect('/admin');
  } catch (e) { res.status(500).send('Gagal mengaktifkan akun'); }
});

// Aksi Web Admin: Reject User
app.post('/admin/reject-user/:id', async (req, res) => {
  try {
    await prisma.user.update({ where: { id: req.params.id }, data: { status: 'DITOLAK' } });
    res.redirect('/admin');
  } catch (e) { res.status(500).send('Gagal menolak akun'); }
});

// =====================================================================
// 6. JALANKAN SERVER
// =====================================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server SapuLidi berjalan di http://localhost:${PORT}`);
});