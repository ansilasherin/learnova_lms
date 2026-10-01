const mongoose = require('mongoose');

// ----------------------------------------------------
// Message Schema
// Supports real-time text, media attachments, sender details & read receipts
// ----------------------------------------------------
const messageSchema = new mongoose.Schema(
    {
        chat: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Chat',
            required: true
        },
        sender: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        senderName: {
            type: String,
            default: ''
        },
        senderRole: {
            type: String,
            enum: ['student', 'teacher', 'admin'],
            default: 'student'
        },
        senderDepartment: {
            type: String,
            default: ''
        },
        content: {
            type: String,
            trim: true,
            required: [true, 'Message content cannot be empty']
        },
        type: {
            type: String,
            enum: ['text', 'image', 'file', 'code'],
            default: 'text'
        },
        fileUrl: {
            type: String,
            default: ''
        },
        fileName: {
            type: String,
            default: ''
        },
        readBy: [
            {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User'
            }
        ]
    },
    {
        timestamps: true
    }
);

const Message = mongoose.model('Message', messageSchema);

module.exports = Message;
