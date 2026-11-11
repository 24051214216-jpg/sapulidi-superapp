const express = require('express');
const router = express.Router();
const adminWargaController = require('../controllers/adminWargaController');
const { verifyToken } = require('../middlewares/verifyToken');

// Semua endpoint wajib login. Pembatasan role (pengurus) dilakukan di controller.
router.post('/guest', verifyToken, adminWargaController.createGuest);
router.get('/guest', verifyToken, adminWargaController.getGuests);
router.post('/letter', verifyToken, adminWargaController.createLetter);
router.get('/letter', verifyToken, adminWargaController.getLetters);
router.patch('/letter/:id/approve', verifyToken, adminWargaController.approveLetter);
router.patch('/letter/:id/reject', verifyToken, adminWargaController.rejectLetter);

module.exports = router;