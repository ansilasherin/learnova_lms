const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const path = require('path');
const fs = require('fs');

// ====================================================
// @desc    Get all published courses (Public)
// @route   GET /api/courses
// @access  Public
// ====================================================
const getAllCourses = async (req, res) => {
    try {
        const { category, search, level } = req.query;

        // Build filter query
        let query = { isPublished: true };

        if (category) {
            query.category = { $regex: category, $options: 'i' };
        }

        if (level) {
            query.level = level;
        }

        if (search) {
            query.$or = [
                { title: { $regex: search, $options: 'i' } },
                { description: { $regex: search, $options: 'i' } }
            ];
        }

        // Fetch courses and populate instructor details (name, email, profileImage)
        const courses = await Course.find(query)
            .populate('instructor', 'name email profileImage')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: courses.length,
            message: 'Courses fetched successfully! 📚',
            courses
        });
    } catch (error) {
        console.error('Get All Courses Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error fetching courses',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Get single course details by ID
// @route   GET /api/courses/:id
// @access  Public
// ====================================================
const getCourseById = async (req, res) => {
    try {
        const course = await Course.findById(req.params.id)
            .populate('instructor', 'name email profileImage role')
            .populate('enrolledStudents', 'name email');

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        res.status(200).json({
            success: true,
            course
        });
    } catch (error) {
        console.error('Get Course Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error fetching course details',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Create a new course (Teacher / Admin)
// @route   POST /api/courses
// @access  Private (Teacher, Admin)
// ====================================================
const createCourse = async (req, res) => {
    try {
        const { title, description, category, price, level, thumbnail, lessons } = req.body;

        // 1. Validation
        if (!title || !description || !category) {
            return res.status(400).json({
                success: false,
                message: 'Please provide course title, description, and category'
            });
        }

        // 2. Create course and assign logged-in user as instructor
        const course = await Course.create({
            title,
            description,
            category,
            price: price !== undefined ? price : 0,
            level: level || 'Beginner',
            thumbnail: thumbnail || undefined,
            lessons: lessons || [],
            instructor: req.user._id // Extracted securely from verified JWT
        });

        res.status(201).json({
            success: true,
            message: 'Course created successfully! 🎉',
            course
        });

    } catch (error) {
        console.error('Create Course Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error creating course',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Update course details (Instructor or Admin only)
// @route   PUT /api/courses/:id
// @access  Private (Teacher/Admin)
// ====================================================
const updateCourse = async (req, res) => {
    try {
        let course = await Course.findById(req.params.id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Make sure user is the course instructor or an Admin
        if (course.instructor.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to update this course'
            });
        }

        course = await Course.findByIdAndUpdate(req.params.id, req.body, {
            new: true,
            runValidators: true
        });

        res.status(200).json({
            success: true,
            message: 'Course updated successfully! ✅',
            course
        });

    } catch (error) {
        console.error('Update Course Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error updating course',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Delete a course (Instructor or Admin only)
// @route   DELETE /api/courses/:id
// @access  Private (Teacher/Admin)
// ====================================================
const deleteCourse = async (req, res) => {
    try {
        const course = await Course.findById(req.params.id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Make sure user is course instructor or Admin
        if (course.instructor.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to delete this course'
            });
        }

        // 1. Delete all student enrollments associated with this course
        await Enrollment.deleteMany({ course: req.params.id });

        // 2. Clean up any physical uploaded video files if present
        if (course.lessons && course.lessons.length > 0) {
            for (const lesson of course.lessons) {
                if (lesson.videoUrl && lesson.videoUrl.includes('/uploads/videos/')) {
                    try {
                        const filename = lesson.videoUrl.split('/uploads/videos/').pop();
                        const filePath = path.join(__dirname, '../uploads/videos', filename);
                        if (fs.existsSync(filePath)) {
                            fs.unlinkSync(filePath);
                        }
                    } catch (err) {
                        console.error('Failed to remove lesson video file:', err.message);
                    }
                }
            }
        }

        // 3. Delete the course document itself
        await Course.findByIdAndDelete(req.params.id);

        res.status(200).json({
            success: true,
            message: 'Course and all related student enrollments deleted successfully! 🗑️'
        });

    } catch (error) {
        console.error('Delete Course Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error deleting course',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Add a lesson to a course (Instructor or Admin)
// @route   POST /api/courses/:id/lessons
// @access  Private (Teacher/Admin)
// ====================================================
const addLesson = async (req, res) => {
    try {
        const { title, description, videoUrl, duration, isFreePreview } = req.body;

        if (!title || !videoUrl) {
            return res.status(400).json({
                success: false,
                message: 'Lesson title and video URL are required'
            });
        }

        const course = await Course.findById(req.params.id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Check ownership or admin
        if (course.instructor.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to add lessons to this course'
            });
        }

        // Add new lesson to lessons array
        course.lessons.push({
            title,
            description: description || '',
            videoUrl,
            duration: duration || '',
            isFreePreview: isFreePreview || false
        });

        await course.save();

        res.status(201).json({
            success: true,
            message: 'Lesson added successfully! 🎬',
            course: course,
            lessons: course.lessons
        });

    } catch (error) {
        console.error('Add Lesson Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error adding lesson',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Delete a lesson from a course (Instructor or Admin)
// @route   DELETE /api/courses/:id/lessons/:lessonId
// @access  Private (Teacher/Admin)
// ====================================================
const deleteLesson = async (req, res) => {
    try {
        const { id, lessonId } = req.params;

        const course = await Course.findById(id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Check ownership or admin
        if (course.instructor.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to delete lessons from this course'
            });
        }

        // Find the lesson
        const lesson = course.lessons.id(lessonId);
        if (!lesson) {
            return res.status(404).json({
                success: false,
                message: 'Lesson not found'
            });
        }

        // Clean up physical uploaded file from disk if local upload
        if (lesson.videoUrl && lesson.videoUrl.includes('/uploads/videos/')) {
            try {
                const filename = lesson.videoUrl.split('/uploads/videos/').pop();
                const filePath = path.join(__dirname, '../uploads/videos', filename);
                if (fs.existsSync(filePath)) {
                    fs.unlinkSync(filePath);
                }
            } catch (err) {
                console.error('Failed to remove physical video file:', err.message);
            }
        }

        // Remove the lesson from course lessons array
        course.lessons.pull({ _id: lessonId });
        await course.save();

        res.status(200).json({
            success: true,
            message: 'Lesson deleted successfully! 🗑️',
            course: course,
            lessons: course.lessons
        });

    } catch (error) {
        console.error('Delete Lesson Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error deleting lesson',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Add a study material/slide to a course (Instructor or Admin)
// @route   POST /api/courses/:id/materials
// @access  Private (Teacher/Admin)
// ====================================================
const addMaterial = async (req, res) => {
    try {
        const { title, description, type, fileUrl, fileSize } = req.body;

        if (!title || !fileUrl) {
            return res.status(400).json({
                success: false,
                message: 'Material title and file URL are required'
            });
        }

        const course = await Course.findById(req.params.id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Check ownership or admin
        if (course.instructor.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to add study materials to this course'
            });
        }

        course.materials.push({
            title,
            description: description || '',
            type: type || 'pdf',
            fileUrl,
            fileSize: fileSize || '2.5 MB'
        });

        await course.save();

        res.status(201).json({
            success: true,
            message: 'Study material added successfully! 📑',
            course: course,
            materials: course.materials
        });

    } catch (error) {
        console.error('Add Material Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error adding study material',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Delete a study material from a course (Instructor or Admin)
// @route   DELETE /api/courses/:id/materials/:materialId
// @access  Private (Teacher/Admin)
// ====================================================
const deleteMaterial = async (req, res) => {
    try {
        const { id, materialId } = req.params;

        const course = await Course.findById(id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Check ownership or admin
        if (course.instructor.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to delete materials from this course'
            });
        }

        course.materials.pull({ _id: materialId });
        await course.save();

        res.status(200).json({
            success: true,
            message: 'Study material deleted successfully! 🗑️',
            course: course,
            materials: course.materials
        });

    } catch (error) {
        console.error('Delete Material Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error deleting material',
            error: error.message
        });
    }
};

// ====================================================
// @desc    Update / Replace a study material in a course (Instructor or Admin)
// @route   PUT /api/courses/:id/materials/:materialId
// @access  Private (Teacher/Admin)
// ====================================================
const updateMaterial = async (req, res) => {
    try {
        const { id, materialId } = req.params;
        const { title, description, type, fileUrl, fileSize } = req.body;

        const course = await Course.findById(id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Check ownership or admin
        if (course.instructor.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to update materials for this course'
            });
        }

        const material = course.materials.id(materialId);
        if (!material) {
            return res.status(404).json({
                success: false,
                message: 'Study material not found'
            });
        }

        if (title) material.title = title;
        if (description !== undefined) material.description = description;
        if (type) material.type = type;
        if (fileUrl) material.fileUrl = fileUrl;
        if (fileSize) material.fileSize = fileSize;

        await course.save();

        res.status(200).json({
            success: true,
            message: 'Study material updated successfully! ✅',
            course: course,
            materials: course.materials
        });

    } catch (error) {
        console.error('Update Material Error:', error.message);
        res.status(500).json({
            success: false,
            message: 'Server error updating material',
            error: error.message
        });
    }
};

module.exports = {
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
};
