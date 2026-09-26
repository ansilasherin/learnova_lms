const express = require('express');
const router = express.Router();
const { getUserProfile, updateUserProfile } = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

// ----------------------------------------------------
// User Profile Routes (Private & JWT Protected)
// ----------------------------------------------------

// @route   GET /api/users/profile
// @route   PUT /api/users/profile
router.route('/profile')
    .get(protect, getUserProfile)
    .put(protect, updateUserProfile);

module.exports = router;
