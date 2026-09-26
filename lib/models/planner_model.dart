import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String title;
  final String instructor;
  final String time;
  final String duration;
  final bool isLive;
  final Color color;
  final String type; // 'class' (Teacher / College Lecture) or 'self_study' (Student Personal Task)
  final bool isCompleted;
  final String location;
  final String notes;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.instructor,
    required this.time,
    required this.duration,
    this.isLive = false,
    required this.color,
    this.type = 'class',
    this.isCompleted = false,
    this.location = '',
    this.notes = '',
  });

  ScheduleItem copyWith({
    String? id,
    String? title,
    String? instructor,
    String? time,
    String? duration,
    bool? isLive,
    Color? color,
    String? type,
    bool? isCompleted,
    String? location,
    String? notes,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      instructor: instructor ?? this.instructor,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      isLive: isLive ?? this.isLive,
      color: color ?? this.color,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }
}

class StudentSubmissionItem {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String studentRollNo;
  final String profileImage;
  final DateTime? submittedAt;
  final String fileName;
  final String fileUrl;
  final String submissionText;
  final String status; // 'submitted', 'graded', 'reviewed'
  final double? score;
  final double maxScore;
  final String feedback;
  final DateTime? gradedAt;
  final String gradedByName;

  StudentSubmissionItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentEmail = '',
    this.studentRollNo = '',
    this.profileImage = '',
    this.submittedAt,
    this.fileName = '',
    this.fileUrl = '',
    this.submissionText = '',
    this.status = 'submitted',
    this.score,
    this.maxScore = 100.0,
    this.feedback = '',
    this.gradedAt,
    this.gradedByName = '',
  });

  factory StudentSubmissionItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic dateVal) {
      if (dateVal == null) return null;
      if (dateVal is DateTime) return dateVal;
      try {
        return DateTime.parse(dateVal.toString());
      } catch (_) {
        return null;
      }
    }

    return StudentSubmissionItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Student',
      studentEmail: json['studentEmail']?.toString() ?? '',
      studentRollNo: json['studentRollNo']?.toString() ?? '',
      profileImage: json['profileImage']?.toString() ?? '',
      submittedAt: parseDate(json['submittedAt']),
      fileName: json['fileName']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      submissionText: json['submissionText']?.toString() ?? '',
      status: json['status']?.toString() ?? 'submitted',
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : null,
      maxScore: (json['maxScore'] is num) ? (json['maxScore'] as num).toDouble() : 100.0,
      feedback: json['feedback']?.toString() ?? '',
      gradedAt: parseDate(json['gradedAt']),
      gradedByName: json['gradedByName']?.toString() ?? '',
    );
  }
}

class AssignmentItem {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String dueDate;
  final String priority; // High Priority, Medium Priority, Low Priority
  final double maxScore;
  final int progress;
  final String status; // pending, submitted, graded
  final double? score;
  final String? feedback;
  final DateTime? submittedAt;
  final String? fileName;
  final String? fileUrl;
  final String? submissionText;
  final String? gradedByName;
  final int totalSubmissions;
  final int gradedCount;
  final int pendingCount;
  final List<StudentSubmissionItem> submissions;

  AssignmentItem({
    required this.id,
    required this.title,
    required this.subject,
    this.description = '',
    required this.dueDate,
    required this.priority,
    this.maxScore = 100.0,
    required this.progress,
    required this.status,
    this.score,
    this.feedback,
    this.submittedAt,
    this.fileName,
    this.fileUrl,
    this.submissionText,
    this.gradedByName,
    this.totalSubmissions = 0,
    this.gradedCount = 0,
    this.pendingCount = 0,
    this.submissions = const [],
  });

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic dateVal) {
      if (dateVal == null) return null;
      if (dateVal is DateTime) return dateVal;
      try {
        return DateTime.parse(dateVal.toString());
      } catch (_) {
        return null;
      }
    }

    final rawSubmissions = json['submissions'];
    List<StudentSubmissionItem> parsedSubs = [];
    if (rawSubmissions is List) {
      parsedSubs = rawSubmissions
          .map((s) => StudentSubmissionItem.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    }

    return AssignmentItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dueDate: json['dueDate']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium Priority',
      maxScore: (json['maxScore'] is num) ? (json['maxScore'] as num).toDouble() : 100.0,
      progress: (json['progress'] is num) ? (json['progress'] as num).toInt() : 0,
      status: json['status']?.toString() ?? 'pending',
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : null,
      feedback: json['feedback']?.toString(),
      submittedAt: parseDate(json['submittedAt']),
      fileName: json['fileName']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      submissionText: json['submissionText']?.toString(),
      gradedByName: json['gradedByName']?.toString(),
      totalSubmissions: (json['totalSubmissions'] is num)
          ? (json['totalSubmissions'] as num).toInt()
          : parsedSubs.length,
      gradedCount: (json['gradedCount'] is num)
          ? (json['gradedCount'] as num).toInt()
          : parsedSubs.where((s) => s.status == 'graded').length,
      pendingCount: (json['pendingCount'] is num)
          ? (json['pendingCount'] as num).toInt()
          : parsedSubs.where((s) => s.status != 'graded').length,
      submissions: parsedSubs,
    );
  }
}

class BadgeItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = true,
  });
}

class GradeItem {
  final String subject;
  final String grade;
  final double score;
  final double maxScore;

  GradeItem({
    required this.subject,
    required this.grade,
    required this.score,
    this.maxScore = 10.0,
  });
}
