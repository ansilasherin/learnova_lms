class LessonModel {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String duration;
  final bool isFreePreview;

  LessonModel({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    required this.duration,
    this.isFreePreview = false,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      videoUrl: json['videoUrl'] ?? '',
      duration: json['duration'] ?? '10 mins',
      isFreePreview: json['isFreePreview'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'duration': duration,
      'isFreePreview': isFreePreview,
    };
  }
}

class MaterialModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'pdf', 'slide', 'document', 'link'
  final String fileUrl;
  final String fileSize;

  MaterialModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    required this.fileUrl,
    this.fileSize = '2.5 MB',
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'pdf',
      fileUrl: json['fileUrl'] ?? '',
      fileSize: json['fileSize'] ?? '2.5 MB',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'type': type,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
    };
  }
}

class InstructorModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;

  InstructorModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    return InstructorModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Instructor',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String level;
  final String thumbnail;
  final InstructorModel? instructor;
  final List<LessonModel> lessons;
  final List<MaterialModel> materials;
  final int enrolledCount;
  final double rating;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.level,
    required this.thumbnail,
    this.instructor,
    this.lessons = const [],
    this.materials = const [],
    this.enrolledCount = 0,
    this.rating = 4.8,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    var rawLessons = json['lessons'] as List? ?? [];
    List<LessonModel> parsedLessons =
        rawLessons.map((l) => LessonModel.fromJson(l is Map<String, dynamic> ? l : {})).toList();

    var rawMaterials = json['materials'] as List? ?? [];
    List<MaterialModel> parsedMaterials =
        rawMaterials.map((m) => MaterialModel.fromJson(m is Map<String, dynamic> ? m : {})).toList();

    InstructorModel? parsedInstructor;
    if (json['instructor'] != null) {
      if (json['instructor'] is Map<String, dynamic>) {
        parsedInstructor = InstructorModel.fromJson(json['instructor']);
      } else if (json['instructor'] is String) {
        parsedInstructor = InstructorModel(
          id: json['instructor'],
          name: 'Instructor',
          email: '',
        );
      }
    }

    return CourseModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      price: (json['price'] != null) ? (json['price'] as num).toDouble() : 0.0,
      level: json['level'] ?? 'Beginner',
      thumbnail: json['thumbnail'] ??
          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
      instructor: parsedInstructor,
      lessons: parsedLessons,
      materials: parsedMaterials,
      enrolledCount: (json['enrolledStudents'] is List)
          ? (json['enrolledStudents'] as List).length
          : 0,
      rating: 4.8,
    );
  }
}
