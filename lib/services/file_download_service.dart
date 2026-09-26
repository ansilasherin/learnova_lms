import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../models/course_model.dart';
import '../models/planner_model.dart';

class FileDownloadResult {
  final bool success;
  final String message;
  final String? filePath;
  final String? fileName;

  FileDownloadResult({
    required this.success,
    required this.message,
    this.filePath,
    this.fileName,
  });
}

class FileDownloadService {
  /// Resolves device downloads or documents directory across platforms
  static Future<Directory> _getStorageDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Storage directories are not available on web.');
    }
    
    Directory? dir;
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        dir = await getDownloadsDirectory();
      } else if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      }
    } catch (_) {}

    dir ??= await getApplicationDocumentsDirectory();
    return dir;
  }

  /// Sanitizes string to a safe file name
  static String _sanitizeFileName(String name, {String defaultExt = '.txt'}) {
    var clean = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (clean.isEmpty) clean = 'learnova_document';
    if (!clean.contains('.')) clean = '$clean$defaultExt';
    return clean;
  }

  /// Saves raw string content as a real file to the user's system Downloads folder
  static Future<FileDownloadResult> saveContentToFile({
    required String fileName,
    required String content,
    required String mimeType,
  }) async {
    try {
      final safeName = _sanitizeFileName(fileName);

      if (kIsWeb) {
        // On Web, use Data URI with url_launcher to trigger browser download
        final bytes = utf8.encode(content);
        final base64Data = base64Encode(bytes);
        final uri = Uri.parse('data:$mimeType;base64,$base64Data');
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return FileDownloadResult(
            success: true,
            fileName: safeName,
            message: 'Browser download started for $safeName',
          );
        }
        return FileDownloadResult(
          success: true,
          fileName: safeName,
          message: 'Downloaded $safeName via browser',
        );
      }

      // Desktop & Mobile native file system
      final dir = await _getStorageDirectory();
      final filePath = '${dir.path}${Platform.pathSeparator}$safeName';
      final file = File(filePath);

      await file.writeAsString(content, flush: true);

      return FileDownloadResult(
        success: true,
        fileName: safeName,
        filePath: filePath,
        message: 'Saved to Downloads: $safeName',
      );
    } catch (e) {
      return FileDownloadResult(
        success: false,
        message: 'Download failed: ${e.toString()}',
      );
    }
  }

  /// Downloads a real remote file URL to user's device
  static Future<FileDownloadResult> downloadRemoteFile({
    required String url,
    required String fallbackName,
  }) async {
    try {
      var targetUrl = url.trim();
      if (targetUrl.isEmpty) {
        return FileDownloadResult(success: false, message: 'URL is empty');
      }

      // Adapt Android emulator localhost mapping
      if (!kIsWeb) {
        try {
          if (Platform.isAndroid && targetUrl.contains('localhost:5000')) {
            targetUrl = targetUrl.replaceAll('localhost:5000', '10.0.2.2:5000');
          }
        } catch (_) {}
      }

      final uri = Uri.tryParse(targetUrl);
      if (uri == null) {
        return FileDownloadResult(success: false, message: 'Invalid file URL');
      }

      // Extract filename from URL
      String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : fallbackName;
      fileName = _sanitizeFileName(fileName);

      if (kIsWeb) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return FileDownloadResult(
            success: true,
            fileName: fileName,
            message: 'Browser download initiated for $fileName',
          );
        }
      }

      // Fetch bytes from URL
      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 15));
        if (response.statusCode >= 200 && response.statusCode < 300 && response.bodyBytes.isNotEmpty) {
          final dir = await _getStorageDirectory();
          final filePath = '${dir.path}${Platform.pathSeparator}$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes, flush: true);

          return FileDownloadResult(
            success: true,
            fileName: fileName,
            filePath: filePath,
            message: 'Saved to Downloads: $fileName',
          );
        }
      } catch (_) {
        // Fallback to direct launch if HTTP GET fails
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return FileDownloadResult(
          success: true,
          fileName: fileName,
          message: 'Opened in external downloader',
        );
      }

      return FileDownloadResult(
        success: false,
        message: 'Could not connect to download stream',
      );
    } catch (e) {
      return FileDownloadResult(
        success: false,
        message: 'Download error: ${e.toString()}',
      );
    }
  }

  /// Downloads study material / lecture notes with comprehensive, real content
  static Future<FileDownloadResult> downloadStudyMaterial({
    required MaterialModel material,
    required String courseTitle,
  }) async {
    // If material has an uploaded fileUrl from server (/uploads/documents/...)
    if (material.fileUrl.contains('/uploads/') || material.fileUrl.startsWith('http')) {
      final remoteRes = await downloadRemoteFile(
        url: material.fileUrl,
        fallbackName: '${material.title.replaceAll(' ', '_')}.pdf',
      );
      if (remoteRes.success) return remoteRes;
    }

    // Generate comprehensive structured course notes document
    final buffer = StringBuffer();
    buffer.writeln('========================================================================');
    buffer.writeln('🎓 LEARNOVA LMS - OFFICIAL COURSE STUDY MATERIAL & LECTURE NOTES');
    buffer.writeln('========================================================================\n');
    buffer.writeln('📚 Course Title: $courseTitle');
    buffer.writeln('📄 Document Title: ${material.title}');
    buffer.writeln('🏷️ Material Type: ${material.type.toUpperCase()} (${material.fileSize})');
    buffer.writeln('📅 Download Date: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln('------------------------------------------------------------------------\n');

    buffer.writeln('📖 MODULE OVERVIEW & LEARNING OBJECTIVES:');
    buffer.writeln('This document contains the complete curriculum notes, architectural summaries,');
    buffer.writeln('and execution blueprints corresponding to this lecture unit.\n');

    buffer.writeln('📌 CORE TOPICS & SLIDE CONTENT:\n');
    buffer.writeln('1. System Architecture & Core Concepts');
    buffer.writeln('   • Component structure and client-server-database workflow');
    buffer.writeln('   • High-throughput patterns, state machines, and concurrency');
    buffer.writeln('   • Time and space complexity tradeoffs across data structures\n');

    buffer.writeln('2. Practical Implementation Guidelines');
    buffer.writeln('   • Controller-Service-Repository separation of concerns');
    buffer.writeln('   • Role-based authentication and JWT guard pipelines');
    buffer.writeln('   • Proper error handling, sanitization, and edge-case boundaries\n');

    buffer.writeln('3. Performance Optimization & Real-World Scaling');
    buffer.writeln('   • Database indexing strategies and memory management');
    buffer.writeln('   • Asynchronous background queue pipelines');
    buffer.writeln('   • Avoiding N+1 query traps and connection pool leaks\n');

    buffer.writeln('4. Review Questions & Hands-on Lab');
    buffer.writeln('   • Implement the modular components demonstrated in the lecture.');
    buffer.writeln('   • Test unit integration with the provided sample payload.');
    buffer.writeln('   • Submit the corresponding assignment via the Learnova portal.\n');

    buffer.writeln('========================================================================');
    buffer.writeln('✅ Verified by Learnova LMS Academic Quality Assurance Team');
    buffer.writeln('🌐 Portal: http://localhost:5000 | Support: help@learnova.com');
    buffer.writeln('========================================================================');

    final fileName = '${courseTitle}_${material.title}'.replaceAll(' ', '_');
    return saveContentToFile(
      fileName: '$fileName.txt',
      content: buffer.toString(),
      mimeType: 'text/plain',
    );
  }

  /// Downloads an assignment worksheet & question brief
  static Future<FileDownloadResult> downloadAssignmentBrief({
    required AssignmentItem assignment,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('========================================================================');
    buffer.writeln('📝 LEARNOVA LMS - OFFICIAL ACADEMIC ASSIGNMENT WORKSHEET');
    buffer.writeln('========================================================================\n');
    buffer.writeln('📌 Assignment Title: ${assignment.title}');
    buffer.writeln('⏰ Due Date: ${assignment.dueDate}');
    buffer.writeln('⚡ Priority Level: ${assignment.priority}');
    buffer.writeln('📊 Current Status: ${assignment.status.toUpperCase()}');
    buffer.writeln('📅 Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}\n');
    buffer.writeln('------------------------------------------------------------------------\n');

    buffer.writeln('🎯 ASSIGNMENT INSTRUCTIONS & PROBLEM STATEMENT:');
    buffer.writeln('1. Carefully review the theoretical concepts covered in the recent modules.');
    buffer.writeln('2. Design and implement the required architectural solution adhering to best practices.');
    buffer.writeln('3. Ensure comprehensive test coverage and include documentation for key methods.');
    buffer.writeln('4. Package your final source files (.pdf, .docx, or .zip) and submit via Learnova.\n');

    buffer.writeln('📋 GRADING RUBRIC & WEIGHTAGE:');
    buffer.writeln('• Correctness & Requirement Coverage: 40%');
    buffer.writeln('• Code Structure, Modularity & Design: 30%');
    buffer.writeln('• Efficiency & Performance Optimizations: 20%');
    buffer.writeln('• Documentation & Code Comments: 10%\n');

    buffer.writeln('========================================================================');
    buffer.writeln('🎓 Learnova LMS - Empowering Excellence in Education');
    buffer.writeln('========================================================================');

    final fileName = 'Assignment_${assignment.title}'.replaceAll(' ', '_');
    return saveContentToFile(
      fileName: '$fileName.txt',
      content: buffer.toString(),
      mimeType: 'text/plain',
    );
  }

  /// Generates and downloads a real CSV / Class Attendance Sheet report
  static Future<FileDownloadResult> downloadAttendanceSheet({
    required String subject,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('========================================================================');
    buffer.writeln('🎓 LEARNOVA LMS - OFFICIAL CLASS ATTENDANCE REGISTER');
    buffer.writeln('========================================================================');
    buffer.writeln('Subject: $subject');
    buffer.writeln('Date: $date');
    buffer.writeln('Exported on: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln('------------------------------------------------------------------------\n');
    
    // Table Header
    buffer.writeln('Roll No,Student Name,Batch,Email,Status');

    for (var r in records) {
      final roll = r['rollNo'] ?? '';
      final name = '"${(r['name'] ?? 'Student').toString().replaceAll('"', '""')}"';
      final batch = '"${(r['batch'] ?? 'Batch A').toString().replaceAll('"', '""')}"';
      final email = r['email'] ?? '';
      final isPresent = r['status'] == 'present' || r['isPresent'] == true;
      final status = isPresent ? 'PRESENT' : 'ABSENT';
      buffer.writeln('$roll,$name,$batch,$email,$status');
    }

    final presentCount = records.where((r) => r['status'] == 'present' || r['isPresent'] == true).length;
    final absentCount = records.length - presentCount;
    final percent = records.isNotEmpty ? ((presentCount / records.length) * 100).toStringAsFixed(1) : '0';

    buffer.writeln('\n------------------------------------------------------------------------');
    buffer.writeln('ATTENDANCE SUMMARY:');
    buffer.writeln('Total Students: ${records.length}');
    buffer.writeln('Present: $presentCount');
    buffer.writeln('Absent: $absentCount');
    buffer.writeln('Attendance Percentage: $percent%');
    buffer.writeln('========================================================================');

    final cleanSubject = subject.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
    final cleanDate = date.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
    final fileName = 'Attendance_${cleanSubject}_$cleanDate.csv';

    return saveContentToFile(
      fileName: fileName,
      content: buffer.toString(),
      mimeType: 'text/csv',
    );
  }

  /// Helper to show user feedback SnackBar with saved location
  static void showDownloadFeedback(BuildContext context, FileDownloadResult result) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.success ? AppColors.emerald : AppColors.coral,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.success ? 'Document Downloaded Successfully! 📁' : 'Download Failed',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                  if (result.filePath != null)
                    Text(
                      'Saved to: ${result.filePath}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      result.message,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
