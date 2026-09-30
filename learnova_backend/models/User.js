const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// ----------------------------------------------------
// User Schema Definition for Learnova LMS
// ----------------------------------------------------
const userSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: [true, 'Please provide your full name'],
            trim: true,
            maxlength: [60, 'Name cannot exceed 60 characters']
        },
        email: {
            type: String,
            required: [true, 'Please provide your email address'],
            unique: true,
            trim: true,
            lowercase: true,
            match: [
                /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
                'Please provide a valid email address'
            ]
        },
        phone: {
            type: String,
            trim: true,
            default: ''
        },
        password: {
            type: String,
            required: [true, 'Please provide a password'],
            minlength: [6, 'Password must be at least 6 characters long'],
            select: false // Exclude from find queries by default
        },
        role: {
            type: String,
            enum: {
                values: ['student', 'teacher', 'admin'],
                message: '{VALUE} is not a valid role. Allowed roles: student, teacher, admin'
            },
            default: 'student'
        },
        department: {
            type: String,
            trim: true,
            default: 'Computer Science & Engineering'
        },
        // Student specific fields
        studentId: {
            type: String,
            trim: true,
            default: null
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
        // Teacher / Faculty specific fields
        designation: {
            type: String,
            trim: true,
            default: 'Assistant Professor'
        },
        facultyId: {
            type: String,
            trim: true,
            default: null
        },
        bio: {
            type: String,
            trim: true,
            default: ''
        },
        profileImage: {
            type: String,
            default: 'https://api.dicebear.com/7.x/bottts/svg?seed=Learnova'
        }
    },
    {
        // Automatically creates and manages 'createdAt' & 'updatedAt' fields
        timestamps: true
    }
);

// ----------------------------------------------------
// Mongoose Pre-save Hook: Password Auto-Hashing
// ----------------------------------------------------
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) {
        return next();
    }

    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// ----------------------------------------------------
// Instance Method: Compare entered password with hashed password
// ----------------------------------------------------
userSchema.methods.matchPassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

// ----------------------------------------------------
// Create & Export User Model
// ----------------------------------------------------
const User = mongoose.model('User', userSchema);

module.exports = User;
