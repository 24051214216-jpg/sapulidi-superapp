const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { verifyToken } = require('../middlewares/verifyToken');

// Semua endpoint wajib login. Pembatasan role (broadcast) dilakukan di controller.
router.post('/broadcast', verifyToken, notificationController.broadcast);
router.get('/', verifyToken, notificationController.getMyNotifications);
router.patch('/:id/read', verifyToken, notificationController.markAsRead);

module.exports = router;