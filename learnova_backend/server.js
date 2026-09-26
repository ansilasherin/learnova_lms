const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

// Route Imports
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const courseRoutes = require('./routes/courseRoutes');
const enrollmentRoutes = require('./routes/enrollmentRoutes');
const assignmentRoutes = require('./routes/assignmentRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const scheduleRoutes = require('./routes/scheduleRoutes');
const testRoutes = require('./routes/testRoutes');

// Load environment variables from .env
dotenv.config();

// Connect to MongoDB
connectDB();

// Initialize Express app
const app = express();

// Enable Cross-Origin Resource Sharing (CORS) for Flutter Web/Desktop/Mobile
app.use(cors());

// Middleware to parse incoming JSON requests
app.use(express.json());

// Serve static uploads folder (Videos, attachments, profile photos)
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ----------------------------------------------------
// API Routes
// ----------------------------------------------------

// 1. Auth API Routes (/api/auth)
app.use('/api/auth', authRoutes);

// 2. User Profile API Routes (/api/users)
app.use('/api/users', userRoutes);

// 3. Course Management API Routes (/api/courses)
app.use('/api/courses', courseRoutes);

// 4. Student Enrollment & Progress API Routes (/api/enrollments)
app.use('/api/enrollments', enrollmentRoutes);

// 5. Assignment API Routes (/api/assignments)
app.use('/api/assignments', assignmentRoutes);

// 6. Attendance API Routes (/api/attendance)
app.use('/api/attendance', attendanceRoutes);

// 7. Schedule API Routes (/api/schedules)
app.use('/api/schedules', scheduleRoutes);

// 8. Role Test Routes (/api/test)
app.use('/api/test', testRoutes);

// Root Route
app.get('/', (req, res) => {
    res.status(200).json({
        success: true,
        message: "Welcome to Learnova LMS Server API 🎓"
    });
});

// ----------------------------------------------------
// Server Configuration
// ----------------------------------------------------
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`=========================================`);
    console.log(`🚀 Learnova Server is running on Port: ${PORT}`);
    console.log(`📍 Test URL: http://localhost:${PORT}/api/test`);
    console.log(`🔐 Auth URL: http://localhost:${PORT}/api/auth/register`);
    console.log(`👤 User Profile URL: http://localhost:${PORT}/api/users/profile`);
    console.log(`📚 Courses API URL: http://localhost:${PORT}/api/courses`);
    console.log(`📖 Enrollments API URL: http://localhost:${PORT}/api/enrollments/my-courses`);
    console.log(`=========================================`);
});
