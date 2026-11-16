const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const UserRepository = require('../repositories/UserRepository');

const JWT_SECRET = process.env.JWT_SECRET || 'rahasia_sapulidi_super_app';

class AuthService {
  async register({ nama, nik, noHp, password, blokRumah, noRumah }) {
    // 1. Cek apakah No HP / NIK sudah terdaftar
    const existingHp = await UserRepository.findByNoHp(noHp);
    if (existingHp) throw new Error('Nomor HP sudah terdaftar');

    const existingNik = await UserRepository.findByNik(nik);
    if (existingNik) throw new Error('NIK sudah terdaftar');

    // 2. Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // 3. Simpan ke database (Role default WARGA, Status PENDING)
    const newUser = await UserRepository.createUser({
      nama,
      nik,
      noHp,
      password: hashedPassword,
      blokRumah,
      noRumah,
      role: 'WARGA',
      status: 'PENDING'
    });

    return newUser;
  }

  async login(noHp, password) {
    // 1. Cari user
    const user = await UserRepository.findByNoHp(noHp);
    if (!user) throw new Error('User tidak ditemukan');

    // 2. Cek status akun
    if (user.status !== 'AKTIF') throw new Error('Akun Anda belum disetujui oleh Ketua RT');

    // 3. Cek password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) throw new Error('Password salah');

    // 4. Buat JWT Token
    const token = jwt.sign(
      { id: user.id, role: user.role, nama: user.nama },
      JWT_SECRET,
      { expiresIn: '1d' }
    );

    return { user, token };
  }
}

module.exports = new AuthService();