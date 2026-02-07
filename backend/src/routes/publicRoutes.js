const express = require('express');
const publicController = require('../controllers/publicController');
const leadController = require('../controllers/leadController');

const router = express.Router();

// No authentication middleware here
router.post('/public/book', publicController.bookAppointment);

// Lead Generation Webhook (Facebook/Instagram/Landing Page)
router.post('/leads/webhook', leadController.webhook);

module.exports = router;
