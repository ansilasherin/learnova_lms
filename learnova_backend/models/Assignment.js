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
        gradedByName: {
            type: String,
            default: ''
        }
    },
    { _id: true, timestamps: true }
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
        description: {
            type: String,
            trim: true,
            default: ''
        },
        dueDate: {
            type: String, // e.g. "Tomorrow, 11:59 PM" or "2026-10-05"
            required: [true, 'Due date is required']
        },
        priority: {
            type: String,
            enum: ['High Priority', 'Medium Priority', 'Low Priority', 'High', 'Medium', 'Low'],
            default: 'Medium Priority'
        },
        maxScore: {
            type: Number,
            default: 100
        },
        progress: {
            type: Number,
            default: 0
        },
        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        submissions: [submissionSchema]
    },
    {
        timestamps: true
    }
);

const Assignment = mongoose.model('Assignment', assignmentSchema);

module.exports = Assignment;
