const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

// ----------------------------------------------------
// Public Test Route (No auth needed)
// ----------------------------------------------------
router.get('/', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Learnova Test API Root - Server & Database are active! 🚀'
    });
});

// ----------------------------------------------------
// 1. Student Only Route
// ----------------------------------------------------
// @route   GET /api/test/student
// @access  Private (Student role only)
router.get('/student', protect, authorizeRoles('student'), (req, res) => {
    res.status(200).json({
        success: true,
        message: `Welcome Student ${req.user.name}! 📚 You can view enrolled courses, quizzes, and learning progress.`,
        user: {
            id: req.user._id,
            name: req.user.name,
            email: req.user.email,
            role: req.user.role
        }
    });
});

// ----------------------------------------------------
// 2. Teacher Only Route
// ----------------------------------------------------
// @route   GET /api/test/teacher
// @access  Private (Teacher role only)
router.get('/teacher', protect, authorizeRoles('teacher'), (req, res) => {
    res.status(200).json({
        success: true,
        message: `Welcome Teacher ${req.user.name}! 👨‍🏫 You can create new courses, upload videos, and grade assignments.`,
        user: {
            id: req.user._id,
            name: req.user.name,
            email: req.user.email,
            role: req.user.role
        }
    });
});

// ----------------------------------------------------
// 3. Admin Only Route
// ----------------------------------------------------
// @route   GET /api/test/admin
// @access  Private (Admin role only)
router.get('/admin', protect, authorizeRoles('admin'), (req, res) => {
    res.status(200).json({
        success: true,
        message: `Welcome Admin ${req.user.name}! 👑 You have full access to platform analytics, user management, and payments.`,
        user: {
            id: req.user._id,
            name: req.user.name,
            email: req.user.email,
            role: req.user.role
        }
    });
});

module.exports = router;
