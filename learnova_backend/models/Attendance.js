const mongoose = require('mongoose');

// ----------------------------------------------------
// Class Attendance Record Schema
// ----------------------------------------------------
const attendanceSchema = new mongoose.Schema(
    {
        student: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Student'
        },
        studentName: {
            type: String,
            required: [true, 'Student name is required'],
            trim: true
        },
        rollNo: {
            type: String,
            default: '',
            trim: true
        },
        subject: {
            type: String,
            required: [true, 'Subject name is required'],
            trim: true
        },
        date: {
            type: String, // e.g. "25 Sep 2026"
            required: true,
            trim: true
        },
        isPresent: {
            type: Boolean,
            default: true
        },
        remarks: {
            type: String,
            default: ''
        }
    },
    {
        timestamps: true
    }
);

const Attendance = mongoose.model('Attendance', attendanceSchema);

module.exports = Attendance;
