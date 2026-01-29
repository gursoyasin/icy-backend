const express = require('express');
const featController = require('../controllers/featuresController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

// AI
router.post('/ai/query', featController.queryAI);

// Marketing
router.post('/marketing/send', featController.sendCampaign);

// Support
router.post('/support', featController.createTicket);

// Photos
router.post('/photos', featController.uploadPhoto);

// Health Tourism
router.get('/patients/:id/transfers', featController.getTransfers);
router.post('/transfers', featController.createTransfer);
router.get('/patients/:id/accommodations', featController.getAccommodations);
router.post('/accommodations', featController.createAccommodation);

module.exports = router;
