const express = require('express');
const commController = require('../controllers/communicationController'); // handles opt-out, notifications
const callController = require('../controllers/callController'); // handles calls
const socialController = require('../controllers/socialController'); // handles conversations, messages
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Webhooks (Platform Specific)
// Note: /social/webhook is handled in socialRoutes.js, avoiding duplication here unless strictly needed by legacy code.
// If /webhooks/:platform IS still used by something, we can map it.
router.post('/webhooks/:platform', socialController.handleWebhook);
router.post('/voip/webhook', callController.webhook);

// Protected Routes
router.use(authenticate);

// Conversations & Messages (Social Controller)
router.get('/conversations', socialController.getConversations);
router.get('/conversations/:id/messages', socialController.getMessages);
router.post('/messages', socialController.sendMessage);

// Notifications (Communication Controller)
router.get('/notifications', commController.getNotifications);

// Calls (Call Controller)
router.get('/calls', callController.getCalls);

// Opt-out (Communication Controller)
router.post('/opt-out', commController.optOut);

module.exports = router;
