const mongoose = require('mongoose');

// ----------------------------------------------------
// Lesson Subdocument Schema
// ----------------------------------------------------
const lessonSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Lesson title is required'],
            trim: true
        },
        description: {
            type: String,
            trim: true,
            default: ''
        },
        videoUrl: {
            type: String,
            required: [true, 'Video URL is required'],
            trim: true
        },
        duration: {
            type: String, // e.g. "15 mins"
            default: ''
        },
        isFreePreview: {
            type: Boolean,
            default: false
        }
    },
    { _id: true, timestamps: true }
);

// ----------------------------------------------------
// Study Material / Slide Subdocument Schema
// ----------------------------------------------------
const materialSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Material title is required'],
            trim: true
        },
        description: {
            type: String,
            default: ''
        },
        type: {
            type: String, // 'pdf', 'slide', 'document', 'link'
            enum: ['pdf', 'slide', 'document', 'link'],
            default: 'pdf'
        },
        fileUrl: {
            type: String,
            required: [true, 'File URL or download link is required'],
            trim: true
        },
        fileSize: {
            type: String, // e.g. "3.5 MB", "24 Slides"
            default: '2.5 MB'
        }
    },
    { _id: true, timestamps: true }
);

// ----------------------------------------------------
// Main Course Schema Definition for Learnova LMS
// ----------------------------------------------------
const courseSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: [true, 'Course title is required'],
            trim: true,
            maxlength: [120, 'Title cannot exceed 120 characters']
        },
        description: {
            type: String,
            required: [true, 'Course description is required'],
            trim: true
        },
        category: {
            type: String,
            required: [true, 'Category is required'],
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
        price: {
            type: Number,
            required: [true, 'Price is required'],
            min: [0, 'Price cannot be negative'],
            default: 0
        },
        level: {
            type: String,
            enum: ['Beginner', 'Intermediate', 'Advanced', 'All Levels'],
            default: 'Beginner'
        },
        thumbnail: {
            type: String,
            default: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600'
        },
        instructor: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        lessons: [lessonSchema],
        materials: [materialSchema],
        isPublished: {
            type: Boolean,
            default: true
        },
        enrolledStudents: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User'
            }
        ]
    },
    {
        timestamps: true
    }
);

// ----------------------------------------------------
// Create & Export Course Model
// ----------------------------------------------------
const Course = mongoose.model('Course', courseSchema);

module.exports = Course;
