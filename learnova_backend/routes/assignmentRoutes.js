const express = require('express');
const router = express.Router();
const {
    getAssignments,
    createAssignment,
    submitAssignment,
    gradeSubmission,
    deleteAssignment
} = require('../controllers/assignmentController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

router
    .route('/')
    .get(getAssignments)
    .post(authorize('teacher', 'admin'), createAssignment);

router
    .route('/:id')
    .delete(authorize('teacher', 'admin'), deleteAssignment);

router
    .route('/:id/submit')
    .put(authorize('student'), submitAssignment);

router
    .route('/:id/submissions/:submissionId/grade')
    .put(authorize('teacher', 'admin'), gradeSubmission);

module.exports = router;

