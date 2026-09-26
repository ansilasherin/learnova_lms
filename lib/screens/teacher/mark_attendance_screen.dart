import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/academic_service.dart';
import '../../services/file_download_service.dart';
import '../attendance/class_attendance_sheet_screen.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final CourseModel? initialCourse;

  const MarkAttendanceScreen({super.key, this.initialCourse});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  String _selectedSubject = 'Computer Science';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isDownloading = false;
  bool _isDateRecorded = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> _sheet = [];

  final List<String> _commonSubjects = [
    'Computer Science',
    'Data Structures',
    'Database Systems',
    'Operating Systems',
    'Computer Networks',
    'Web Development',
    'Mathematics',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCourse != null) {
      _selectedSubject = widget.initialCourse!.title;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProv = Provider.of<CourseProvider>(context, listen: false);
      if (widget.initialCourse == null && courseProv.courses.isNotEmpty) {
        _selectedSubject = courseProv.courses.first.title;
      }
      _loadAttendanceSheet();
    });
  }

  Future<void> _loadAttendanceSheet() async {
    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);
      final res = await AcademicService.getClassAttendanceSheet(
        subject: _selectedSubject,
        date: dateStr,
      );

      setState(() {
        _isDateRecorded = res['isRecorded'] == true;
        _sheet = res['sheet'] is List ? List<Map<String, dynamic>>.from(res['sheet']) : [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _markAll(bool isPresent) {
    setState(() {
      for (var s in _sheet) {
        s['status'] = isPresent ? 'present' : 'absent';
        s['isPresent'] = isPresent;
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_sheet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students in register to mark attendance'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    // Check if any student is still unmarked
    final unmarkedCount = _sheet.where((s) => s['status'] == 'unmarked').length;
    if (unmarkedCount > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Unmarked Students'),
          content: Text('$unmarkedCount student(s) are not marked yet. Do you want to mark unmarked students as Absent and save?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Review Sheet'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Anyway', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() => _isSubmitting = true);

    final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);
    final records = _sheet.map((s) {
      final isPresent = s['status'] == 'present';
      return {
        'studentId': s['id'],
        'name': s['name'] ?? 'Student',
        'rollNo': s['rollNo'] ?? '',
        'status': isPresent ? 'present' : 'absent',
        'isPresent': isPresent,
      };
    }).toList();

    final result = await AcademicService.saveClassAttendanceSheet(
      subject: _selectedSubject,
      date: dateStr,
      records: records,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (result['success'] == true) {
        _isDateRecorded = true;
        Provider.of<PlannerProvider>(context, listen: false).fetchAcademicData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Attendance Sheet saved successfully! ✅',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save attendance'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _downloadCurrentAttendance() async {
    if (_sheet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance data to download')),
      );
      return;
    }

    setState(() => _isDownloading = true);

    final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);
    final result = await FileDownloadService.downloadAttendanceSheet(
      subject: _selectedSubject,
      date: dateStr,
      records: _sheet,
    );

    setState(() => _isDownloading = false);

    if (mounted) {
      FileDownloadService.showDownloadFeedback(context, result);
    }
  }

  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final batchCtrl = TextEditingController(text: 'Batch A');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Add Student to Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Student Full Name *',
                    hintText: 'e.g. Rahul Sharma',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rollCtrl,
                  decoration: InputDecoration(
                    labelText: 'Roll No / ID (Optional)',
                    hintText: 'e.g. 13',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'e.g. student@gmail.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: batchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Batch / Section',
                    hintText: 'e.g. Batch A',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.groups_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter student name')),
                  );
                  return;
                }

                Navigator.pop(dialogCtx);
                setState(() => _isLoading = true);

                final res = await AcademicService.addStudentToRoster(
                  name: name,
                  rollNo: rollCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  batch: batchCtrl.text.trim(),
                );

                if (res['success'] == true) {
                  await _loadAttendanceSheet();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Student added successfully!'),
                        backgroundColor: AppColors.emerald,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteStudent(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Remove Student?'),
          content: Text('Are you sure you want to remove "$studentName" from the class register?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final res = await AcademicService.deleteStudentFromRoster(studentId);
                await _loadAttendanceSheet();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Student removed'),
                      backgroundColor: AppColors.coral,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAttendanceSheet();
    }
  }

  void _changeDateByDays(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadAttendanceSheet();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);

    final subjectSet = <String>{};
    for (var c in courseProv.courses) {
      subjectSet.add(c.title);
    }
    for (var s in _commonSubjects) {
      subjectSet.add(s);
    }
    final allSubjects = subjectSet.toList();

    final filteredList = _sheet.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final roll = (s['rollNo'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || roll.contains(_searchQuery.toLowerCase());
    }).toList();

    final presentCount = _sheet.where((s) => s['status'] == 'present').length;
    final absentCount = _sheet.where((s) => s['status'] == 'absent').length;
    final unmarkedCount = _sheet.where((s) => s['status'] == 'unmarked').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Attendance Register', style: AppStyles.heading3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.file_download_outlined, color: AppColors.primary),
            tooltip: 'Download CSV Sheet',
            onPressed: _isDownloading ? null : _downloadCurrentAttendance,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_rounded, color: AppColors.primary),
            tooltip: 'View Full Sheet',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassAttendanceSheetScreen(
                    initialCourse: widget.initialCourse,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            tooltip: 'Add Student to Register',
            onPressed: _showAddStudentDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Sheet',
            onPressed: _loadAttendanceSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Controls Header (Subject & Date Selector with Navigation)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Subject Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: allSubjects.contains(_selectedSubject) ? _selectedSubject : allSubjects.first,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                      items: allSubjects.map((sub) {
                        return DropdownMenuItem<String>(
                          value: sub,
                          child: Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (newVal) {
                        if (newVal != null) {
                          setState(() => _selectedSubject = newVal);
                          _loadAttendanceSheet();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Date Navigation Bar (Prev Day, Date Picker, Next Day)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                      tooltip: 'Previous Day',
                      onPressed: () => _changeDateByDays(-1),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      tooltip: 'Next Day',
                      onPressed: () => _changeDateByDays(1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Bar + Batch Toggles
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search by name or roll no...',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildBatchChip('All Present ✓', AppColors.emerald, () => _markAll(true)),
                    const SizedBox(width: 6),
                    _buildBatchChip('All Absent ✗', AppColors.coral, () => _markAll(false)),
                  ],
                ),
              ],
            ),
          ),

          // 2. Status Banner (Recorded vs Not Recorded)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _isDateRecorded ? AppColors.emerald.withValues(alpha: 0.08) : AppColors.amber.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isDateRecorded ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 16,
                      color: _isDateRecorded ? AppColors.emerald : AppColors.amber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isDateRecorded
                          ? 'Attendance Recorded for this date'
                          : 'Not Marked Yet for this date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isDateRecorded ? AppColors.emerald : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildMiniBadge('P: $presentCount', AppColors.emerald),
                    const SizedBox(width: 6),
                    _buildMiniBadge('A: $absentCount', AppColors.coral),
                    if (unmarkedCount > 0) ...[
                      const SizedBox(width: 6),
                      _buildMiniBadge('Unmarked: $unmarkedCount', AppColors.textMuted),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 3. Register Sheet Student List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('No students match your search', style: AppStyles.bodyMedium),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showAddStudentDialog,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Student to Register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        itemCount: filteredList.length + 1,
                        itemBuilder: (context, index) {
                          // Last item is an inline "+ Add Student" tile
                          if (index == filteredList.length) {
                            return InkWell(
                              onTap: _showAddStudentDialog,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+ Add New Student to Register',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final student = filteredList[index];
                          final status = student['status'] ?? 'unmarked';
                          final isPresent = status == 'present';
                          final isAbsent = status == 'absent';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isPresent
                                    ? AppColors.emerald.withValues(alpha: 0.35)
                                    : (isAbsent
                                        ? AppColors.coral.withValues(alpha: 0.35)
                                        : AppColors.cardBorder),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPresent
                                          ? AppColors.emerald
                                          : (isAbsent ? AppColors.coral : Colors.black))
                                      .withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Roll Number Badge
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Center(
                                    child: Text(
                                      student['rollNo'] ?? '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Student Name & Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student['name'] ?? 'Student',
                                        style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${student['batch'] ?? 'Batch A'} ${student['email'] != null && student['email'] != '' ? '• ${student['email']}' : ''}',
                                        style: AppStyles.caption.copyWith(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Interactive Present & Absent Two-Pill Switch
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Present Button
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          student['status'] = 'present';
                                          student['isPresent'] = true;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isPresent ? AppColors.emerald : AppColors.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isPresent ? AppColors.emerald : AppColors.cardBorder,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: isPresent ? Colors.white : AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Present',
                                              style: TextStyle(
                                                color: isPresent ? Colors.white : AppColors.textSecondary,
                                                fontWeight: isPresent ? FontWeight.bold : FontWeight.w500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Absent Button
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          student['status'] = 'absent';
                                          student['isPresent'] = false;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isAbsent ? AppColors.coral : AppColors.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isAbsent ? AppColors.coral : AppColors.cardBorder,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.close_rounded,
                                              size: 14,
                                              color: isAbsent ? Colors.white : AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Absent',
                                              style: TextStyle(
                                                color: isAbsent ? Colors.white : AppColors.textSecondary,
                                                fontWeight: isAbsent ? FontWeight.bold : FontWeight.w500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),

                                // Delete Student from Register
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                                  tooltip: 'Delete Student',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _confirmDeleteStudent(
                                    student['id'].toString(),
                                    student['name'] ?? 'Student',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // 4. Bottom Sticky Submit Attendance Sheet Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Save Attendance Sheet ($presentCount P, $absentCount A)',
                              style: AppStyles.button.copyWith(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchChip(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
