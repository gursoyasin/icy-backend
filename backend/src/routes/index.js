const express = require('express');
const authRoutes = require('./authRoutes');
const statsRoutes = require('./statsRoutes');
const patientRoutes = require('./patientRoutes');
const appointmentRoutes = require('./appointmentRoutes');
const commRoutes = require('./communicationRoutes');
const faRoutes = require('./financeAdminRoutes');
const featRoutes = require('./featuresRoutes');

const campaignRoutes = require('./campaignRoutes');
const publicRoutes = require('./publicRoutes');

const router = express.Router();

router.use('/public', publicRoutes);

router.use('/auth', authRoutes);
router.use('/', statsRoutes);
router.use('/patients', patientRoutes);
router.use('/', appointmentRoutes);
router.use('/', commRoutes);
router.use('/', faRoutes);
router.use('/', featRoutes);
router.use('/campaigns', campaignRoutes);
router.use('/social', require('./socialRoutes'));
router.use('/', require('./reportsRoutes'));

// Setup Route (Protected by JWT_SECRET)
const setupController = require('../controllers/setupController');
router.post('/setup/init-tenant', setupController.initTenant);

// Platform Admin Routes
router.use('/platform', require('./platformRoutes'));

module.exports = router;


