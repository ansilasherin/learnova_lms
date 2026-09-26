const express = require('express');
const router = express.Router();
const {
    getSchedules,
    createSchedule
} = require('../controllers/scheduleController');
const { protect, authorize } = require('../middleware/authMiddleware');

router
    .route('/')
    .get(getSchedules)
    .post(protect, authorize('teacher', 'admin'), createSchedule);

module.exports = router;
