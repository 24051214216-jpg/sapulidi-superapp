const express = require('express');
const router = express.Router();
const eventController = require('../controllers/eventController');
const { verifyToken } = require('../middlewares/verifyToken'); // Kita gunakan middleware token

// Semua route di bawah ini WAJIB LOGIN (membawa token)
router.post('/', verifyToken, eventController.createEvent);
router.get('/', verifyToken, eventController.getAllEvents);

module.exports = router;