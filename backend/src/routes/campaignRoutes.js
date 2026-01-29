const express = require('express');
const router = express.Router();
const campaignController = require('../controllers/campaignController');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

router.get('/', campaignController.getCampaigns);
router.post('/send', campaignController.createCampaign);

module.exports = router;
