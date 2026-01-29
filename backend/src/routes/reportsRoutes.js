const express = require('express');
const reportsController = require('../controllers/reportsController'); // Verify existence
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.get('/reports/daily', authenticate, reportsController.getDailySummary);

module.exports = router;
