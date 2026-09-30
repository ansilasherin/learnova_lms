const mongoose = require('mongoose');

// ----------------------------------------------------
// Student Roster Model (For Class Attendance Register)
// ----------------------------------------------------
const studentSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, 'Student name is required'],
            trim: true
        },
        rollNo: {
            type: String,
            required: [true, 'Roll number is required'],
            trim: true
        },
        email: {
            type: String,
            trim: true,
            default: ''
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
        gender: {
            type: String,
            enum: ['Male', 'Female', 'Other'],
            default: 'Male'
        },
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            default: null
        },
        addedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    },
    {
        timestamps: true
    }
);

const Student = mongoose.model('Student', studentSchema);

module.exports = Student;
