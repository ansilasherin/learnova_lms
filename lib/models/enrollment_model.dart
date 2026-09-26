import 'course_model.dart';

class EnrollmentModel {
  final String id;
  final String studentId;
  final CourseModel? course;
  final String courseId;
  final List<String> completedLessons;
  final int progressPercentage;
  final bool isCompleted;
  final DateTime? enrolledAt;

  EnrollmentModel({
    required this.id,
    required this.studentId,
    this.course,
    required this.courseId,
    this.completedLessons = const [],
    this.progressPercentage = 0,
    this.isCompleted = false,
    this.enrolledAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    CourseModel? parsedCourse;
    String cId = '';

    if (json['course'] != null) {
      if (json['course'] is Map<String, dynamic>) {
        parsedCourse = CourseModel.fromJson(json['course']);
        cId = parsedCourse.id;
      } else if (json['course'] is String) {
        cId = json['course'];
      }
    }

    var rawCompleted = json['completedLessons'] as List? ?? [];
    List<String> completed = rawCompleted.map((e) => e.toString()).toList();

    return EnrollmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['student'] is String
          ? json['student']
          : (json['student'] is Map ? json['student']['_id'] ?? '' : ''),
      course: parsedCourse,
      courseId: cId,
      completedLessons: completed,
      progressPercentage: json['progressPercentage'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.tryParse(json['enrolledAt'])
          : null,
    );
  }
}
