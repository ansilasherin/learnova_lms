const express = require('express');
const router = express.Router();
const {
    getRoster,
    addStudent,
    deleteStudent,
    getClassAttendanceSheet,
    saveClassAttendanceSheet,
    getRecordedDates,
    getAttendance
} = require('../controllers/attendanceController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

// 1. Roster endpoints
router.route('/roster')
    .get(getRoster)
    .post(authorize('teacher', 'admin'), addStudent);

router.route('/roster/:id')
    .delete(authorize('teacher', 'admin'), deleteStudent);

// 2. Class Attendance Sheet endpoints
router.route('/sheet')
    .get(getClassAttendanceSheet)
    .post(authorize('teacher', 'admin'), saveClassAttendanceSheet);

// 3. Calendar & Recorded Dates
router.route('/recorded-dates')
    .get(getRecordedDates);

// 4. Real Summary for Dashboard & Students
router.route('/')
    .get(getAttendance);

module.exports = router;
