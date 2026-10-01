const express = require('express');
const router = express.Router();
const {
    accessOrCreateDirectChat,
    fetchUserChats,
    getDepartmentContacts,
    fetchMessages,
    sendMessage
} = require('../controllers/chatController');
const { protect } = require('../middleware/authMiddleware');

// All chat routes require authentication
router.use(protect);

// 1. Fetch user's active chats or initiate direct chat
router
    .route('/')
    .get(fetchUserChats)
    .post(accessOrCreateDirectChat);

// 2. Fetch department contacts (Faculty and classmates in same department)
router.get('/contacts', getDepartmentContacts);

// 3. Fetch messages for a specific chat or send a new message
router
    .route('/:chatId/messages')
    .get(fetchMessages)
    .post(sendMessage);

module.exports = router;
