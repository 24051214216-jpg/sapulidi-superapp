const express = require('express');
const router = express.Router();
const financeController = require('../controllers/financeController');
const { verifyToken } = require('../middlewares/verifyToken');

// Semua endpoint keuangan wajib login (membawa token).
// Pembatasan role (Bendahara / Ketua RT / Warga) dilakukan di controller.
router.post('/invoices', verifyToken, financeController.createInvoice);
router.get('/invoices', verifyToken, financeController.getInvoices);
router.post('/payments', verifyToken, financeController.createPayment);
router.patch('/payments/:id/verify', verifyToken, financeController.verifyPayment);
router.get('/cash', verifyToken, financeController.getCash);

module.exports = router;