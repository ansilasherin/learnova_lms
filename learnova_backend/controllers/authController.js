const User = require('../models/User');
const Student = require('../models/Student');
const generateToken = require('../utils/generateToken');

// ====================================================
// @desc    Register a new user (Student / Teacher / Admin)
// @route   POST /api/auth/register
// @access  Public
// ====================================================
const registerUser = async (req, res) => {
    try {
        const {
            name,
            email,
            phone,
            password,
            role,
            department,
            studentId,
            semester,
            batch,
            designation,
            facultyId,
            bio
        } = req.body;

        // 1. Check if required fields are provided
        if (!name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide name, email, and password'
            });
        }

        // 2. Check if user already exists with this email
        const userExists = await User.findOne({ email: email.toLowerCase() });
        if (userExists) {
            return res.status(400).json({
                success: false,
                message: 'A user with this email already exists'
            });
        }

        // 3. Create new user in Database (Password will be auto-hashed by User model hook)
        const user = await User.create({
            name,
            email,
            phone: phone || '',
            password,
            role: role || 'student',
            department: department || 'Computer Science & Engineering',
            studentId: studentId || null,
            semester: semester || 'Semester 1',
            batch: batch || '2024 - 2028',
            designation: designation || 'Assistant Professor',
            facultyId: facultyId || null,
            bio: bio || ''
        });

        // 4. Auto-sync student to class roster of their department
        if (user.role === 'student') {
            try {
                await Student.findOneAndUpdate(
                    { email: user.email },
                    {
                        name: user.name,
                        rollNo: user.studentId || user.email.split('@')[0],
                        email: user.email,
                        department: user.department,
                        semester: user.semester,
                        batch: user.batch,
                        user: user._id
                    },
                    { upsert: true, new: true }
                );
            } catch (err) {
                console.error('Auto-roster sync error:', err.message);
            }
        }

        // 5. Generate JWT token
        const token = generateToken(user._id, user.role);

        // 6. Send success response (excluding password)
        res.status(201).json({
            success: true,
            message: 'User registered successfully! 🎉',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                phone: user.phone,
                role: user.role,
                department: user.department,
                studentId: user.studentId,
                semester: user.semester,
                batch: user.batch,
                designation: user.designation,
                facultyId: user.facultyId,
                bio: user.bio,
                profileImage: user.profileImage,
                createdAt: user.createdAt
            }
        });

    } catch (error) {
        console.error('Registration Error:', error.message);

        // Handle Mongoose Validation Errors
        if (error.name === 'ValidationError') {
            const messages = Object.values(error.errors).map(val => val.message);
            return res.status(400).json({
                success: false,
                message: messages.join(', ')
            });
        }

        res.status(500).json({
            success: false,
            message: 'Server error during registration',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Authenticate user & get token (Login)
// @route   POST /api/auth/login
// @access  Public
// ====================================================
const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;

        // 1. Check if email & password are provided
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide both email and password'
            });
        }

        // 2. Find user by email and explicitly include password field
        const user = await User.findOne({ email: email.toLowerCase() }).select('+password');

        // 3. Check if user exists
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        // 4. Compare entered password with hashed password in database
        const isMatch = await user.matchPassword(password);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        // 5. Generate JWT token
        const token = generateToken(user._id, user.role);

        // 6. Return response (excluding password)
        res.status(200).json({
            success: true,
            message: 'Logged in successfully! 🚀',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                phone: user.phone,
                role: user.role,
                department: user.department || 'Computer Science & Engineering',
                studentId: user.studentId,
                semester: user.semester || 'Semester 1',
                batch: user.batch || '2024 - 2028',
                designation: user.designation || 'Assistant Professor',
                facultyId: user.facultyId,
                bio: user.bio || '',
                profileImage: user.profileImage,
                createdAt: user.createdAt
            }
        });

    } catch (error) {
        console.error('Login Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error during login',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Get currently logged-in user profile
// @route   GET /api/auth/me
// @access  Private (Protected by JWT)
// ====================================================
const getMe = async (req, res) => {
    try {
        res.status(200).json({
            success: true,
            message: 'User profile fetched successfully! 👤',
            user: req.user
        });
    } catch (error) {
        console.error('Get Profile Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error fetching user profile',
            error: error.message
        });
    }
};

module.exports = {
    registerUser,
    loginUser,
    getMe
};
