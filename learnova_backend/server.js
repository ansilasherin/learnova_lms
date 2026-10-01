const express = require('express');
const http = require('http');
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
const chatRoutes = require('./routes/chatRoutes');
const testRoutes = require('./routes/testRoutes');

// Load environment variables from .env
dotenv.config();

// Connect to MongoDB
connectDB();

// Initialize Express app
const app = express();

// Create HTTP server for Express + Socket.IO
const server = http.createServer(app);

// Enable Cross-Origin Resource Sharing (CORS) for Flutter Web/Desktop/Mobile
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    credentials: true
}));

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

// 8. Real-time Chat API Routes (/api/chats)
app.use('/api/chats', chatRoutes);

// 9. Role Test Routes (/api/test)
app.use('/api/test', testRoutes);

// Root Route
app.get('/', (req, res) => {
    res.status(200).json({
        success: true,
        message: "Welcome to Learnova LMS Server API 🎓",
        features: ["Auth", "Courses", "Enrollments", "Assignments", "Attendance", "Schedules", "Realtime Chat (Socket.IO)"]
    });
});

// ----------------------------------------------------
// Socket.IO Real-time WebSockets Engine
// ----------------------------------------------------
const { Server } = require('socket.io');
const io = new Server(server, {
    pingTimeout: 60000,
    cors: {
        origin: '*',
        methods: ['GET', 'POST']
    }
});

// Attach io to express app for use in controllers
app.set('io', io);

io.on('connection', (socket) => {
    console.log(`⚡ Socket connected: ${socket.id}`);

    // Setup: User joins their personal room
    socket.on('setup', (userData) => {
        if (userData && (userData.id || userData._id)) {
            const userId = (userData.id || userData._id).toString();
            socket.join(userId);
            console.log(`👤 User joined personal room: ${userId} (${userData.name || 'User'})`);
            socket.emit('connected');
        }
    });

    // Join specific chat room (Direct or Department Batch Group)
    socket.on('join_chat', (chatId) => {
        if (chatId) {
            const room = chatId.toString();
            socket.join(room);
            console.log(`💬 Socket ${socket.id} joined chat room: ${room}`);
        }
    });

    // Leave chat room
    socket.on('leave_chat', (chatId) => {
        if (chatId) {
            const room = chatId.toString();
            socket.leave(room);
            console.log(`🚪 Socket ${socket.id} left chat room: ${room}`);
        }
    });

    // Send Real-time message
    socket.on('send_message', (newMessageReceived) => {
        if (!newMessageReceived) return;
        const chat = newMessageReceived.chat;
        if (!chat) return console.log('chat not defined on message');

        const chatId = (typeof chat === 'object' ? (chat._id || chat.id) : chat).toString();
        
        // Broadcast to all sockets in this chat room except sender
        socket.to(chatId).emit('message_received', newMessageReceived);
        
        // Also emit to individual user rooms if recipients list is attached
        if (newMessageReceived.recipients && Array.isArray(newMessageReceived.recipients)) {
            newMessageReceived.recipients.forEach(userId => {
                if (userId) {
                    socket.to(userId.toString()).emit('message_received', newMessageReceived);
                }
            });
        }
        
        console.log(`📨 Broadcasted message to chat room ${chatId}: "${newMessageReceived.content || ''}"`);
    });

    // Typing Indicators
    socket.on('typing', (data) => {
        if (!data) return;
        const chatId = (data.chatId || data).toString();
        const userName = data.userName || 'Someone';
        socket.to(chatId).emit('typing', { chatId, userName });
    });

    socket.on('stop_typing', (chatId) => {
        if (chatId) {
            socket.to(chatId.toString()).emit('stop_typing', chatId.toString());
        }
    });

    socket.on('disconnect', () => {
        console.log(`🔌 Socket disconnected: ${socket.id}`);
    });
});

// ----------------------------------------------------
// Server Configuration
// ----------------------------------------------------
const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
    console.log(`=========================================`);
    console.log(`🚀 Learnova Server is running on Port: ${PORT}`);
    console.log(`📍 Test URL: http://localhost:${PORT}/api/test`);
    console.log(`🔐 Auth URL: http://localhost:${PORT}/api/auth/register`);
    console.log(`👤 User Profile URL: http://localhost:${PORT}/api/users/profile`);
    console.log(`📚 Courses API URL: http://localhost:${PORT}/api/courses`);
    console.log(`📖 Enrollments API URL: http://localhost:${PORT}/api/enrollments/my-courses`);
    console.log(`💬 Realtime Chat API: http://localhost:${PORT}/api/chats`);
    console.log(`=========================================`);
});
