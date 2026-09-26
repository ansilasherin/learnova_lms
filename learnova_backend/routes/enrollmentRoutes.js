const express = require('express');
const router = express.Router();
const {
    enrollInCourse,
    getMyEnrolledCourses,
    updateLessonProgress,
    getCourseProgress
} = require('../controllers/enrollmentController');

const { protect } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

// ----------------------------------------------------
// Student Protected Enrollment Routes
// ----------------------------------------------------

// @route   GET /api/enrollments/my-courses
// @desc    Get all courses enrolled by the logged-in student
router.get('/my-courses', protect, authorizeRoles('student', 'admin'), getMyEnrolledCourses);

// @route   POST /api/enrollments/:courseId
// @desc    Enroll logged-in student in a course
router.post('/:courseId', protect, authorizeRoles('student', 'admin'), enrollInCourse);

// @route   GET /api/enrollments/:courseId/progress
// @desc    Get current progress for a course
router.get('/:courseId/progress', protect, authorizeRoles('student', 'admin'), getCourseProgress);

// @route   PUT /api/enrollments/:courseId/lessons/:lessonId/complete
// @desc    Mark a lesson completed and recalculate %
router.put('/:courseId/lessons/:lessonId/complete', protect, authorizeRoles('student', 'admin'), updateLessonProgress);

module.exports = router;
