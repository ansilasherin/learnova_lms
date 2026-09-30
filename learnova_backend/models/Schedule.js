const mongoose = require('mongoose');

// ----------------------------------------------------
// Timetable & Class Schedule Schema
// ----------------------------------------------------
const scheduleSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            default: null
        },
        title: {
            type: String,
            required: [true, 'Class or schedule title is required'],
            trim: true
        },
        instructor: {
            type: String,
            required: true,
            trim: true,
            default: 'Self Study'
        },
        department: {
            type: String,
            trim: true,
            default: 'Computer Science & Engineering'
        },
        semester: {
            type: String,
            trim: true,
            default: 'Semester 1'
        },
        batch: {
            type: String,
            trim: true,
            default: '2024 - 2028'
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
        type: {
            type: String, // 'class' (official lecture) or 'self_study' (student goal)
            enum: ['class', 'self_study'],
            default: 'class'
        },
        location: {
            type: String,
            default: ''
        },
        notes: {
            type: String,
            default: ''
        },
        isCompleted: {
            type: Boolean,
            default: false
        },
        dayOfWeek: {
            type: String, // e.g. "Monday", "Today", "All Days"
            default: 'Today'
        }
    },
    {
        timestamps: true
    }
);

const Schedule = mongoose.model('Schedule', scheduleSchema);

module.exports = Schedule;
