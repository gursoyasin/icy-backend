const express = require('express');
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.post('/login', authController.login);
router.post('/verify-2fa', authController.verify2FA);
router.post('/enable-2fa', authenticate, authController.enable2FA);
router.post('/register', authenticate, authController.register);
router.get('/me', authenticate, authController.getMe);
router.get('/doctors', authenticate, authController.getDoctors);
router.get('/users', authenticate, authController.listUsers);
router.delete('/users/:id', authenticate, authController.deleteUser);
router.post('/change-password', authenticate, authController.changePassword);
router.get('/fix-admin', authController.fixAdminName); // Temporary Fix Route

module.exports = router;
