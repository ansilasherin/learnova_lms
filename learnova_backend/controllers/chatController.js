const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');

// ====================================================
// @desc    Helper to auto-ensure Department Batch Group Chat exists
// ====================================================
async function ensureDepartmentGroupChat(user) {
    const department = user.department || 'Computer Science & Engineering';
    const groupName = `${department} - Batch Portal`;

    let groupChat = await Chat.findOne({
        isGroupChat: true,
        groupType: 'department_batch',
        department: department
    }).populate('users', '-password').populate('latestMessage');

    if (!groupChat) {
        // Find all users in this department
        const deptUsers = await User.find({ department: department }).select('_id');
        const userIds = deptUsers.map(u => u._id);

        if (!userIds.some(id => id.toString() === user._id.toString())) {
            userIds.push(user._id);
        }

        groupChat = await Chat.create({
            name: groupName,
            isGroupChat: true,
            groupType: 'department_batch',
            department: department,
            semester: user.semester || 'Semester 1',
            batch: user.batch || '2024 - 2028',
            users: userIds,
            groupAdmin: user._id
        });

        // Create initial welcome message
        const welcomeMessage = await Message.create({
            chat: groupChat._id,
            sender: user._id,
            senderName: 'Learnova LMS Bot',
            senderRole: 'admin',
            senderDepartment: department,
            content: `👋 Welcome to the official ${department} discussion group! Students and faculty can share notices, ask questions, and collaborate here.`
        });

        groupChat.latestMessage = welcomeMessage._id;
        await groupChat.save();

        groupChat = await Chat.findById(groupChat._id)
            .populate('users', '-password')
            .populate('latestMessage');
    } else {
        // Ensure this user is added to the group if not already
        const isMember = groupChat.users.some(u => (u._id || u).toString() === user._id.toString());
        if (!isMember) {
            groupChat.users.push(user._id);
            await groupChat.save();
        }
    }

    return groupChat;
}

// ====================================================
// @desc    Access or create 1-to-1 direct chat
// @route   POST /api/chats
// @access  Private
// ====================================================
exports.accessOrCreateDirectChat = async (req, res) => {
    try {
        const { userId } = req.body;

        if (!userId) {
            return res.status(400).json({
                success: false,
                message: 'Target userId parameter is required'
            });
        }

        if (userId.toString() === req.user._id.toString()) {
            return res.status(400).json({
                success: false,
                message: 'You cannot create a chat with yourself'
            });
        }

        // Check if chat already exists
        let isChat = await Chat.find({
            isGroupChat: false,
            $and: [
                { users: { $elemMatch: { $eq: req.user._id } } },
                { users: { $elemMatch: { $eq: userId } } }
            ]
        })
            .populate('users', '-password')
            .populate({
                path: 'latestMessage',
                populate: { path: 'sender', select: 'name email profileImage role' }
            });

        if (isChat.length > 0) {
            return res.status(200).json({
                success: true,
                chat: isChat[0]
            });
        }

        // Fetch other user's info for naming/context
        const otherUser = await User.findById(userId);
        if (!otherUser) {
            return res.status(404).json({
                success: false,
                message: 'Target user not found'
            });
        }

        const chatData = {
            name: `${otherUser.name}`,
            isGroupChat: false,
            groupType: 'direct',
            department: req.user.department || otherUser.department || '',
            users: [req.user._id, userId]
        };

        const createdChat = await Chat.create(chatData);
        const fullChat = await Chat.findById(createdChat._id).populate('users', '-password');

        res.status(201).json({
            success: true,
            message: 'Chat initialized successfully',
            chat: fullChat
        });
    } catch (error) {
        console.error('accessOrCreateDirectChat error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error accessing chat',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Get all chats for the logged in user (Direct + Department Group)
// @route   GET /api/chats
// @access  Private
// ====================================================
exports.fetchUserChats = async (req, res) => {
    try {
        // 1. Ensure department group exists for this user
        if (req.user.department) {
            await ensureDepartmentGroupChat(req.user);
        }

        // 2. Query all chats where user is a participant
        const chats = await Chat.find({
            users: { $elemMatch: { $eq: req.user._id } }
        })
            .populate('users', '-password')
            .populate('groupAdmin', '-password')
            .populate({
                path: 'latestMessage',
                populate: { path: 'sender', select: 'name email profileImage role' }
            })
            .sort({ updatedAt: -1 });

        res.status(200).json({
            success: true,
            count: chats.length,
            chats
        });
    } catch (error) {
        console.error('fetchUserChats error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error fetching chats',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Get Department Contacts (Teachers & Students in same department)
// @route   GET /api/chats/contacts
// @access  Private
// ====================================================
exports.getDepartmentContacts = async (req, res) => {
    try {
        const userDept = (req.user.department || '').trim();

        let filter = { _id: { $ne: req.user._id } };
        if (userDept) {
            const escaped = userDept.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            filter.department = { $regex: new RegExp(`^${escaped}$`, 'i') };
        }

        let contacts = await User.find(filter)
            .select('name email role department designation facultyId studentId profileImage semester batch')
            .sort({ role: -1, name: 1 }); // Teachers first, then students

        // If no contacts in exact match, try matching department keywords
        if (contacts.length === 0 && userDept) {
            const words = userDept.split(/[\s&,-]+/).filter(w => w.length > 2);
            if (words.length > 0) {
                contacts = await User.find({
                    _id: { $ne: req.user._id },
                    department: { $regex: new RegExp(words.join('|'), 'i') }
                })
                    .select('name email role department designation facultyId studentId profileImage semester batch')
                    .sort({ role: -1, name: 1 });
            }
        }

        const teachers = contacts.filter(c => c.role === 'teacher' || c.role === 'admin');
        const students = contacts.filter(c => c.role === 'student');

        res.status(200).json({
            success: true,
            department: userDept || 'All',
            totalContacts: contacts.length,
            teachers,
            students
        });
    } catch (error) {
        console.error('getDepartmentContacts error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Error fetching department contacts',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Get all messages for a specific chat
// @route   GET /api/chats/:chatId/messages
// @access  Private
// ====================================================
exports.fetchMessages = async (req, res) => {
    try {
        const { chatId } = req.params;

        const chat = await Chat.findById(chatId);
        if (!chat) {
            return res.status(404).json({
                success: false,
                message: 'Chat not found'
            });
        }

        // Strict authorization check: User must be a member of this chat
        const isParticipant = chat.users.some(
            u => u.toString() === req.user._id.toString()
        );

        if (!isParticipant) {
            return res.status(403).json({
                success: false,
                message: 'Access denied: You are not authorized to view messages in this chat'
            });
        }

        const messages = await Message.find({ chat: chatId })
            .populate('sender', 'name email profileImage role department designation')
            .sort({ createdAt: 1 });

        // Mark messages as read by current user
        await Message.updateMany(
            { chat: chatId, readBy: { $ne: req.user._id } },
            { $addToSet: { readBy: req.user._id } }
        );

        res.status(200).json({
            success: true,
            count: messages.length,
            messages
        });
    } catch (error) {
        console.error('fetchMessages error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Error fetching messages',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Send a message in a chat (REST endpoint)
// @route   POST /api/chats/:chatId/messages
// @access  Private
// ====================================================
exports.sendMessage = async (req, res) => {
    try {
        const { chatId } = req.params;
        const { content, type, fileUrl, fileName } = req.body;

        if (!content || content.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'Message content is required'
            });
        }

        const chat = await Chat.findById(chatId);
        if (!chat) {
            return res.status(404).json({
                success: false,
                message: 'Chat not found'
            });
        }

        // Strict authorization check: User must be a member of this chat
        const isParticipant = chat.users.some(
            u => u.toString() === req.user._id.toString()
        );

        if (!isParticipant) {
            return res.status(403).json({
                success: false,
                message: 'Access denied: You cannot send messages to a chat you do not belong to'
            });
        }

        // Create Message
        let message = await Message.create({
            chat: chatId,
            sender: req.user._id,
            senderName: req.user.name,
            senderRole: req.user.role,
            senderDepartment: req.user.department || '',
            content: content.trim(),
            type: type || 'text',
            fileUrl: fileUrl || '',
            fileName: fileName || '',
            readBy: [req.user._id]
        });

        // Update Chat's latest message and updated time
        await Chat.findByIdAndUpdate(chatId, {
            latestMessage: message._id,
            updatedAt: new Date()
        });

        message = await Message.findById(message._id)
            .populate('sender', 'name email profileImage role department designation')
            .populate('chat');

        // Broadcast via Socket.IO directly from backend for guaranteed real-time delivery
        const io = req.app.get('io');
        if (io) {
            io.to(chatId.toString()).emit('message_received', message);
            // Also emit to all participants' personal user rooms
            if (chat.users && Array.isArray(chat.users)) {
                chat.users.forEach(userId => {
                    if (userId) {
                        io.to(userId.toString()).emit('message_received', message);
                    }
                });
            }
        }

        res.status(201).json({
            success: true,
            message
        });
    } catch (error) {
        console.error('sendMessage error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Error sending message',
            error: error.message
        });
    }
};
