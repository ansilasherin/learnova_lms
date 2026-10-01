const mongoose = require('mongoose');

// ----------------------------------------------------
// Chat / Conversation Schema
// Supports 1-to-1 direct messaging and Department Batch group chats
// ----------------------------------------------------
const chatSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            trim: true,
            default: ''
        },
        isGroupChat: {
            type: Boolean,
            default: false
        },
        groupType: {
            type: String,
            enum: ['direct', 'department_batch', 'course_forum'],
            default: 'direct'
        },
        department: {
            type: String,
            trim: true,
            default: ''
        },
        semester: {
            type: String,
            trim: true,
            default: ''
        },
        batch: {
            type: String,
            trim: true,
            default: ''
        },
        groupAvatar: {
            type: String,
            default: ''
        },
        users: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User'
            }
        ],
        latestMessage: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Message'
        },
        groupAdmin: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    },
    {
        timestamps: true
    }
);

const Chat = mongoose.model('Chat', chatSchema);

module.exports = Chat;
