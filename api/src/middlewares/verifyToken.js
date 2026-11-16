const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'rahasia_sapulidi_super_app';

exports.verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: "Akses ditolak. Token tidak ditemukan." });
  }

  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ success: false, message: "Token tidak valid atau kedaluwarsa." });
    }
    req.user = decoded; 
    next();
  });
};

exports.isAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'KETUA_RT') {
    return next();
  }
  return res.status(403).json({ success: false, message: "Akses ditolak. Hanya untuk Ketua RT." });
};