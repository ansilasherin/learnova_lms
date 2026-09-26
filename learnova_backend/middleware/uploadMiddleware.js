const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
const videoUploadDir = path.join(__dirname, '../uploads/videos');
const docUploadDir = path.join(__dirname, '../uploads/documents');

if (!fs.existsSync(videoUploadDir)) {
    fs.mkdirSync(videoUploadDir, { recursive: true });
}
if (!fs.existsSync(docUploadDir)) {
    fs.mkdirSync(docUploadDir, { recursive: true });
}

// Video Storage configuration
const videoStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, videoUploadDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const ext = path.extname(file.originalname);
        cb(null, 'video-' + uniqueSuffix + ext);
    }
});

// Document Storage configuration
const docStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, docUploadDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const cleanName = file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_');
        cb(null, 'doc-' + uniqueSuffix + '-' + cleanName);
    }
});

// File filter for video formats
const videoFilter = (req, file, cb) => {
    const allowedExtensions = ['.mp4', '.mov', '.mkv', '.webm', '.avi', '.m4v'];
    const ext = path.extname(file.originalname).toLowerCase();
    
    if (allowedExtensions.includes(ext) || file.mimetype.startsWith('video/')) {
        cb(null, true);
    } else {
        cb(new Error('Only video files (MP4, MOV, MKV, WEBM) are allowed!'), false);
    }
};

// File filter for document formats
const docFilter = (req, file, cb) => {
    const allowedExtensions = ['.pdf', '.doc', '.docx', '.ppt', '.pptx', '.txt', '.md', '.zip', '.xls', '.xlsx'];
    const ext = path.extname(file.originalname).toLowerCase();
    
    if (allowedExtensions.includes(ext) || file.mimetype.includes('pdf') || file.mimetype.includes('document') || file.mimetype.includes('text')) {
        cb(null, true);
    } else {
        cb(new Error('Only document files (PDF, DOCX, PPTX, TXT, MD, ZIP) are allowed!'), false);
    }
};

const uploadVideo = multer({
    storage: videoStorage,
    limits: {
        fileSize: 500 * 1024 * 1024 // 500MB max video file size
    },
    fileFilter: videoFilter
});

const uploadDocument = multer({
    storage: docStorage,
    limits: {
        fileSize: 100 * 1024 * 1024 // 100MB max document file size
    },
    fileFilter: docFilter
});

// Default export is uploadVideo for backward compatibility, with uploadDocument attached
const upload = uploadVideo;
upload.uploadVideo = uploadVideo;
upload.uploadDocument = uploadDocument;

module.exports = upload;
