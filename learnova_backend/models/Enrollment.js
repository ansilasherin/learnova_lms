const mongoose = require('mongoose');

// ----------------------------------------------------
// Enrollment & Learning Progress Schema
// ----------------------------------------------------
const enrollmentSchema = new mongoose.Schema(
    {
        student: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Student ID is required']
        },
        course: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Course',
            required: [true, 'Course ID is required']
        },
        completedLessons: [
            {
                type: mongoose.Schema.Types.ObjectId // Lesson subdocument _id
            }
        ],
        progressPercentage: {
            type: Number,
            default: 0,
            min: 0,
            max: 100
        },
        isCompleted: {
            type: Boolean,
            default: false
        },
        enrolledAt: {
            type: Date,
            default: Date.now
        }
    },
    {
        timestamps: true
    }
);

// Prevent duplicate enrollment for same student in the same course
enrollmentSchema.index({ student: 1, course: 1 }, { unique: true });

const Enrollment = mongoose.model('Enrollment', enrollmentSchema);

module.exports = Enrollment;
