import 'package:flutter/material.dart';
import '../models/enrollment_model.dart';
import '../services/enrollment_service.dart';

class EnrollmentProvider with ChangeNotifier {
  List<EnrollmentModel> _enrollments = [];
  EnrollmentModel? _activeEnrollment;
  bool _isLoading = false;
  String? _errorMessage;

  List<EnrollmentModel> get enrollments => _enrollments;
  EnrollmentModel? get activeEnrollment => _activeEnrollment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Total enrolled count
  int get enrolledCount => _enrollments.length;

  // Average progress percentage across all courses
  int get overallProgressPercentage {
    if (_enrollments.isEmpty) return 0;
    int total = _enrollments.fold(0, (sum, item) => sum + item.progressPercentage);
    return (total / _enrollments.length).round();
  }

  // Check if enrolled in a specific course
  bool isEnrolledInCourse(String courseId) {
    return _enrollments.any((e) => e.courseId == courseId || e.course?.id == courseId);
  }

  // Get enrollment for a course
  EnrollmentModel? getEnrollmentForCourse(String courseId) {
    try {
      return _enrollments.firstWhere(
        (e) => e.courseId == courseId || e.course?.id == courseId,
      );
    } catch (_) {
      return null;
    }
  }

  // Fetch enrolled courses
  Future<void> fetchMyEnrollments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _enrollments = await EnrollmentService.getMyEnrolledCourses();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enroll in Course
  Future<bool> enrollInCourse(String courseId) async {
    _isLoading = true;
    notifyListeners();

    final res = await EnrollmentService.enrollInCourse(courseId);
    _isLoading = false;

    if (res['success'] == true) {
      await fetchMyEnrollments();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }

  // Fetch Course Progress
  Future<EnrollmentModel?> fetchCourseProgress(String courseId) async {
    try {
      _activeEnrollment = await EnrollmentService.getCourseProgress(courseId);
      notifyListeners();
      return _activeEnrollment;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // Mark Lesson Completed
  Future<Map<String, dynamic>> completeLesson(String courseId, String lessonId) async {
    _isLoading = true;
    notifyListeners();

    final res = await EnrollmentService.completeLesson(courseId, lessonId);
    _isLoading = false;

    if (res['success'] == true) {
      await fetchMyEnrollments();
      await fetchCourseProgress(courseId);
    } else {
      _errorMessage = res['message'];
      notifyListeners();
    }
    return res;
  }
}
