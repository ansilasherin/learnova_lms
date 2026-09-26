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
        batch: {
            type: String,
            trim: true,
            default: 'Batch A'
        },
        gender: {
            type: String,
            enum: ['Male', 'Female', 'Other'],
            default: 'Male'
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
