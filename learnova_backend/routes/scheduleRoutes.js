const express = require('express');
const router = express.Router();
const {
    getSchedules,
    createSchedule,
    toggleScheduleCompletion,
    deleteSchedule
} = require('../controllers/scheduleController');
const { protect, protectOptional } = require('../middleware/authMiddleware');

router
    .route('/')
    .get(protectOptional, getSchedules)
    .post(protect, createSchedule);

router
    .route('/:id/toggle')
    .patch(protect, toggleScheduleCompletion);

router
    .route('/:id')
    .delete(protect, deleteSchedule);

module.exports = router;
