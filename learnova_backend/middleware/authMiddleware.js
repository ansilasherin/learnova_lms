const jwt = require('jsonwebtoken');
const User = require('../models/User');

// ====================================================
// @desc    Middleware to protect private routes using JWT
// ====================================================
const protect = async (req, res, next) => {
    let token;

    // 1. Read Authorization header & check for Bearer format
    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            // 2. Extract Bearer token ('Bearer eyJhbGci...')
            token = req.headers.authorization.split(' ')[1];

            // 3. Verify JWT token using secret key
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // 4. Identify logged-in user from DB (excluding password)
            req.user = await User.findById(decoded.id).select('-password');

            // 5. Check if user still exists in DB
            if (!req.user) {
                return res.status(401).json({
                    success: false,
                    message: 'User belonging to this token no longer exists'
                });
            }

            // 6. Pass execution to the next controller function
            return next();

        } catch (error) {
            console.error('JWT Verification Error:', error.message);
            return res.status(401).json({
                success: false,
                message: 'Not authorized, invalid or expired token'
            });
        }
    }

    // 7. If no token is provided in Authorization header
    if (!token) {
        return res.status(401).json({
            success: false,
            message: 'Not authorized, no token provided'
        });
    }
};

// ====================================================
// @desc    Role Authorization Middleware (e.g. admin, teacher)
// ====================================================
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user || !roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `User role '${req.user ? req.user.role : 'none'}' is not allowed to access this resource`
            });
        }
        next();
    };
};

// ====================================================
// @desc    Optional Auth Middleware (extracts req.user if token present)
// ====================================================
const protectOptional = async (req, res, next) => {
    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            const token = req.headers.authorization.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            req.user = await User.findById(decoded.id).select('-password');
        } catch (_) {}
    }
    next();
};

module.exports = {
    protect,
    protectOptional,
    authorize
};
