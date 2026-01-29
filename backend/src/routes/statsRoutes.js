const express = require('express');
const statsController = require('../controllers/statsController');
const { authenticate, requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate); // Protect all stats routes

router.get('/stats', statsController.getStats);
router.get('/analytics', requireRole('admin'), statsController.getAnalytics);

module.exports = router;
