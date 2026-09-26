import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/course_model.dart';

class CourseService {
  // Get all courses
  static Future<List<CourseModel>> getAllCourses() async {
    final response = await ApiClient.get(ApiConstants.courses, auth: false);
    if (response.success && response.data != null && response.data['courses'] is List) {
      final List raw = response.data['courses'];
      return raw.map((c) => CourseModel.fromJson(c)).toList();
    }
    return [];
  }

  // Get single course by ID
  static Future<CourseModel?> getCourseById(String courseId) async {
    final response = await ApiClient.get(ApiConstants.courseById(courseId), auth: false);
    if (response.success && response.data != null && response.data['course'] != null) {
      return CourseModel.fromJson(response.data['course']);
    }
    return null;
  }

  // Upload Video File to Backend Storage (Teacher/Admin)
  static Future<Map<String, dynamic>> uploadVideoFile(PlatformFile file) async {
    try {
      final token = await ApiClient.getToken();
      final uri = Uri.parse(ApiConstants.uploadVideo);
      final request = http.MultipartRequest('POST', uri);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'video',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'video',
            file.path!,
            filename: file.name,
          ),
        );
      } else {
        return {'success': false, 'message': 'Could not read video file data.'};
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'videoUrl': decoded['videoUrl'],
          'filename': decoded['filename'],
          'size': decoded['size'],
          'message': decoded['message'] ?? 'Video uploaded successfully! 🎬',
        };
      } else {
        return {
          'success': false,
          'message': decoded is Map ? decoded['message'] ?? 'Video upload failed' : 'Upload failed (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Upload error: ${e.toString()}'};
    }
  }

  // Create Course (Teacher/Admin)
  static Future<Map<String, dynamic>> createCourse({
    required String title,
    required String description,
    required String category,
    required double price,
    required String level,
    String? thumbnail,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.courses,
      body: {
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'level': level,
        if (thumbnail != null) 'thumbnail': thumbnail,
      },
    );

    if (response.success && response.data != null) {
      final course = CourseModel.fromJson(response.data['course'] ?? {});
      return {'success': true, 'course': course};
    }
    return {'success': false, 'message': response.message ?? 'Course creation failed'};
  }

  // Add Lesson (Teacher/Admin)
  static Future<Map<String, dynamic>> addLesson({
    required String courseId,
    required String title,
    required String videoUrl,
    required String duration,
    String? description,
    bool isFreePreview = false,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.addLesson(courseId),
      body: {
        'title': title,
        'videoUrl': videoUrl,
        'duration': duration,
        if (description != null) 'description': description,
        'isFreePreview': isFreePreview,
      },
    );

    if (response.success && response.data != null) {
      return {'success': true, 'course': response.data['course']};
    }
    return {'success': false, 'message': response.message ?? 'Add lesson failed'};
  }

  // Delete Lesson (Teacher/Admin)
  static Future<Map<String, dynamic>> deleteLesson({
    required String courseId,
    required String lessonId,
  }) async {
    final response = await ApiClient.delete(
      ApiConstants.deleteLesson(courseId, lessonId),
    );

    if (response.success && response.data != null) {
      return {'success': true, 'course': response.data['course']};
    }
    return {'success': false, 'message': response.message ?? 'Delete lesson failed'};
  }
}
