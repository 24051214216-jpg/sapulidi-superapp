require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const session = require('express-session');
const multer = require('multer');
const fs = require('fs');
const authRoutes = require('./src/routes/v1/authRoutes');
const app = express();

// Middleware Dasar
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Setup EJS & Session (Web Admin)
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

app.post('/api/v1/upload', upload.single('foto'), (req, res) => {
  if (!req.file) return res.status(400).json({ message: "Tidak ada file yang diupload" });
  const fileUrl = `/uploads/${req.file.filename}`;
  res.status(200).json({ success: true, message: "Upload berhasil", url: fileUrl });
});

// Health Check
app.get('/', (req, res) => { res.json({ pesan: "API SapuLidi V2 Berjalan!" }); });
// Daftarkan Route V1
app.use('/api/v1/auth', authRoutes);
// ==========================================
// DAFTARKAN ROUTE V1 DI SINI NANTI
// ==========================================

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server SapuLidi V2 berjalan di http://localhost:${PORT}`);
});