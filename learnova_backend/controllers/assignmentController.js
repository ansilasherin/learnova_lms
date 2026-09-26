const Assignment = require('../models/Assignment');
const User = require('../models/User');

// ----------------------------------------------------
// @desc    Get all assignments (Role-aware)
// @route   GET /api/assignments
// @access  Private
// ----------------------------------------------------
exports.getAssignments = async (req, res) => {
    try {
        const user = req.user;
        const assignments = await Assignment.find()
            .populate('submissions.student', 'name email studentId profileImage')
            .populate('createdBy', 'name email')
            .sort({ createdAt: -1 });

        // If Teacher or Admin: return full assignment details with all student submissions
        if (user.role === 'teacher' || user.role === 'admin') {
            const teacherFormatted = assignments.map((a) => {
                const submissions = (a.submissions || []).map((s) => ({
                    id: s._id,
                    studentId: s.student ? (s.student._id || s.student) : '',
                    studentName: s.student?.name || s.studentName || 'Student',
                    studentEmail: s.student?.email || s.studentEmail || '',
                    studentRollNo: s.student?.studentId || s.studentRollNo || '',
                    profileImage: s.student?.profileImage || '',
                    submittedAt: s.submittedAt,
                    fileName: s.fileName || '',
                    fileUrl: s.fileUrl || '',
                    submissionText: s.submissionText || '',
                    status: s.status || 'submitted',
                    score: s.score,
                    maxScore: s.maxScore || a.maxScore || 100,
                    feedback: s.feedback || '',
                    gradedAt: s.gradedAt,
                    gradedByName: s.gradedByName || ''
                }));

                const totalSubmissions = submissions.length;
                const gradedCount = submissions.filter((s) => s.status === 'graded').length;
                const pendingCount = totalSubmissions - gradedCount;

                return {
                    id: a._id,
                    title: a.title,
                    subject: a.subject,
                    description: a.description || '',
                    dueDate: a.dueDate,
                    priority: a.priority,
                    maxScore: a.maxScore || 100,
                    progress: a.progress || 0,
                    totalSubmissions,
                    gradedCount,
                    pendingCount,
                    submissions
                };
            });

            return res.status(200).json({
                success: true,
                count: teacherFormatted.length,
                isTeacher: true,
                assignments: teacherFormatted
            });
        }

        // Student View: map student-specific submission and results
        const studentFormatted = assignments.map((a) => {
            const submission = a.submissions.find(
                (s) => s.student && s.student._id.toString() === user._id.toString()
            );

            return {
                id: a._id,
                title: a.title,
                subject: a.subject,
                description: a.description || '',
                dueDate: a.dueDate,
                priority: a.priority,
                maxScore: a.maxScore || 100,
                progress: submission ? (submission.status === 'graded' ? 100 : 80) : a.progress,
                status: submission ? submission.status : 'pending',
                score: submission ? submission.score : null,
                feedback: submission ? submission.feedback : '',
                submittedAt: submission ? submission.submittedAt : null,
                fileName: submission ? submission.fileName : '',
                submissionText: submission ? submission.submissionText : '',
                gradedByName: submission ? submission.gradedByName : ''
            };
        });

        res.status(200).json({
            success: true,
            count: studentFormatted.length,
            isTeacher: false,
            assignments: studentFormatted
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error fetching assignments',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Create an assignment (Teacher/Admin)
// @route   POST /api/assignments
// @access  Private (Teacher, Admin)
// ----------------------------------------------------
exports.createAssignment = async (req, res) => {
    try {
        const { title, subject, description, dueDate, priority, maxScore } = req.body;

        if (!title || !subject || !dueDate) {
            return res.status(400).json({
                success: false,
                message: 'Please provide title, subject, and due date'
            });
        }

        const assignment = await Assignment.create({
            title,
            subject,
            description: description || '',
            dueDate,
            priority: priority || 'Medium Priority',
            maxScore: maxScore ? Number(maxScore) : 100,
            createdBy: req.user._id,
            submissions: []
        });

        res.status(201).json({
            success: true,
            message: 'Assignment created successfully! 📝',
            assignment
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error creating assignment',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Submit assignment (Student)
// @route   PUT /api/assignments/:id/submit
// @access  Private (Student)
// ----------------------------------------------------
exports.submitAssignment = async (req, res) => {
    try {
        const { fileName, fileUrl, submissionText } = req.body || {};
        const assignment = await Assignment.findById(req.params.id);
        if (!assignment) {
            return res.status(404).json({
                success: false,
                message: 'Assignment not found'
            });
        }

        const existingIndex = assignment.submissions.findIndex(
            (s) => s.student && s.student.toString() === req.user._id.toString()
        );

        if (existingIndex !== -1) {
            assignment.submissions[existingIndex].submittedAt = new Date();
            assignment.submissions[existingIndex].status = 'submitted';
            if (fileName) assignment.submissions[existingIndex].fileName = fileName;
            if (fileUrl) assignment.submissions[existingIndex].fileUrl = fileUrl;
            if (submissionText) assignment.submissions[existingIndex].submissionText = submissionText;
            assignment.submissions[existingIndex].studentName = req.user.name;
            assignment.submissions[existingIndex].studentEmail = req.user.email;
            assignment.submissions[existingIndex].studentRollNo = req.user.studentId || '';
        } else {
            assignment.submissions.push({
                student: req.user._id,
                studentName: req.user.name,
                studentEmail: req.user.email,
                studentRollNo: req.user.studentId || '',
                submittedAt: new Date(),
                status: 'submitted',
                fileName: fileName || '',
                fileUrl: fileUrl || '',
                submissionText: submissionText || '',
                maxScore: assignment.maxScore || 100
            });
        }

        await assignment.save();

        res.status(200).json({
            success: true,
            message: 'Assignment submitted successfully! 🎉'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error submitting assignment',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Grade student submission (Teacher/Admin)
// @route   PUT /api/assignments/:id/submissions/:submissionId/grade
// @access  Private (Teacher, Admin)
// ----------------------------------------------------
exports.gradeSubmission = async (req, res) => {
    try {
        const { id, submissionId } = req.params;
        const { score, feedback } = req.body;

        if (score === undefined || score === null) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a grade score'
            });
        }

        const assignment = await Assignment.findById(id);
        if (!assignment) {
            return res.status(404).json({
                success: false,
                message: 'Assignment not found'
            });
        }

        const submission = assignment.submissions.id(submissionId);
        if (!submission) {
            return res.status(404).json({
                success: false,
                message: 'Submission not found'
            });
        }

        submission.score = Number(score);
        submission.feedback = feedback !== undefined ? feedback : '';
        submission.status = 'graded';
        submission.gradedAt = new Date();
        submission.gradedBy = req.user._id;
        submission.gradedByName = req.user.name;

        await assignment.save();

        res.status(200).json({
            success: true,
            message: `Graded successfully with ${score}/${assignment.maxScore || 100} points! 🌟`,
            submission
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error grading submission',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Delete assignment (Teacher/Admin)
// @route   DELETE /api/assignments/:id
// @access  Private (Teacher, Admin)
// ----------------------------------------------------
exports.deleteAssignment = async (req, res) => {
    try {
        const assignment = await Assignment.findById(req.params.id);
        if (!assignment) {
            return res.status(404).json({
                success: false,
                message: 'Assignment not found'
            });
        }

        await Assignment.findByIdAndDelete(req.params.id);

        res.status(200).json({
            success: true,
            message: 'Assignment removed successfully 🗑️'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error deleting assignment',
            error: error.message
        });
    }
};

