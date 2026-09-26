import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configurable base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  // Auth Endpoints
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';

  // User Endpoints
  static String get userProfile => '$baseUrl/users/profile';

  // Course Endpoints
  static String get courses => '$baseUrl/courses';
  static String get uploadVideo => '$baseUrl/courses/upload-video';
  static String get uploadDocument => '$baseUrl/courses/upload-document';
  static String courseById(String id) => '$baseUrl/courses/$id';
  static String addLesson(String courseId) => '$baseUrl/courses/$courseId/lessons';
  static String deleteLesson(String courseId, String lessonId) => '$baseUrl/courses/$courseId/lessons/$lessonId';
  static String addMaterial(String courseId) => '$baseUrl/courses/$courseId/materials';
  static String deleteMaterial(String courseId, String materialId) => '$baseUrl/courses/$courseId/materials/$materialId';

  // Enrollment Endpoints
  static String get myCourses => '$baseUrl/enrollments/my-courses';
  static String enroll(String courseId) => '$baseUrl/enrollments/$courseId';
  static String progress(String courseId) => '$baseUrl/enrollments/$courseId/progress';
  static String completeLesson(String courseId, String lessonId) =>
      '$baseUrl/enrollments/$courseId/lessons/$lessonId/complete';

  // Academic & Attendance Endpoints
  static String get assignments => '$baseUrl/assignments';
  static String assignmentById(String id) => '$baseUrl/assignments/$id';
  static String submitAssignment(String id) => '$baseUrl/assignments/$id/submit';
  static String gradeAssignmentSubmission(String assignmentId, String submissionId) =>
      '$baseUrl/assignments/$assignmentId/submissions/$submissionId/grade';
  static String get attendance => '$baseUrl/attendance';
  static String get attendanceStudents => '$baseUrl/attendance/students';
  static String get attendanceRoster => '$baseUrl/attendance/roster';
  static String attendanceRosterDelete(String id) => '$baseUrl/attendance/roster/$id';
  static String get attendanceSheet => '$baseUrl/attendance/sheet';
  static String get attendanceRecordedDates => '$baseUrl/attendance/recorded-dates';
  static String get schedules => '$baseUrl/schedules';
}
