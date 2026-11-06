const express = require('express');
const router = express.Router();
const newsController = require('../controllers/newsController');
const { verifyToken } = require('../middlewares/verifyToken');

// Warga wajib login (membawa token) untuk membaca berita
router.get('/', verifyToken, newsController.getNews);

module.exports = router;