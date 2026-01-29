const express = require('express');
const faController = require('../controllers/financeAdminController');
const { authenticate, requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

// Finance
router.get('/patients/:id/invoices', requireRole('staff'), faController.getInvoices);
router.post('/invoices/generate', requireRole('doctor'), faController.generateInvoice);

// Admin
router.post('/admin/clinics', requireRole('admin'), faController.createClinic);

module.exports = router;
