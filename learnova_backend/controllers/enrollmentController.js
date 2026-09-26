const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');

// ====================================================
// @desc    Enroll logged-in student in a course
// @route   POST /api/enrollments/:courseId
// @access  Private (Student only)
// ====================================================
const enrollInCourse = async (req, res) => {
    try {
        const { courseId } = req.params;

        // 1. Check if course exists
        const course = await Course.findById(courseId);
        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // 2. Check if already enrolled
        const existingEnrollment = await Enrollment.findOne({
            student: req.user._id,
            course: courseId
        });

        if (existingEnrollment) {
            return res.status(400).json({
                success: false,
                message: 'You are already enrolled in this course'
            });
        }

        // 3. Create Enrollment record
        const enrollment = await Enrollment.create({
            student: req.user._id,
            course: courseId,
            completedLessons: [],
            progressPercentage: 0
        });

        // 4. Also add student ID to Course.enrolledStudents array
        if (!course.enrolledStudents.includes(req.user._id)) {
            course.enrolledStudents.push(req.user._id);
            await course.save();
        }

        res.status(201).json({
            success: true,
            message: `Successfully enrolled in "${course.title}"! 🎓`,
            enrollment
        });

    } catch (error) {
        console.error('Enroll Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error during course enrollment',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Get all enrolled courses for logged-in student
// @route   GET /api/enrollments/my-courses
// @access  Private (Student only)
// ====================================================
const getMyEnrolledCourses = async (req, res) => {
    try {
        const enrollments = await Enrollment.find({ student: req.user._id })
            .populate({
                path: 'course',
                select: 'title description thumbnail category price level instructor lessons',
                populate: {
                    path: 'instructor',
                    select: 'name email profileImage'
                }
            })
            .sort({ createdAt: -1 });

        // Filter out any enrollments whose course no longer exists
        const validEnrollments = enrollments.filter(e => e.course != null);

        // Clean up orphan enrollment records asynchronously
        const orphanEnrollmentIds = enrollments.filter(e => e.course == null).map(e => e._id);
        if (orphanEnrollmentIds.length > 0) {
            Enrollment.deleteMany({ _id: { $in: orphanEnrollmentIds } }).catch(err => {
                console.error('Failed to clean up orphan enrollments:', err.message);
            });
        }

        res.status(200).json({
            success: true,
            count: validEnrollments.length,
            message: 'Enrolled courses fetched successfully! 📖',
            enrollments: validEnrollments
        });

    } catch (error) {
        console.error('Get My Courses Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error fetching your enrolled courses',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Mark a lesson as completed & update progress %
// @route   PUT /api/enrollments/:courseId/lessons/:lessonId/complete
// @access  Private (Student only)
// ====================================================
const updateLessonProgress = async (req, res) => {
    try {
        const { courseId, lessonId } = req.params;

        // 1. Find the enrollment record
        const enrollment = await Enrollment.findOne({
            student: req.user._id,
            course: courseId
        });

        if (!enrollment) {
            return res.status(404).json({
                success: false,
                message: 'You are not enrolled in this course'
            });
        }

        // 2. Find the course to count total lessons
        const course = await Course.findById(courseId);
        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        const totalLessons = course.lessons.length;
        if (totalLessons === 0) {
            return res.status(400).json({
                success: false,
                message: 'Course has no lessons to complete'
            });
        }

        // 3. Add lessonId to completedLessons if not already present
        const alreadyCompleted = enrollment.completedLessons.some(
            (id) => id.toString() === lessonId.toString()
        );

        if (!alreadyCompleted) {
            enrollment.completedLessons.push(lessonId);
        }

        // 4. Calculate progress percentage
        const completedCount = enrollment.completedLessons.length;
        enrollment.progressPercentage = Math.round((completedCount / totalLessons) * 100);

        if (enrollment.progressPercentage >= 100) {
            enrollment.progressPercentage = 100;
            enrollment.isCompleted = true;
        }

        await enrollment.save();

        res.status(200).json({
            success: true,
            message: enrollment.isCompleted
                ? 'Congratulations! You have completed the entire course! 🏆'
                : 'Lesson progress updated successfully! ✅',
            progressPercentage: enrollment.progressPercentage,
            isCompleted: enrollment.isCompleted,
            completedLessonsCount: completedCount,
            totalLessonsCount: totalLessons
        });

    } catch (error) {
        console.error('Update Progress Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error updating lesson progress',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Get progress details for a single course
// @route   GET /api/enrollments/:courseId/progress
// @access  Private (Student only)
// ====================================================
const getCourseProgress = async (req, res) => {
    try {
        const { courseId } = req.params;

        const enrollment = await Enrollment.findOne({
            student: req.user._id,
            course: courseId
        }).populate('course', 'title lessons');

        if (!enrollment) {
            return res.status(404).json({
                success: false,
                message: 'No enrollment record found for this course'
            });
        }

        res.status(200).json({
            success: true,
            enrollment
        });

    } catch (error) {
        console.error('Get Course Progress Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error fetching course progress',
            error: error.message
        });
    }
};

module.exports = {
    enrollInCourse,
    getMyEnrolledCourses,
    updateLessonProgress,
    getCourseProgress
};
