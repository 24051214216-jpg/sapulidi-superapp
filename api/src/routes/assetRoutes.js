const express = require('express');
const router = express.Router();
const assetController = require('../controllers/assetController');
const { verifyToken } = require('../middlewares/verifyToken');

// Semua endpoint wajib login. Pembatasan role dilakukan di controller.
router.post('/', verifyToken, assetController.createAsset);
router.get('/', verifyToken, assetController.getAvailableAssets);
router.post('/loans', verifyToken, assetController.createLoan);
router.get('/loans', verifyToken, assetController.getActiveLoans);
router.patch('/loans/:id/return', verifyToken, assetController.returnLoan);

module.exports = router;