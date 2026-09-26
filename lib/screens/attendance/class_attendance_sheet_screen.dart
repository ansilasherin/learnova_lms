import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/academic_service.dart';
import '../../services/file_download_service.dart';
import '../teacher/mark_attendance_screen.dart';

class ClassAttendanceSheetScreen extends StatefulWidget {
  final CourseModel? initialCourse;

  const ClassAttendanceSheetScreen({super.key, this.initialCourse});

  @override
  State<ClassAttendanceSheetScreen> createState() => _ClassAttendanceSheetScreenState();
}

class _ClassAttendanceSheetScreenState extends State<ClassAttendanceSheetScreen> {
  String _selectedSubject = 'Computer Science';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isRecorded = false;
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
      _loadSheet();
    });
  }

  Future<void> _loadSheet() async {
    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);
      final res = await AcademicService.getClassAttendanceSheet(
        subject: _selectedSubject,
        date: dateStr,
      );

      setState(() {
        _isRecorded = res['isRecorded'] == true;
        _sheet = res['sheet'] is List ? List<Map<String, dynamic>>.from(res['sheet']) : [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadSheet() async {
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
      _loadSheet();
    }
  }

  void _changeDateByDays(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadSheet();
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
    final presentPercent = _sheet.isNotEmpty ? ((presentCount / _sheet.length) * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Class Attendance Sheet', style: AppStyles.heading3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.file_download_outlined, color: AppColors.primary),
            tooltip: 'Download CSV Sheet',
            onPressed: _isDownloading ? null : _downloadSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
            onPressed: _loadSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Navigation Header
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
                          _loadSheet();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Date Navigation Bar
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

                // Search Bar + Action Buttons
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
                            hintText: 'Search student...',
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Take/Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MarkAttendanceScreen(),
                          ),
                        ).then((_) => _loadSheet());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sheet Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _isRecorded ? AppColors.emerald.withValues(alpha: 0.08) : AppColors.amber.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isRecorded ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 16,
                      color: _isRecorded ? AppColors.emerald : AppColors.amber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isRecorded ? 'Recorded Sheet' : 'Not Recorded',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isRecorded ? AppColors.emerald : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildMiniBadge('Present: $presentCount ($presentPercent%)', AppColors.emerald),
                    const SizedBox(width: 6),
                    _buildMiniBadge('Absent: $absentCount', AppColors.coral),
                    if (unmarkedCount > 0) ...[
                      const SizedBox(width: 6),
                      _buildMiniBadge('Unmarked: $unmarkedCount', AppColors.textMuted),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Attendance Sheet Matrix / Register Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_rows_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('No students found in sheet', style: AppStyles.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final student = filteredList[index];
                          final status = student['status'] ?? 'unmarked';
                          final isPresent = status == 'present';
                          final isAbsent = status == 'absent';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isPresent
                                    ? AppColors.emerald.withValues(alpha: 0.3)
                                    : (isAbsent
                                        ? AppColors.coral.withValues(alpha: 0.3)
                                        : AppColors.cardBorder),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Roll Number Pill
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(10),
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
                                const SizedBox(width: 12),

                                // Student Details
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

                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? AppColors.emerald.withValues(alpha: 0.12)
                                        : (isAbsent
                                            ? AppColors.coral.withValues(alpha: 0.12)
                                            : AppColors.surfaceSubtle),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isPresent
                                          ? AppColors.emerald.withValues(alpha: 0.3)
                                          : (isAbsent
                                              ? AppColors.coral.withValues(alpha: 0.3)
                                              : AppColors.cardBorder),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPresent
                                            ? Icons.check_circle_rounded
                                            : (isAbsent ? Icons.cancel_rounded : Icons.help_outline_rounded),
                                        size: 14,
                                        color: isPresent
                                            ? AppColors.emerald
                                            : (isAbsent ? AppColors.coral : AppColors.textMuted),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPresent ? 'PRESENT' : (isAbsent ? 'ABSENT' : 'UNMARKED'),
                                        style: TextStyle(
                                          color: isPresent
                                              ? AppColors.emerald
                                              : (isAbsent ? AppColors.coral : AppColors.textMuted),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Download Bar
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
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                  label: Text(
                    'Download Official CSV Sheet 📥',
                    style: AppStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
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
