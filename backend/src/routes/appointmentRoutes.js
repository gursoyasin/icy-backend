const express = require('express');
const appointmentController = require('../controllers/appointmentController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Public Routes (No Auth Middleware applied here, or handled inside if global)
// We will mount these on a separate path or handle exclusion. 
// For cleanest design, let's mount standard api on /api and public on /api/booking separately?
// Or just put them here and ensure `authenticate` middleware skips them if mounted globally.
// Our `authenticate` middleware ALREADY skips /api/booking. So we are good.

router.get('/booking/:slug', appointmentController.getPublicBookingSlot);
router.post('/booking/:slug', appointmentController.createPublicBooking);

// Protected Routes
router.post('/appointments', authenticate, appointmentController.createAppointment);
router.get('/appointments', authenticate, appointmentController.getAppointments); // Added
router.patch('/appointments/:id/status', authenticate, appointmentController.updateAppointmentStatus);
router.patch('/appointments/:id/cancel', authenticate, appointmentController.cancelAppointment); // Added for specific cancel action

module.exports = router;
