const express = require('express');
const publicController = require('../controllers/publicController');

const router = express.Router();

// No authentication middleware here
router.post('/public/book', publicController.bookAppointment);

module.exports = router;
