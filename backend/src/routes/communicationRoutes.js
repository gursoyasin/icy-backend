const express = require('express');
const commController = require('../controllers/communicationController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Webhook is public (handled by middleware check)
router.post('/webhooks/:platform', commController.webhook);

// Protected
router.use(authenticate);
router.get('/conversations', commController.getConversations);
router.get('/conversations/:id/messages', commController.getMessages);
router.post('/messages', commController.sendMessage);

module.exports = router;
