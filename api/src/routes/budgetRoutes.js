const express = require('express');
const router = express.Router();
const budgetController = require('../controllers/budgetController');
const { verifyToken } = require('../middlewares/verifyToken');

router.post('/', verifyToken, budgetController.createBudgetRequest);
router.patch('/:id/approve', verifyToken, budgetController.approveBudget);
router.patch('/:id/disburse', verifyToken, budgetController.disburseBudget);

module.exports = router;