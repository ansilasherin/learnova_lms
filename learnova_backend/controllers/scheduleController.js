const Schedule = require('../models/Schedule');

// ----------------------------------------------------
// @desc    Get all timetable schedules
// @route   GET /api/schedules
// @access  Public / Private
// ----------------------------------------------------
exports.getSchedules = async (req, res) => {
    try {
        const schedules = await Schedule.find().sort({ createdAt: 1 });

        res.status(200).json({
            success: true,
            count: schedules.length,
            schedules: schedules.map((s) => ({
                id: s._id,
                title: s.title,
                instructor: s.instructor,
                time: s.time,
                duration: s.duration,
                isLive: s.isLive,
                color: s.color,
                dayOfWeek: s.dayOfWeek
            }))
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error fetching schedules',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Create schedule item (Teacher/Admin)
// @route   POST /api/schedules
// @access  Private (Teacher, Admin)
// ----------------------------------------------------
exports.createSchedule = async (req, res) => {
    try {
        const { title, instructor, time, duration, isLive, color, dayOfWeek } = req.body;

        const schedule = await Schedule.create({
            title,
            instructor,
            time,
            duration,
            isLive,
            color,
            dayOfWeek
        });

        res.status(201).json({
            success: true,
            message: 'Class schedule added successfully! 📅',
            schedule
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error creating schedule',
            error: error.message
        });
    }
};
