const mongoose = require('mongoose');

// ----------------------------------------------------
// Assignment Schema Definition for Learnova LMS
// ----------------------------------------------------
const submissionSchema = new mongoose.Schema(
    {
        student: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        studentName: {
            type: String,
            default: ''
        },
        studentEmail: {
            type: String,
            default: ''
        },
        studentRollNo: {
            type: String,
            default: ''
        },
        submittedAt: {
            type: Date,
            default: Date.now
        },
        fileName: {
            type: String,
            default: ''
        },
        fileUrl: {
            type: String,
            default: ''
        },
        submissionText: {
            type: String,
            default: ''
        },
        status: {
            type: String,
            enum: ['submitted', 'graded', 'reviewed'],
            default: 'submitted'
        },
        score: {
            type: Number,
            default: null
        },
        maxScore: {
            type: Number,
            default: 100
        },
        feedback: {
            type: String,
            default: ''
        },
        gradedAt: {
            type: Date
        },
        gradedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        gradedByName: {
            type: String,
            default: ''
        }
    },
    { _id: true }
);

const assignmentSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Assignment title is required'],
            trim: true
        },
        subject: {
            type: String,
            required: [true, 'Subject is required'],
            trim: true
        },
        description: {
            type: String,
            default: ''
        },
        dueDate: {
            type: String, // e.g. "Due: 20 Oct 2026"
            required: true
        },
        priority: {
            type: String,
            enum: ['High Priority', 'Medium Priority', 'Low Priority'],
            default: 'Medium Priority'
        },
        maxScore: {
            type: Number,
            default: 100
        },
        progress: {
            type: Number,
            default: 0,
            min: 0,
            max: 100
        },
        submissions: [submissionSchema],
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    },
    {
        timestamps: true
    }
);

const Assignment = mongoose.model('Assignment', assignmentSchema);

module.exports = Assignment;
