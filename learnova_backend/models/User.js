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
            select: false // Queries-il (e.g. User.find()) password return aakaruthu (Security protection)
        },
        role: {
            type: String,
            enum: {
                values: ['student', 'teacher', 'admin'],
                message: '{VALUE} is not a valid role. Allowed roles: student, teacher, admin'
            },
            default: 'student'
        },
        studentId: {
            type: String,
            trim: true,
            default: null
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
    // Password modify cheythal mathram hash cheythaal mathi
    if (!this.isModified('password')) {
        return next();
    }

    // Salt generate cheythu password hash cheyyunnu
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
