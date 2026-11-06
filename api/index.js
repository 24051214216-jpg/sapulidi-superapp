require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');

const authRoutes = require('./src/routes/authRoutes');
const eventRoutes = require('./src/routes/eventRoutes'); // TAMBAHKAN INI

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ pesan: "Selamat datang di API SapuLidi SuperApp!" });
});

app.use('/api/auth', authRoutes);
app.use('/api/events', eventRoutes); // TAMBAHKAN INI

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server SapuLidi berjalan di http://localhost:${PORT}`);
  const authRoutes = require('./src/routes/authRoutes');
const eventRoutes = require('./src/routes/eventRoutes');
const attendanceRoutes = require('./src/routes/attendanceRoutes'); // TAMBAHKAN INI

// ... (kode sebelumnya)
app.use('/api/auth', authRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/attendance', attendanceRoutes); // TAMBAHKAN INI
});