const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'rahasia_sapulidi_super_app';

// --- REGISTER ---
exports.register = async (req, res) => {
  try {
    const { nama, noHp, password } = req.body;

    // Cek apakah No HP sudah terdaftar
    const existingUser = await prisma.user.findUnique({ where: { noHp } });
    if (existingUser) {
      return res.status(400).json({ message: "Nomor HP sudah terdaftar!" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Simpan ke database (status default: PENDING)
    const user = await prisma.user.create({
      data: {
        nama,
        noHp,
        password: hashedPassword,
        role: 'WARGA',
        status: 'PENDING'
      }
    });

    res.status(201).json({ 
      message: "Registrasi berhasil! Akun menunggu persetujuan Ketua RT.",
      data: { id: user.id, nama: user.nama, noHp: user.noHp }
    });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
  }
};

// --- LOGIN ---
exports.login = async (req, res) => {
  try {
    const { noHp, password } = req.body;

    // Cek user
    const user = await prisma.user.findUnique({ where: { noHp } });
    if (!user) {
      return res.status(404).json({ message: "User tidak ditemukan!" });
    }

    // Cek apakah akun sudah di-approve (AKTIF)
    if (user.status !== 'AKTIF') {
      return res.status(403).json({ message: "Akun Anda belum disetujui oleh Ketua RT." });
    }

    // Cek password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: "Password salah!" });
    }

    // Buat Token JWT
    const token = jwt.sign(
      { id: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: '1d' } // Token berlaku 1 hari
    );

    res.status(200).json({
      message: "Login berhasil!",
      token,
      user: { id: user.id, nama: user.nama, role: user.role }
    });
  } catch (error) {
    res.status(500).json({ message: "Terjadi kesalahan server", error: error.message });
  }
};