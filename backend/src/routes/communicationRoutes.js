const express = require('express');
const commController = require('../controllers/communicationController');
const callController = require('../controllers/callController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Webhook is public (handled by middleware check)
router.post('/webhooks/:platform', commController.webhook);
router.post('/voip/webhook', callController.webhook);

// Protected
router.use(authenticate);
router.get('/conversations', commController.getConversations);
router.get('/conversations/:id/messages', commController.getMessages);
router.post('/messages', commController.sendMessage);
router.get('/notifications', commController.getNotifications);
router.get('/calls', commController.getCalls);

module.exports = router;
