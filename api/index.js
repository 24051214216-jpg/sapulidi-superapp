require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const path = require('path');
const session = require('express-session');

// 1. Import Routes API
const authRoutes = require('./src/routes/authRoutes');
const eventRoutes = require('./src/routes/eventRoutes');
const attendanceRoutes = require('./src/routes/attendanceRoutes');
const budgetRoutes = require('./src/routes/budgetRoutes');

const app = express();
const prisma = new PrismaClient();

// 2. Middleware Dasar
app.use(cors());
app.use(express.json());

// 3. Setup EJS (Template Web Admin) & Session
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(session({
  secret: 'rahasia_admin_sapulidi',
  resave: false,
  saveUninitialized: true
}));

// 4. Daftarkan Route API
app.use('/api/auth', authRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/budgets', budgetRoutes);

// 5. Route API Dasar (Tes)
app.get('/', (req, res) => {
  res.json({ pesan: "Selamat datang di API SapuLidi SuperApp!" });
});

// 6. Route Web Admin (Mengambil data asli dari database)
app.get('/admin', async (req, res) => {
  try {
    // a. Hitung total warga aktif
    const totalWarga = await prisma.user.count({ where: { status: 'AKTIF' } });
    
    // b. Hitung total Event
    const totalEvent = await prisma.event.count();
    
    // c. Hitung total Kas (Pemasukan - Pengeluaran)
    const kasMasuk = await prisma.cashLedger.aggregate({ where: { tipe: 'MASUK' }, _sum: { jumlah: true } });
    const kasKeluar = await prisma.cashLedger.aggregate({ where: { tipe: 'KELUAR' }, _sum: { jumlah: true } });
    const totalKas = (kasMasuk._sum.jumlah || 0) - (kasKeluar._sum.jumlah || 0);

    // d. Ambil daftar pengajuan anggaran yang butuh persetujuan (Status: DIAJUKAN)
    const pengajuanAnggaran = await prisma.budgetRequest.findMany({
      where: { status: 'DIAJUKAN' },
      include: { event: true } // Ambil data event terkait
    });

    // Kirim semua data ke file EJS
    res.render('dashboard', { 
      totalWarga, 
      totalEvent, 
      totalKas, 
      pengajuanAnggaran 
    });
  } catch (error) {
    res.status(500).send("Terjadi kesalahan saat memuat dashboard: " + error.message);
  }
});

// 7. Jalankan Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server SapuLidi berjalan di http://localhost:${PORT}`);
});