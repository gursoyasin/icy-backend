const express = require('express');
const router = express.Router();
const socialController = require('../controllers/socialController');

// Webhook Verification (GET)
router.get('/webhook', socialController.verifyWebhook);

// Webhook Event (POST)
router.post('/webhook', socialController.handleWebhook);

// Reply (POST) - Internal
router.post('/reply', socialController.replyToMessage);

module.exports = router;
