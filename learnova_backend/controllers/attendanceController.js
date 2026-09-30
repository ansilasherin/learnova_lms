const Attendance = require('../models/Attendance');
const Student = require('../models/Student');

// Default initial class roster to pre-populate for CS department if database is clean
const DEFAULT_STUDENTS = [
    { rollNo: '01', name: 'Aaditya Menon', batch: 'Batch A', email: 'aaditya.menon@gmail.com', department: 'Computer Science & Engineering', gender: 'Male' },
    { rollNo: '02', name: 'Ananya Sharma', batch: 'Batch A', email: 'ananya.sharma@gmail.com', department: 'Computer Science & Engineering', gender: 'Female' },
    { rollNo: '03', name: 'Arjun Das', batch: 'Batch A', email: 'arjun.das@gmail.com', department: 'Computer Science & Engineering', gender: 'Male' },
    { rollNo: '04', name: 'Devika Nair', batch: 'Batch A', email: 'devika.nair@gmail.com', department: 'Computer Science & Engineering', gender: 'Female' },
    { rollNo: '05', name: 'Fahad Mohammed', batch: 'Batch A', email: 'fahad.m@gmail.com', department: 'Computer Science & Engineering', gender: 'Male' },
    { rollNo: '06', name: 'Gautham Varma', batch: 'Batch A', email: 'gautham.v@gmail.com', department: 'Computer Science & Engineering', gender: 'Male' },
    { rollNo: '07', name: 'Meera Nambiar', batch: 'Batch A', email: 'meera.n@gmail.com', department: 'Computer Science & Engineering', gender: 'Female' },
    { rollNo: '08', name: 'Naveen Kumar', batch: 'Batch A', email: 'naveen.k@gmail.com', department: 'Computer Science & Engineering', gender: 'Male' },
    { rollNo: '09', name: 'Pooja Hegde', batch: 'Batch A', email: 'pooja.h@gmail.com', department: 'Computer Science & Engineering', gender: 'Female' },
    { rollNo: '10', name: 'Rahul Krishna', batch: 'Batch A', email: 'rahul.k@gmail.com', department: 'Computer Science & Engineering', gender: 'Male' },
    { rollNo: '11', name: 'Rohan Joshi', batch: 'Batch A', email: 'rohan.j@gmail.com', department: 'Computer Science & Engineering', gender: 'Male' },
    { rollNo: '12', name: 'Sneha Pillai', batch: 'Batch A', email: 'sneha.pillai@gmail.com', department: 'Computer Science & Engineering', gender: 'Female' },
];

// Helper to seed students if none exist for CS department
async function ensureStudentsExist(dept) {
    if (dept === 'Computer Science & Engineering') {
        const count = await Student.countDocuments({ department: 'Computer Science & Engineering' });
        if (count === 0) {
            await Student.insertMany(DEFAULT_STUDENTS);
            console.log('📋 Auto-seeded 12 initial students into CS Class Roster');
        }
    }
}

// ----------------------------------------------------
// @desc    Get all students in class roster (Department-aware)
// @route   GET /api/attendance/roster
// @access  Private
// ----------------------------------------------------
exports.getRoster = async (req, res) => {
    try {
        const userDept = req.user?.department || 'Computer Science & Engineering';
        await ensureStudentsExist(userDept);

        const filter = {
            department: userDept
        };

        const students = await Student.find(filter).sort({ rollNo: 1, name: 1 });

        res.status(200).json({
            success: true,
            count: students.length,
            department: userDept,
            students: students.map((s) => ({
                id: s._id,
                rollNo: s.rollNo,
                name: s.name,
                email: s.email,
                department: s.department || userDept,
                batch: s.batch,
                gender: s.gender,
                createdAt: s.createdAt
            }))
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching students roster',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Add new student to class roster
// @route   POST /api/attendance/roster
// @access  Private (Teacher, Admin)
// ----------------------------------------------------
exports.addStudent = async (req, res) => {
    try {
        const { name, rollNo, email, department, batch, gender } = req.body;

        if (!name || name.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'Student name is required'
            });
        }

        const userDept = department || req.user?.department || 'Computer Science & Engineering';

        // Auto generate roll number if not provided
        let finalRollNo = rollNo ? rollNo.trim() : '';
        if (!finalRollNo) {
            const count = await Student.countDocuments({ department: userDept });
            finalRollNo = String(count + 1).padStart(2, '0');
        }

        const newStudent = await Student.create({
            name: name.trim(),
            rollNo: finalRollNo,
            email: email ? email.trim() : '',
            department: userDept,
            batch: batch ? batch.trim() : 'Batch A',
            gender: gender || 'Male',
            addedBy: req.user ? req.user._id : null
        });

        res.status(201).json({
            success: true,
            message: `${newStudent.name} added to class register! ✅`,
            student: {
                id: newStudent._id,
                rollNo: newStudent.rollNo,
                name: newStudent.name,
                email: newStudent.email,
                department: newStudent.department,
                batch: newStudent.batch,
                gender: newStudent.gender
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error adding student to register',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Delete student from class roster
// @route   DELETE /api/attendance/roster/:id
// @access  Private (Teacher, Admin)
// ----------------------------------------------------
exports.deleteStudent = async (req, res) => {
    try {
        const student = await Student.findById(req.params.id);

        if (!student) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        await Student.findByIdAndDelete(req.params.id);

        res.status(200).json({
            success: true,
            message: `${student.name} removed from roster`
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error deleting student',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Get complete attendance sheet for given date & subject (Department-aware)
// @route   GET /api/attendance/sheet
// @access  Private
// ----------------------------------------------------
exports.getClassAttendanceSheet = async (req, res) => {
    try {
        const userDept = req.user?.department || 'Computer Science & Engineering';
        await ensureStudentsExist(userDept);
        const { date, subject } = req.query;

        const filter = {
            department: userDept
        };

        const students = await Student.find(filter).sort({ rollNo: 1, name: 1 });

        // Map existing attendance records for the date and subject
        let existingMap = {};
        let isRecorded = false;

        if (date && subject) {
            const records = await Attendance.find({
                date: date.trim(),
                subject: subject.trim()
            });

            if (records.length > 0) {
                isRecorded = true;
                records.forEach((r) => {
                    if (r.student) {
                        existingMap[r.student.toString()] = r.isPresent;
                    }
                    existingMap[r.studentName.toLowerCase()] = r.isPresent;
                });
            }
        }

        const sheet = students.map((s) => {
            const hasRecordById = existingMap[s._id.toString()];
            const hasRecordByName = existingMap[s.name.toLowerCase()];

            let status = 'unmarked';
            if (isRecorded) {
                if (hasRecordById !== undefined) {
                    status = hasRecordById ? 'present' : 'absent';
                } else if (hasRecordByName !== undefined) {
                    status = hasRecordByName ? 'present' : 'absent';
                } else {
                    status = 'absent';
                }
            }

            return {
                id: s._id,
                rollNo: s.rollNo,
                name: s.name,
                email: s.email,
                department: s.department || userDept,
                batch: s.batch,
                status: status, // 'present', 'absent', or 'unmarked'
                isPresent: status === 'present'
            };
        });

        res.status(200).json({
            success: true,
            isRecorded,
            date: date || '',
            subject: subject || '',
            department: userDept,
            count: sheet.length,
            sheet
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error loading attendance sheet',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Save/Submit complete class attendance sheet for a date
// @route   POST /api/attendance/sheet
// @access  Private (Teacher, Admin)
// ----------------------------------------------------
exports.saveClassAttendanceSheet = async (req, res) => {
    try {
        const { date, subject, department, records } = req.body;

        if (!date || !subject || !Array.isArray(records)) {
            return res.status(400).json({
                success: false,
                message: 'date, subject, and records array are required'
            });
        }

        const userDept = department || req.user?.department || 'Computer Science & Engineering';

        // Delete existing records for this subject and date to prevent duplicates
        await Attendance.deleteMany({
            date: date.trim(),
            subject: subject.trim()
        });

        // Insert new attendance entries
        const attendanceDocs = records.map((r) => ({
            student: r.studentId || r.id,
            studentName: r.name || r.studentName || 'Student',
            subject: subject.trim(),
            department: userDept,
            date: date.trim(),
            isPresent: r.isPresent === true || r.status === 'present',
            remarks: r.remarks || '',
            recordedBy: req.user ? req.user._id : null
        }));

        if (attendanceDocs.length > 0) {
            await Attendance.insertMany(attendanceDocs);
        }

        res.status(200).json({
            success: true,
            message: `Attendance for ${subject} (${date}) saved successfully! 📊`,
            count: attendanceDocs.length
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error saving attendance sheet',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Get all distinct dates for which attendance was recorded
// @route   GET /api/attendance/recorded-dates
// @access  Private
// ----------------------------------------------------
exports.getRecordedDates = async (req, res) => {
    try {
        const { subject } = req.query;
        const query = {};
        if (subject && subject.trim() !== '') {
            query.subject = subject.trim();
        }

        const dates = await Attendance.distinct('date', query);

        res.status(200).json({
            success: true,
            count: dates.length,
            dates
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching recorded dates',
            error: error.message
        });
    }
};

// ----------------------------------------------------
// @desc    Get 100% REAL attendance summary for student
// @route   GET /api/attendance
// @access  Private
// ----------------------------------------------------
exports.getAttendance = async (req, res) => {
    try {
        const { month, subject } = req.query;
        const studentName = req.user ? req.user.name : '';

        // Query real records matching this student
        const query = {
            $or: [
                { student: req.user ? req.user._id : null },
                { studentName: { $regex: new RegExp(`^${studentName}$`, 'i') } }
            ]
        };

        if (subject && subject.trim() !== '' && subject !== 'All Subjects') {
            query.subject = subject.trim();
        }

        let records = await Attendance.find(query).sort({ createdAt: -1 });

        // Month filter if provided (e.g. "Sep 2026" or "October 2026")
        if (month && month.trim() !== '' && month !== 'All Months') {
            records = records.filter((r) => {
                return (r.date || '').toLowerCase().includes(month.trim().toLowerCase());
            });
        }

        const totalClasses = records.length;
        const presentDays = records.filter((r) => r.isPresent).length;
        const absentDays = totalClasses - presentDays;
        const attendanceRate = totalClasses > 0 ? (presentDays / totalClasses) : 0.0;

        res.status(200).json({
            success: true,
            totalClasses,
            presentDays,
            absentDays,
            attendanceRate: Number(attendanceRate.toFixed(2)),
            records: records.map((r) => ({
                id: r._id,
                subject: r.subject,
                date: r.date,
                isPresent: r.isPresent,
                remarks: r.remarks || ''
            }))
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching attendance summary',
            error: error.message
        });
    }
};
