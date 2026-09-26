const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getMe } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

// ----------------------------------------------------
// Public Auth Routes
// ----------------------------------------------------
router.post('/register', registerUser);
router.post('/login', loginUser);

// ----------------------------------------------------
// Protected Routes (Requires valid JWT Token)
// ----------------------------------------------------
router.get('/me', protect, getMe);

module.exports = router;
