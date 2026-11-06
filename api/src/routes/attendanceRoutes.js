const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { verifyToken } = require('../middlewares/verifyToken');

// Warga wajib login (membawa token) untuk absen
router.post('/', verifyToken, attendanceController.absenKerjaBakti);

module.exports = router;