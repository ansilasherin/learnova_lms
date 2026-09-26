class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? studentId;
  final String? profileImage;
  final String? bio;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.studentId,
    this.profileImage,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      phone: json['phone'],
      studentId: json['studentId'],
      profileImage: json['profileImage'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'studentId': studentId,
      'profileImage': profileImage,
      'bio': bio,
    };
  }
}
