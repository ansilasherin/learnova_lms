import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/planner_model.dart';
import '../core/constants/app_colors.dart';

class AcademicService {
  // 1. Fetch Assignments (Role-aware)
  static Future<List<AssignmentItem>> getAssignments() async {
    final response = await ApiClient.get(ApiConstants.assignments);
    if (response.success && response.data != null && response.data['assignments'] is List) {
      final List raw = response.data['assignments'];
      return raw.map((a) => AssignmentItem.fromJson(Map<String, dynamic>.from(a))).toList();
    }
    return [];
  }

  // 2. Submit Assignment (Student)
  static Future<Map<String, dynamic>> submitAssignment({
    required String assignmentId,
    String? fileName,
    String? fileUrl,
    String? submissionText,
  }) async {
    final response = await ApiClient.put(
      ApiConstants.submitAssignment(assignmentId),
      body: {
        'fileName': fileName ?? '',
        'fileUrl': fileUrl ?? '',
        'submissionText': submissionText ?? '',
      },
    );
    return {
      'success': response.success,
      'message': response.message ?? 'Assignment submitted successfully',
    };
  }

  // 2b. Grade Student Submission (Teacher)
  static Future<Map<String, dynamic>> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required double score,
    required String feedback,
  }) async {
    final response = await ApiClient.put(
      ApiConstants.gradeAssignmentSubmission(assignmentId, submissionId),
      body: {
        'score': score,
        'feedback': feedback,
      },
    );
    return {
      'success': response.success,
      'message': response.message ?? 'Submission graded successfully! 🌟',
    };
  }

  // 2c. Create Assignment (Teacher)
  static Future<Map<String, dynamic>> createAssignment({
    required String title,
    required String subject,
    required String dueDate,
    String priority = 'Medium Priority',
    double maxScore = 100.0,
    String description = '',
  }) async {
    final response = await ApiClient.post(
      ApiConstants.assignments,
      body: {
        'title': title,
        'subject': subject,
        'dueDate': dueDate,
        'priority': priority,
        'maxScore': maxScore,
        'description': description,
      },
    );
    return {
      'success': response.success,
      'message': response.message ?? 'Assignment created successfully! 📝',
    };
  }

  // 2d. Delete Assignment (Teacher)
  static Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
    final response = await ApiClient.delete(ApiConstants.assignmentById(assignmentId));
    return {
      'success': response.success,
      'message': response.message ?? 'Assignment removed',
    };
  }

  // 3. Fetch Real Attendance Summary & History
  static Future<Map<String, dynamic>> getAttendance({String? month, String? subject}) async {
    final queryParams = <String, String>{};
    if (month != null && month.isNotEmpty && month != 'All Months') queryParams['month'] = month;
    if (subject != null && subject.isNotEmpty && subject != 'All Subjects') queryParams['subject'] = subject;

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await ApiClient.get('${ApiConstants.attendance}$queryString');
    if (response.success && response.data != null) {
      return {
        'success': true,
        'attendanceRate': (response.data['attendanceRate'] is num)
            ? (response.data['attendanceRate'] as num).toDouble()
            : 0.0,
        'presentDays': response.data['presentDays'] ?? 0,
        'absentDays': response.data['absentDays'] ?? 0,
        'totalClasses': response.data['totalClasses'] ?? 0,
        'records': response.data['records'] ?? [],
      };
    }
    return {'success': false, 'attendanceRate': 0.0, 'presentDays': 0, 'absentDays': 0, 'totalClasses': 0, 'records': []};
  }

  // 4. Fetch Recorded Dates
  static Future<List<Map<String, dynamic>>> getRecordedDates({String? subject}) async {
    final queryParams = <String, String>{};
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await ApiClient.get('${ApiConstants.attendanceRecordedDates}$queryString');
    if (response.success && response.data != null && response.data['dates'] is List) {
      return List<Map<String, dynamic>>.from(response.data['dates']);
    }
    return [];
  }

  // 5. Fetch Class Attendance Sheet (Students + status for date & subject)
  static Future<Map<String, dynamic>> getClassAttendanceSheet({
    required String subject,
    required String date,
  }) async {
    final queryParams = {'subject': subject, 'date': date};
    final queryString = '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final response = await ApiClient.get('${ApiConstants.attendanceSheet}$queryString');
    if (response.success && response.data != null) {
      return {
        'success': true,
        'isRecorded': response.data['isRecorded'] == true,
        'sheet': response.data['sheet'] is List ? List<Map<String, dynamic>>.from(response.data['sheet']) : <Map<String, dynamic>>[],
      };
    }
    return {'success': false, 'isRecorded': false, 'sheet': <Map<String, dynamic>>[]};
  }

  // 5. Save/Submit Class Attendance Sheet
  static Future<Map<String, dynamic>> saveClassAttendanceSheet({
    required String subject,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.attendanceSheet,
      body: {
        'subject': subject,
        'date': date,
        'records': records,
      },
    );
    return {
      'success': response.success,
      'message': response.message ?? 'Class Attendance Sheet saved! ✅',
      'presentCount': response.data != null ? response.data['presentCount'] : null,
      'absentCount': response.data != null ? response.data['absentCount'] : null,
    };
  }

  // 6. Fetch Student Roster
  static Future<List<Map<String, dynamic>>> getRoster() async {
    final response = await ApiClient.get(ApiConstants.attendanceRoster);
    if (response.success && response.data != null && response.data['students'] is List) {
      return List<Map<String, dynamic>>.from(response.data['students']);
    }
    return [];
  }

  // 7. Add New Student to Register
  static Future<Map<String, dynamic>> addStudentToRoster({
    required String name,
    String? rollNo,
    String? email,
    String? batch,
    String? gender,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.attendanceRoster,
      body: {
        'name': name,
        'rollNo': rollNo,
        'email': email,
        'batch': batch ?? 'Batch A',
        'gender': gender ?? 'Male',
      },
    );
    return {
      'success': response.success,
      'message': response.message ?? 'Student added to register',
      'student': response.data != null ? response.data['student'] : null,
    };
  }

  // 8. Delete Student from Register
  static Future<Map<String, dynamic>> deleteStudentFromRoster(String studentId) async {
    final response = await ApiClient.delete(ApiConstants.attendanceRosterDelete(studentId));
    return {
      'success': response.success,
      'message': response.message ?? 'Student removed',
    };
  }

  // 4. Fetch Schedules
  static Future<List<ScheduleItem>> getSchedules() async {
    final response = await ApiClient.get(ApiConstants.schedules, auth: false);
    if (response.success && response.data != null && response.data['schedules'] is List) {
      final List raw = response.data['schedules'];
      return raw.map((s) {
        Color parseColor(String? colorStr) {
          if (colorStr == null) return AppColors.primary;
          try {
            final hex = colorStr.replaceAll('#', '');
            if (hex.length == 6) {
              return Color(int.parse('FF$hex', radix: 16));
            }
          } catch (_) {}
          return AppColors.primary;
        }

        return ScheduleItem(
          id: s['id'] ?? s['_id'] ?? '',
          title: s['title'] ?? '',
          instructor: s['instructor'] ?? '',
          time: s['time'] ?? '',
          duration: s['duration'] ?? '1 hr',
          isLive: s['isLive'] ?? false,
          color: parseColor(s['color']),
        );
      }).toList();
    }
    return [];
  }
}
