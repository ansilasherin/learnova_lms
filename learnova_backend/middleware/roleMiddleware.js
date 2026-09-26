// ====================================================
// @desc    Role-Based Access Control (RBAC) Middleware
// @param   {...string} allowedRoles - 'student', 'teacher', 'admin'
// ====================================================
const authorizeRoles = (...allowedRoles) => {
    return (req, res, next) => {
        // 1. User login aano ennu check cheyyunnu (protect middleware req.user set cheythittundavanam)
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required. Please login first.'
            });
        }

        // 2. User-nte role allowedRoles array-il undo ennu check cheyyunnu
        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Access Forbidden! Role '${req.user.role}' is not authorized to access this resource. Allowed roles: [${allowedRoles.join(', ')}]`
            });
        }

        // 3. User-inu permission undengil adutha step-ilekku vidunnu
        next();
    };
};

module.exports = {
    authorizeRoles
};
