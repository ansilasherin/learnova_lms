import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/planner_model.dart';
import '../services/academic_service.dart';

class PlannerProvider with ChangeNotifier {
  // Current Streak
  final int _streakDays = 12;
  int get streakDays => _streakDays;

  // Attendance metrics
  double _attendanceRate = 0.0;
  int _presentDays = 0;
  int _absentDays = 0;
  int _totalClasses = 0;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = false;

  double get attendanceRate => _attendanceRate;
  int get presentDays => _presentDays;
  int get absentDays => _absentDays;
  int get totalClasses => _totalClasses;
  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;

  // GPA
  final double _gpa = 8.6;
  double get gpa => _gpa;

  // Selected date for study planner
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Today's schedule items (Teacher Classes + Student Self-Study Tasks)
  List<ScheduleItem> _schedules = [
    ScheduleItem(
      id: '1',
      title: 'Data Structures & Algorithms',
      instructor: 'Prof. Mehta',
      time: '09:00 AM - 10:30 AM',
      duration: '1.5 hrs',
      isLive: true,
      color: AppColors.primary,
      type: 'class',
      location: 'Lecture Hall 201',
    ),
    ScheduleItem(
      id: '2',
      title: 'Trees & Graphs Practice',
      instructor: 'Self Study',
      time: '10:30 AM - 11:30 AM',
      duration: '1 hr',
      isLive: false,
      color: AppColors.emerald,
      type: 'self_study',
      location: 'Library / Desk',
      notes: 'Solve 3 LeetCode problems on Binary Search Trees',
    ),
    ScheduleItem(
      id: '3',
      title: 'Database Systems (DBMS)',
      instructor: 'Prof. Iyer',
      time: '11:30 AM - 12:30 PM',
      duration: '1 hr',
      isLive: true,
      color: AppColors.emerald,
      type: 'class',
      location: 'CS Hall 302',
    ),
    ScheduleItem(
      id: '4',
      title: 'Operating Systems (Lab)',
      instructor: 'Prof. Verma',
      time: '02:00 PM - 03:30 PM',
      duration: '1.5 hrs',
      isLive: true,
      color: AppColors.coral,
      type: 'class',
      location: 'Main Lab A',
    ),
    ScheduleItem(
      id: '5',
      title: 'Computer Networks Lecture',
      instructor: 'Prof. Rao',
      time: '04:00 PM - 05:00 PM',
      duration: '1 hr',
      isLive: false,
      color: AppColors.purple,
      type: 'class',
      location: 'Lecture Hall 105',
    ),
    ScheduleItem(
      id: '6',
      title: 'DBMS Assignment Preparation',
      instructor: 'Self Study',
      time: '06:00 PM - 07:30 PM',
      duration: '1.5 hrs',
      isLive: false,
      color: AppColors.amber,
      type: 'self_study',
      location: 'Hostel Room',
      notes: 'Complete SQL Normalization schema diagrams',
    ),
  ];

  List<ScheduleItem> get schedules => _schedules;
  List<ScheduleItem> get teacherClasses => _schedules.where((s) => s.type == 'class').toList();
  List<ScheduleItem> get selfStudyTasks => _schedules.where((s) => s.type == 'self_study').toList();

  // Add a new schedule/study task
  void addSchedule(ScheduleItem item) {
    _schedules.insert(0, item);
    notifyListeners();
  }

  // Toggle completion of study task / schedule
  void toggleScheduleCompletion(String id) {
    final idx = _schedules.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final current = _schedules[idx];
      _schedules[idx] = current.copyWith(isCompleted: !current.isCompleted);
      notifyListeners();
    }
  }

  // Remove a schedule/study task
  void removeSchedule(String id) {
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // Add assignment
  void addAssignment(AssignmentItem item) {
    _assignments.insert(0, item);
    notifyListeners();
  }

  // Assignments List
  List<AssignmentItem> _assignments = [
    AssignmentItem(
      id: '1',
      title: 'DSA Module 3',
      subject: 'Data Structures',
      dueDate: 'Due: 18 Oct 2026',
      priority: 'High Priority',
      progress: 62,
      status: 'pending',
    ),
    AssignmentItem(
      id: '2',
      title: 'Database Normalization',
      subject: 'Database Systems',
      dueDate: 'Due: 20 Oct 2026',
      priority: 'Medium Priority',
      progress: 40,
      status: 'pending',
    ),
    AssignmentItem(
      id: '3',
      title: 'OS Case Study',
      subject: 'Operating Systems',
      dueDate: 'Due: 22 Oct 2026',
      priority: 'High Priority',
      progress: 80,
      status: 'submitted',
      score: 9.5,
    ),
    AssignmentItem(
      id: '4',
      title: 'CN Lab Report',
      subject: 'Computer Networks',
      dueDate: 'Due: 25 Oct 2026',
      priority: 'Low Priority',
      progress: 30,
      status: 'pending',
    ),
  ];

  List<AssignmentItem> get assignments => _assignments;

  // Fetch Live Academic Data from Backend
  Future<void> fetchAcademicData({String? month, String? subject}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Assignments
      final liveAssignments = await AcademicService.getAssignments();
      if (liveAssignments.isNotEmpty) {
        _assignments = liveAssignments;
      }

      // 2. Fetch Attendance
      final attRes = await AcademicService.getAttendance(month: month, subject: subject);
      if (attRes['success'] == true) {
        _attendanceRate = attRes['attendanceRate'] ?? 0.0;
        _presentDays = attRes['presentDays'] ?? 0;
        _absentDays = attRes['absentDays'] ?? 0;
        _totalClasses = attRes['totalClasses'] ?? 0;
        if (attRes['records'] is List) {
          _attendanceRecords = List<Map<String, dynamic>>.from(attRes['records']);
        }
      }

      // 3. Fetch Schedules
      final liveSchedules = await AcademicService.getSchedules();
      if (liveSchedules.isNotEmpty) {
        _schedules = liveSchedules;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  // Submit Assignment (Student)
  Future<bool> submitAssignment({
    required String assignmentId,
    String? fileName,
    String? fileUrl,
    String? submissionText,
  }) async {
    final res = await AcademicService.submitAssignment(
      assignmentId: assignmentId,
      fileName: fileName,
      fileUrl: fileUrl,
      submissionText: submissionText,
    );
    if (res['success'] == true) {
      await fetchAcademicData();
      return true;
    }
    return false;
  }

  // Grade Student Submission (Teacher)
  Future<bool> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double score,
    required String feedback,
  }) async {
    final res = await AcademicService.gradeSubmission(
      assignmentId: assignmentId,
      submissionId: submissionId,
      score: score,
      feedback: feedback,
    );
    if (res['success'] == true) {
      await fetchAcademicData();
      return true;
    }
    return false;
  }

  // Create Assignment (Teacher)
  Future<bool> createAssignment({
    required String title,
    required String subject,
    required String dueDate,
    String priority = 'Medium Priority',
    double maxScore = 100.0,
    String description = '',
  }) async {
    final res = await AcademicService.createAssignment(
      title: title,
      subject: subject,
      dueDate: dueDate,
      priority: priority,
      maxScore: maxScore,
      description: description,
    );
    if (res['success'] == true) {
      await fetchAcademicData();
      return true;
    }
    return false;
  }

  // Delete Assignment (Teacher)
  Future<bool> deleteAssignment(String assignmentId) async {
    final res = await AcademicService.deleteAssignment(assignmentId);
    if (res['success'] == true) {
      await fetchAcademicData();
      return true;
    }
    return false;
  }

  // Grades Breakdown
  final List<GradeItem> _grades = [
    GradeItem(subject: 'Data Structures', grade: 'A', score: 9.2),
    GradeItem(subject: 'Database Systems', grade: 'A+', score: 8.7),
    GradeItem(subject: 'Operating Systems', grade: 'A', score: 8.8),
    GradeItem(subject: 'Computer Networks', grade: 'B', score: 7.6),
  ];

  List<GradeItem> get grades => _grades;

  // Badges & Achievements
  final List<BadgeItem> _badges = [
    BadgeItem(
      id: '1',
      title: 'Study Streak',
      description: '10 Days in a row',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.amber,
    ),
    BadgeItem(
      id: '2',
      title: 'Early Bird',
      description: 'Attend 10 classes before 9 AM',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.emerald,
    ),
    BadgeItem(
      id: '3',
      title: 'Assignment Pro',
      description: 'Submit 5 assignments early',
      icon: Icons.assignment_turned_in_rounded,
      color: AppColors.primary,
    ),
    BadgeItem(
      id: '4',
      title: 'Perfect Attendance',
      description: 'Attend 20 classes',
      icon: Icons.verified_user_rounded,
      color: AppColors.cyan,
    ),
  ];

  List<BadgeItem> get badges => _badges;
}
