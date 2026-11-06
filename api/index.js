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
const newsRoutes = require('./src/routes/newsRoutes'); // TAMBAHKAN INI

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

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

// 2. Daftarkan Route
app.use('/api/auth', authRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/news', newsRoutes); // TAMBAHKAN INI

// 3. Route Web Admin
app.get('/', (req, res) => { res.json({ pesan: "API SapuLidi Berjalan!" }); });

app.get('/admin', async (req, res) => {
  try {
    const totalWarga = await prisma.user.count({ where: { status: 'AKTIF' } });
    const totalEvent = await prisma.event.count();
    const kasMasuk = await prisma.cashLedger.aggregate({ where: { tipe: 'MASUK' }, _sum: { jumlah: true } });
    const kasKeluar = await prisma.cashLedger.aggregate({ where: { tipe: 'KELUAR' }, _sum: { jumlah: true } });
    const totalKas = (kasMasuk._sum.jumlah || 0) - (kasKeluar._sum.jumlah || 0);
    const pengajuanAnggaran = await prisma.budgetRequest.findMany({
      where: { status: 'DIAJUKAN' },
      include: { event: true }
    });

    res.render('dashboard', { totalWarga, totalEvent, totalKas, pengajuanAnggaran });
  } catch (error) {
    res.status(500).send("Terjadi kesalahan: " + error.message);
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server SapuLidi berjalan di http://localhost:${PORT}`);
});