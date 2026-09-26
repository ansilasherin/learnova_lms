import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';
import '../teacher/mark_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedMonth = 'All Months';

  final List<String> _months = [
    'All Months',
    'Sep 2026',
    'Oct 2026',
    'Nov 2026',
    'Dec 2026',
    'Jan 2027',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<PlannerProvider>(context, listen: false).fetchAcademicData(
      month: _selectedMonth == 'All Months' ? null : _selectedMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final planner = Provider.of<PlannerProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final isTeacher = authProv.isTeacher || authProv.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Attendance', style: AppStyles.heading3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teacher Studio Quick Action Banner
            if (isTeacher)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher Studio 🎓',
                            style: AppStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Mark and view class attendance register',
                            style: AppStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
                        ).then((_) => _loadData());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: const Text('Mark Sheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // Month Filter Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Filter Month:', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMonth,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                        items: _months.map((m) {
                          return DropdownMenuItem<String>(
                            value: m,
                            child: Text(
                              m,
                              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMonth = val);
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Circular Attendance Card (Real Calculation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: AppStyles.cardDecoration(),
              child: Column(
                children: [
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 12.0,
                    percent: planner.attendanceRate.clamp(0.0, 1.0),
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(planner.attendanceRate * 100).toInt()}%',
                          style: AppStyles.heading1.copyWith(fontSize: 32, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _selectedMonth == 'All Months' ? 'Overall Rate' : _selectedMonth,
                          style: AppStyles.caption,
                        ),
                      ],
                    ),
                    progressColor: planner.attendanceRate >= 0.75 ? AppColors.emerald : AppColors.amber,
                    backgroundColor: AppColors.surfaceSubtle,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Present', '${planner.presentDays}', AppColors.emerald),
                      Container(height: 30, width: 1, color: AppColors.divider),
                      _buildMetric('Absent', '${planner.absentDays}', AppColors.coral),
                      Container(height: 30, width: 1, color: AppColors.divider),
                      _buildMetric('Total Classes', '${planner.totalClasses}', AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Class Attendance History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recorded Sessions History', style: AppStyles.heading3.copyWith(fontSize: 18)),
                if (isTeacher)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Mark Sheet'),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Dynamic Real Attendance History List
            if (planner.attendanceRecords.isNotEmpty)
              ...planner.attendanceRecords.map((rec) {
                return _buildClassAttendanceTile(
                  rec['subject'] ?? 'Subject',
                  rec['date'] ?? 'Recent',
                  rec['isPresent'] == true,
                );
              })
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: AppStyles.cardDecoration(),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 44, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No attendance records found for ${_selectedMonth == 'All Months' ? 'any date' : _selectedMonth}',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Records will appear here once teachers take and save attendance.',
                      textAlign: TextAlign.center,
                      style: AppStyles.caption,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppStyles.heading2.copyWith(color: color, fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: AppStyles.caption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildClassAttendanceTile(String title, String date, bool isPresent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPresent ? AppColors.emerald : AppColors.coral).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isPresent ? AppColors.emerald : AppColors.coral,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(date, style: AppStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPresent ? AppColors.emerald : AppColors.coral).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: AppStyles.caption.copyWith(
                color: isPresent ? AppColors.emerald : AppColors.coral,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
