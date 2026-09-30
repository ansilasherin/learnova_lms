const User = require('../models/User');

// ====================================================
// @desc    Get logged-in user profile
// @route   GET /api/users/profile (also /api/auth/me)
// @access  Private (JWT Protected)
// ====================================================
const getUserProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).select('-password');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Profile fetched successfully! 👤',
            user
        });
    } catch (error) {
        console.error('Get Profile Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error fetching profile',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Update logged-in user profile (Own profile only)
// @route   PUT /api/users/profile
// @access  Private (JWT Protected)
// ====================================================
const updateUserProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        // Update allowable fields if provided
        if (req.body.name) user.name = req.body.name.trim();
        if (req.body.phone !== undefined) user.phone = req.body.phone.trim();
        if (req.body.department) user.department = req.body.department.trim();
        if (req.body.studentId !== undefined) user.studentId = req.body.studentId;
        if (req.body.semester) user.semester = req.body.semester.trim();
        if (req.body.batch) user.batch = req.body.batch.trim();
        if (req.body.designation) user.designation = req.body.designation.trim();
        if (req.body.facultyId !== undefined) user.facultyId = req.body.facultyId;
        if (req.body.bio !== undefined) user.bio = req.body.bio.trim();
        if (req.body.profileImage) user.profileImage = req.body.profileImage.trim();

        // Save updated user (Runs Mongoose schema validations)
        const updatedUser = await user.save();

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully! 🎉',
            user: {
                id: updatedUser._id,
                name: updatedUser.name,
                email: updatedUser.email,
                phone: updatedUser.phone,
                role: updatedUser.role,
                department: updatedUser.department,
                studentId: updatedUser.studentId,
                semester: updatedUser.semester,
                batch: updatedUser.batch,
                designation: updatedUser.designation,
                facultyId: updatedUser.facultyId,
                bio: updatedUser.bio,
                profileImage: updatedUser.profileImage,
                updatedAt: updatedUser.updatedAt
            }
        });

    } catch (error) {
        console.error('Update Profile Error:', error.message);

        if (error.name === 'ValidationError') {
            const messages = Object.values(error.errors).map(val => val.message);
            return res.status(400).json({
                success: false,
                message: messages.join(', ')
            });
        }

        res.status(500).json({
            success: false,
            message: 'Server error updating profile',
            error: error.message
        });
    }
};

module.exports = {
    getUserProfile,
    updateUserProfile
};
