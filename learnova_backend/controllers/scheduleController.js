const Schedule = require('../models/Schedule');

// ----------------------------------------------------
// @desc    Get all timetable schedules & user self-study tasks (Department-aware)
// @route   GET /api/schedules
// @access  Public / Private (with protectOptional)
// ----------------------------------------------------
exports.getSchedules = async (req, res) => {
    try {
        let query;

        if (req.user) {
            const userDept = req.user.department;

            if (req.user.role === 'student') {
                // Student gets: Classes in their own department + THEIR OWN self study tasks
                if (userDept) {
                    query = {
                        $or: [
                            { type: 'class', department: userDept },
                            { type: 'self_study', user: req.user._id }
                        ]
                    };
                } else {
                    query = {
                        $or: [
                            { type: 'class' },
                            { type: 'self_study', user: req.user._id }
                        ]
                    };
                }
            } else {
                // Teacher / Admin gets: Classes in their department + their own created items
                if (userDept) {
                    query = {
                        $or: [
                            { type: 'class', department: userDept },
                            { user: req.user._id }
                        ]
                    };
                } else {
                    query = { user: req.user._id };
                }
            }
        } else {
            // Unauthenticated: only official classes
            query = { type: 'class' };
        }

        let schedules = await Schedule.find(query).sort({ createdAt: 1 });

        // If no schedules exist in DB at all, seed initial realistic schedule for Computer Science
        if (schedules.length === 0 && (!req.user || req.user.department === 'Computer Science & Engineering')) {
            const initialSchedules = [
                {
                    title: 'Data Structures & Algorithms',
                    instructor: 'Prof. Mehta',
                    department: 'Computer Science & Engineering',
                    time: '09:00 AM - 10:30 AM',
                    duration: '1.5 hrs',
                    isLive: true,
                    color: '#6366F1',
                    type: 'class',
                    location: 'Lecture Hall 201',
                    dayOfWeek: 'Today'
                },
                {
                    title: 'Database Systems (DBMS)',
                    instructor: 'Prof. Iyer',
                    department: 'Computer Science & Engineering',
                    time: '11:30 AM - 12:30 PM',
                    duration: '1 hr',
                    isLive: true,
                    color: '#10B981',
                    type: 'class',
                    location: 'CS Hall 302',
                    dayOfWeek: 'Today'
                },
                {
                    title: 'Operating Systems (Lab)',
                    instructor: 'Prof. Verma',
                    department: 'Computer Science & Engineering',
                    time: '02:00 PM - 03:30 PM',
                    duration: '1.5 hrs',
                    isLive: true,
                    color: '#EF4444',
                    type: 'class',
                    location: 'Main Lab A',
                    dayOfWeek: 'Today'
                },
                {
                    title: 'Computer Networks Lecture',
                    instructor: 'Prof. Rao',
                    department: 'Computer Science & Engineering',
                    time: '04:00 PM - 05:00 PM',
                    duration: '1 hr',
                    isLive: false,
                    color: '#8B5CF6',
                    type: 'class',
                    location: 'Lecture Hall 105',
                    dayOfWeek: 'Today'
                }
            ];

            await Schedule.insertMany(initialSchedules);
            schedules = await Schedule.find(query).sort({ createdAt: 1 });
        }

        res.status(200).json({
            success: true,
            count: schedules.length,
            schedules: schedules.map((s) => ({
                id: s._id,
                title: s.title,
                instructor: s.instructor,
                department: s.department || 'General',
                time: s.time,
                duration: s.duration,
                isLive: s.isLive,
                color: s.color,
                type: s.type || 'class',
                location: s.location || '',
                notes: s.notes || '',
                isCompleted: s.isCompleted || false,
                dayOfWeek: s.dayOfWeek || 'Today'
            }))
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error fetching schedules',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Create schedule item (Teacher creates class, Student creates self-study task)
// @route   POST /api/schedules
// @access  Private (All authenticated users)
// ----------------------------------------------------
exports.createSchedule = async (req, res) => {
    try {
        const {
            title,
            instructor,
            department,
            semester,
            batch,
            time,
            duration,
            isLive,
            color,
            type,
            location,
            notes,
            dayOfWeek
        } = req.body;

        const scheduleType = type === 'self_study' ? 'self_study' : 'class';

        // If creating an official class, verify user is teacher or admin
        if (scheduleType === 'class' && req.user.role !== 'teacher' && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only teachers can schedule official classes. Students can add self-study tasks.'
            });
        }

        const schedule = await Schedule.create({
            user: req.user._id,
            title,
            instructor: scheduleType === 'self_study' ? 'Self Study' : (instructor || req.user.name || 'Professor'),
            department: department || req.user.department || 'Computer Science & Engineering',
            semester: semester || req.user.semester || 'Semester 1',
            batch: batch || req.user.batch || '2024 - 2028',
            time: time || '06:00 PM - 07:30 PM',
            duration: duration || '1 hr',
            isLive: isLive || false,
            color: color || (scheduleType === 'self_study' ? '#F59E0B' : '#6366F1'),
            type: scheduleType,
            location: location || (scheduleType === 'self_study' ? 'Study Desk' : 'Lecture Hall 201'),
            notes: notes || '',
            isCompleted: false,
            dayOfWeek: dayOfWeek || 'Today'
        });

        res.status(201).json({
            success: true,
            message: scheduleType === 'self_study'
                ? 'Study Goal saved successfully! 🎯'
                : 'Class scheduled successfully! 📅',
            schedule: {
                id: schedule._id,
                title: schedule.title,
                instructor: schedule.instructor,
                department: schedule.department,
                time: schedule.time,
                duration: schedule.duration,
                isLive: schedule.isLive,
                color: schedule.color,
                type: schedule.type,
                location: schedule.location,
                notes: schedule.notes,
                isCompleted: schedule.isCompleted,
                dayOfWeek: schedule.dayOfWeek
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error creating schedule',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Toggle schedule completion (e.g. self-study task completed)
// @route   PATCH /api/schedules/:id/toggle
// @access  Private
// ----------------------------------------------------
exports.toggleScheduleCompletion = async (req, res) => {
    try {
        const schedule = await Schedule.findById(req.params.id);

        if (!schedule) {
            return res.status(404).json({
                success: false,
                message: 'Schedule item not found'
            });
        }

        // Toggle completion status
        schedule.isCompleted = !schedule.isCompleted;
        await schedule.save();

        res.status(200).json({
            success: true,
            message: schedule.isCompleted ? 'Task marked as completed! ✅' : 'Task marked as pending ⏳',
            schedule: {
                id: schedule._id,
                isCompleted: schedule.isCompleted
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error updating task',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Delete schedule item
// @route   DELETE /api/schedules/:id
// @access  Private
// ----------------------------------------------------
exports.deleteSchedule = async (req, res) => {
    try {
        const schedule = await Schedule.findById(req.params.id);

        if (!schedule) {
            return res.status(404).json({
                success: false,
                message: 'Schedule item not found'
            });
        }

        // Authorization check: If self-study, only owner. If class, only teacher/admin
        if (schedule.type === 'self_study') {
            if (schedule.user && schedule.user.toString() !== req.user._id.toString()) {
                return res.status(403).json({
                    success: false,
                    message: 'Not authorized to delete this personal task'
                });
            }
        } else if (req.user.role !== 'teacher' && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Only teachers can remove official classes'
            });
        }

        await Schedule.findByIdAndDelete(req.params.id);

        res.status(200).json({
            success: true,
            message: 'Schedule item removed successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error deleting schedule',
            error: error.message
        });
    }
};
