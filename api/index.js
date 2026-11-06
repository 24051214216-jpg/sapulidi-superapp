require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');

// Import Route
const authRoutes = require('./src/routes/authRoutes');

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ pesan: "Selamat datang di API SapuLidi SuperApp!" });
});

// Gunakan Route Auth
app.use('/api/auth', authRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server SapuLidi berjalan di http://localhost:${PORT}`);
});