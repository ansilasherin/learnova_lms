const mongoose = require('mongoose');

// ----------------------------------------------------
// Timetable & Class Schedule Schema
// ----------------------------------------------------
const scheduleSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Class or schedule title is required'],
            trim: true
        },
        instructor: {
            type: String,
            required: true,
            trim: true
        },
        time: {
            type: String, // e.g. "09:00 AM - 10:30 AM"
            required: true
        },
        duration: {
            type: String, // e.g. "1.5 hrs"
            default: '1 hr'
        },
        isLive: {
            type: Boolean,
            default: false
        },
        color: {
            type: String, // e.g. "#4F46E5"
            default: '#4F46E5'
        },
        dayOfWeek: {
            type: String, // e.g. "Monday", "All Days"
            default: 'Today'
        }
    },
    {
        timestamps: true
    }
);

const Schedule = mongoose.model('Schedule', scheduleSchema);

module.exports = Schedule;
