import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/enrollment_model.dart';

class EnrollmentService {
  // Get all enrolled courses for student
  static Future<List<EnrollmentModel>> getMyEnrolledCourses() async {
    final response = await ApiClient.get(ApiConstants.myCourses);
    if (response.success && response.data != null && response.data['enrollments'] is List) {
      final List raw = response.data['enrollments'];
      return raw.map((e) => EnrollmentModel.fromJson(e)).toList();
    }
    return [];
  }

  // Enroll in a course
  static Future<Map<String, dynamic>> enrollInCourse(String courseId) async {
    final response = await ApiClient.post(ApiConstants.enroll(courseId));
    if (response.success && response.data != null) {
      final enrollment = EnrollmentModel.fromJson(response.data['enrollment'] ?? {});
      return {'success': true, 'enrollment': enrollment, 'message': response.data['message']};
    }
    return {'success': false, 'message': response.message ?? 'Enrollment failed'};
  }

  // Get progress for a specific course
  static Future<EnrollmentModel?> getCourseProgress(String courseId) async {
    final response = await ApiClient.get(ApiConstants.progress(courseId));
    if (response.success && response.data != null && response.data['enrollment'] != null) {
      return EnrollmentModel.fromJson(response.data['enrollment']);
    }
    return null;
  }

  // Mark lesson as completed
  static Future<Map<String, dynamic>> completeLesson(String courseId, String lessonId) async {
    final response = await ApiClient.put(ApiConstants.completeLesson(courseId, lessonId));
    if (response.success && response.data != null) {
      return {
        'success': true,
        'message': response.data['message'],
        'progressPercentage': response.data['progressPercentage'] ?? 0,
        'isCompleted': response.data['isCompleted'] ?? false,
        'completedLessonsCount': response.data['completedLessonsCount'],
        'totalLessonsCount': response.data['totalLessonsCount'],
      };
    }
    return {'success': false, 'message': response.message ?? 'Update progress failed'};
  }
}
