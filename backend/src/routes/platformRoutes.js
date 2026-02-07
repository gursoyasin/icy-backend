const express = require('express');
const router = express.Router();
const platformController = require('../controllers/platformController');
const { authenticate } = require('../middleware/auth');
const isPlatformAdmin = require('../middleware/platformAuth');

// All routes require Login + Platform Admin Check
router.use(authenticate, isPlatformAdmin);

router.get('/clinics', platformController.listClinics);
router.post('/clinics', platformController.createClinic);
router.patch('/clinics/:id', platformController.updateClinic);

module.exports = router;
