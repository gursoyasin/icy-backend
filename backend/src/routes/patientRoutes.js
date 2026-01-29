const express = require('express');
const patientController = require('../controllers/patientController');
const { authenticate, requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.get('/', patientController.getPatients);
router.post('/', patientController.createPatient);
router.get('/:id', patientController.getPatient);     // [NEW] Single Patient
router.patch('/:id', patientController.updatePatient); // [NEW] Update & Notes
router.delete('/:id', requireRole('admin'), patientController.deletePatient);

module.exports = router;
