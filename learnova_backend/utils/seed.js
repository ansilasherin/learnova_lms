const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('../models/User');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const Assignment = require('../models/Assignment');
const Attendance = require('../models/Attendance');
const Schedule = require('../models/Schedule');

dotenv.config();

const seedData = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/learnova_lms');
        console.log('📦 Connected to MongoDB for Seeding...');

        // Clear existing collections
        await User.deleteMany({});
        await Course.deleteMany({});
        await Enrollment.deleteMany({});
        await Assignment.deleteMany({});
        await Attendance.deleteMany({});
        await Schedule.deleteMany({});
        console.log('🧹 Cleaned existing database records.');

        // 1. Create Users
        const student = await User.create({
            name: 'Ananya Sharma',
            email: 'ananya.student@gmail.com',
            phone: '+91 9876543210',
            password: 'Password123',
            role: 'student',
            studentId: 'LN-2026-089'
        });

        const teacher = await User.create({
            name: 'Prof. Rajesh Mehta',
            email: 'prof.mehta@gmail.com',
            phone: '+91 9876500001',
            password: 'Password123',
            role: 'teacher'
        });

        const teacher2 = await User.create({
            name: 'Prof. Anita Iyer',
            email: 'prof.iyer@gmail.com',
            phone: '+91 9876500002',
            password: 'Password123',
            role: 'teacher'
        });

        const admin = await User.create({
            name: 'Learnova Administrator',
            email: 'admin@learnova.com',
            phone: '+91 9876500099',
            password: 'Password123',
            role: 'admin'
        });

        console.log('👤 Created Demo Users (Student, Teachers, Admin).');

        // 2. Create Courses with Lessons
        const course1 = await Course.create({
            title: 'Data Structures & Algorithms Masterclass',
            description: 'Master core data structures: Arrays, Linked Lists, Trees, Graphs, and dynamic programming with real-world problem solving in Dart and Java.',
            category: 'Computer Science',
            price: 2499,
            level: 'Intermediate',
            thumbnail: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
            instructor: teacher._id,
            enrolledStudents: [student._id],
            lessons: [
                {
                    title: '1. Introduction to Complexity Analysis (Big O)',
                    description: 'Learn time and space complexity with practical algorithm examples.',
                    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                    duration: '15 mins',
                    isFreePreview: true
                },
                {
                    title: '2. Dynamic Arrays and Memory Allocation',
                    description: 'Understand how arrays manage memory dynamically in modern runtimes.',
                    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                    duration: '22 mins',
                    isFreePreview: false
                },
                {
                    title: '3. Singly & Doubly Linked Lists',
                    description: 'Pointer manipulation and step-by-step linked list implementations.',
                    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                    duration: '28 mins',
                    isFreePreview: false
                },
                {
                    title: '4. Binary Search Trees & AVL Trees',
                    description: 'Tree rotations, balanced search trees and self-balancing BSTs.',
                    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
                    duration: '35 mins',
                    isFreePreview: false
                }
            ]
        });

        const course2 = await Course.create({
            title: 'Modern Database Systems: SQL & NoSQL',
            description: 'Deep dive into relational database normalization, ACID transactions, indexing strategies, and MongoDB document modeling.',
            category: 'Databases',
            price: 1999,
            level: 'Beginner',
            thumbnail: 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d?w=600',
            instructor: teacher2._id,
            enrolledStudents: [student._id],
            lessons: [
                {
                    title: '1. Relational Database Concepts & Schema Design',
                    description: 'Entities, attributes, and primary/foreign keys.',
                    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                    duration: '18 mins',
                    isFreePreview: true
                },
                {
                    title: '2. Normalization (1NF, 2NF, 3NF, BCNF)',
                    description: 'Eliminating redundancy and anomaly through normal forms.',
                    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                    duration: '25 mins',
                    isFreePreview: false
                }
            ]
        });

        const course3 = await Course.create({
            title: 'Operating Systems & System Design',
            description: 'Explore process synchronization, deadlock handling, virtual memory management, and paging mechanisms.',
            category: 'System Architecture',
            price: 2999,
            level: 'Advanced',
            thumbnail: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600',
            instructor: teacher._id,
            enrolledStudents: [student._id],
            lessons: [
                {
                    title: '1. Process Lifecycle & Context Switching',
                    description: 'How the OS schedules processes and executes CPU bursts.',
                    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                    duration: '20 mins',
                    isFreePreview: true
                }
            ]
        });

        console.log('📚 Created Demo Courses & Lessons.');

        // 3. Create Enrollments with progress
        const firstLessonId = course1.lessons[0]._id;
        const secondLessonId = course1.lessons[1]._id;

        await Enrollment.create({
            student: student._id,
            course: course1._id,
            completedLessons: [firstLessonId, secondLessonId],
            progressPercentage: 50,
            isCompleted: false
        });

        await Enrollment.create({
            student: student._id,
            course: course2._id,
            completedLessons: [course2.lessons[0]._id],
            progressPercentage: 50,
            isCompleted: false
        });

        console.log('🎓 Created Student Enrollments.');

        // 4. Create Assignments
        await Assignment.create([
            {
                title: 'DSA Module 3: Linked Lists Implementation',
                subject: 'Data Structures',
                description: 'Implement a doubly linked list with O(1) insertion at head and tail.',
                dueDate: 'Due: 18 Oct 2026',
                priority: 'High Priority',
                progress: 62,
                createdBy: teacher._id,
                submissions: []
            },
            {
                title: 'Database Normalization Case Study',
                subject: 'Database Systems',
                description: 'Decompose the given unnormalized table into 3NF.',
                dueDate: 'Due: 20 Oct 2026',
                priority: 'Medium Priority',
                progress: 40,
                createdBy: teacher2._id,
                submissions: []
            },
            {
                title: 'OS Process Scheduling Case Study',
                subject: 'Operating Systems',
                description: 'Compare Round Robin vs Multi-level Feedback Queue performance.',
                dueDate: 'Due: 22 Oct 2026',
                priority: 'High Priority',
                progress: 80,
                createdBy: teacher._id,
                submissions: [
                    {
                        student: student._id,
                        status: 'submitted',
                        score: 9.5
                    }
                ]
            },
            {
                title: 'Computer Networks Packet Sniffing Report',
                subject: 'Computer Networks',
                description: 'Analyze Wireshark PCAP files for TCP three-way handshake.',
                dueDate: 'Due: 25 Oct 2026',
                priority: 'Low Priority',
                progress: 30,
                createdBy: teacher2._id,
                submissions: []
            }
        ]);

        console.log('📝 Created Assignments.');

        // 5. Create Attendance Records
        await Attendance.create([
            { student: student._id, subject: 'Data Structures', date: '14 Oct 2026', isPresent: true },
            { student: student._id, subject: 'Database Systems', date: '14 Oct 2026', isPresent: true },
            { student: student._id, subject: 'Operating Systems', date: '13 Oct 2026', isPresent: false },
            { student: student._id, subject: 'Computer Networks', date: '12 Oct 2026', isPresent: true },
            { student: student._id, subject: 'Data Structures', date: '11 Oct 2026', isPresent: true }
        ]);

        console.log('📊 Created Attendance Records.');

        // 6. Create Timetable Schedules
        await Schedule.create([
            {
                title: 'Data Structures',
                instructor: 'Prof. Rajesh Mehta',
                time: '09:00 AM - 10:30 AM',
                duration: '1.5 hrs',
                isLive: true,
                color: '#4F46E5',
                dayOfWeek: 'Today'
            },
            {
                title: 'Database Systems',
                instructor: 'Prof. Anita Iyer',
                time: '11:30 AM - 12:30 PM',
                duration: '1 hr',
                isLive: true,
                color: '#10B981',
                dayOfWeek: 'Today'
            },
            {
                title: 'Lunch Break',
                instructor: 'Campus Cafeteria',
                time: '12:30 PM - 01:30 PM',
                duration: '1 hr',
                isLive: false,
                color: '#F59E0B',
                dayOfWeek: 'Today'
            },
            {
                title: 'Operating Systems',
                instructor: 'Prof. Verma',
                time: '02:00 PM - 03:00 PM',
                duration: '1 hr',
                isLive: true,
                color: '#EF4444',
                dayOfWeek: 'Today'
            },
            {
                title: 'Computer Networks',
                instructor: 'Prof. Rao',
                time: '04:00 PM - 05:00 PM',
                duration: '1 hr',
                isLive: false,
                color: '#8B5CF6',
                dayOfWeek: 'Today'
            }
        ]);

        console.log('📅 Created Timetable Schedules.');
        console.log('✨ Seeding completed successfully! 🚀');

        process.exit(0);
    } catch (err) {
        console.error('❌ Seeding Error:', err);
        process.exit(1);
    }
};

seedData();
