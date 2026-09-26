const express = require('express');
const router = express.Router();
const {
    getAllCourses,
    getCourseById,
    createCourse,
    updateCourse,
    deleteCourse,
    addLesson,
    deleteLesson,
    addMaterial,
    deleteMaterial,
    updateMaterial
} = require('../controllers/courseController');

const { protect } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const upload = require('../middleware/uploadMiddleware');

// ----------------------------------------------------
// Course Routes Definition
// ----------------------------------------------------

// Video Upload Route: POST /api/courses/upload-video
router.post('/upload-video', protect, authorizeRoles('teacher', 'admin'), upload.uploadVideo.single('video'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Please upload a video file!'
            });
        }

        const protocol = req.protocol;
        const host = req.get('host');
        const videoUrl = `${protocol}://${host}/uploads/videos/${req.file.filename}`;

        res.status(200).json({
            success: true,
            message: 'Video uploaded successfully! 🎬',
            videoUrl: videoUrl,
            filename: req.file.filename,
            size: req.file.size
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Video upload failed',
            error: error.message
        });
    }
});

// Document / PDF / Material Upload Route: POST /api/courses/upload-document
router.post('/upload-document', protect, authorizeRoles('teacher', 'admin'), upload.uploadDocument.single('document'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Please upload a document file (PDF, DOCX, PPTX, TXT)!'
            });
        }

        const protocol = req.protocol;
        const host = req.get('host');
        const fileUrl = `${protocol}://${host}/uploads/documents/${req.file.filename}`;
        
        let sizeStr = `${(req.file.size / (1024 * 1024)).toFixed(1)} MB`;
        if (req.file.size < 1024 * 1024) {
            sizeStr = `${Math.round(req.file.size / 1024)} KB`;
        }

        res.status(200).json({
            success: true,
            message: 'Document uploaded successfully! 📁',
            fileUrl: fileUrl,
            filename: req.file.filename,
            originalName: req.file.originalname,
            fileSize: sizeStr,
            sizeBytes: req.file.size
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Document upload failed',
            error: error.message
        });
    }
});

// Public: GET /api/courses (Browse all)
// Private (Teacher/Admin): POST /api/courses (Create course)
router.route('/')
    .get(getAllCourses)
    .post(protect, authorizeRoles('teacher', 'admin'), createCourse);

// Public: GET /api/courses/:id (Single course details)
// Private (Teacher/Admin): PUT /api/courses/:id (Update course)
// Private (Teacher/Admin): DELETE /api/courses/:id (Delete course)
router.route('/:id')
    .get(getCourseById)
    .put(protect, authorizeRoles('teacher', 'admin'), updateCourse)
    .delete(protect, authorizeRoles('teacher', 'admin'), deleteCourse);

// Private (Teacher/Admin): POST /api/courses/:id/lessons (Add lesson)
router.route('/:id/lessons')
    .post(protect, authorizeRoles('teacher', 'admin'), addLesson);

// Private (Teacher/Admin): DELETE /api/courses/:id/lessons/:lessonId (Delete lesson)
router.route('/:id/lessons/:lessonId')
    .delete(protect, authorizeRoles('teacher', 'admin'), deleteLesson);

// Private (Teacher/Admin): POST /api/courses/:id/materials (Add study material/slide)
router.route('/:id/materials')
    .post(protect, authorizeRoles('teacher', 'admin'), addMaterial);

// Private (Teacher/Admin): PUT (Update/Replace), DELETE (Remove) study material
router.route('/:id/materials/:materialId')
    .put(protect, authorizeRoles('teacher', 'admin'), updateMaterial)
    .delete(protect, authorizeRoles('teacher', 'admin'), deleteMaterial);

module.exports = router;
