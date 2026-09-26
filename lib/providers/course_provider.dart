import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

class CourseProvider with ChangeNotifier {
  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;
  bool _isLoading = false;
  String? _errorMessage;

  List<CourseModel> get courses => _courses;
  CourseModel? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all courses
  Future<void> fetchCourses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courses = await CourseService.getAllCourses();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch single course details
  Future<CourseModel?> fetchCourseDetails(String courseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedCourse = await CourseService.getCourseById(courseId);
      return _selectedCourse;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Course (Teacher)
  Future<bool> createCourse({
    required String title,
    required String description,
    required String category,
    required double price,
    required String level,
    String? thumbnail,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await CourseService.createCourse(
      title: title,
      description: description,
      category: category,
      price: price,
      level: level,
      thumbnail: thumbnail,
    );

    _isLoading = false;
    if (res['success'] == true) {
      await fetchCourses();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }

  // Add Lesson to Course (Teacher)
  Future<bool> addLesson({
    required String courseId,
    required String title,
    required String videoUrl,
    required String duration,
    String? description,
    bool isFreePreview = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await CourseService.addLesson(
      courseId: courseId,
      title: title,
      videoUrl: videoUrl,
      duration: duration,
      description: description,
      isFreePreview: isFreePreview,
    );

    _isLoading = false;
    if (res['success'] == true) {
      await fetchCourseDetails(courseId);
      await fetchCourses();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }

  // Delete Lesson from Course (Teacher/Admin)
  Future<bool> deleteLesson({
    required String courseId,
    required String lessonId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await CourseService.deleteLesson(
      courseId: courseId,
      lessonId: lessonId,
    );

    _isLoading = false;
    if (res['success'] == true) {
      await fetchCourseDetails(courseId);
      await fetchCourses();
      return true;
    } else {
      _errorMessage = res['message'];
      notifyListeners();
      return false;
    }
  }
}
