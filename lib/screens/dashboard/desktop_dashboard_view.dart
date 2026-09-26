import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/cards/schedule_card.dart';
import '../../widgets/charts/progress_donut_chart.dart';
import '../../widgets/charts/performance_line_chart.dart';
import '../../widgets/dialogs/celebration_dialog.dart';
import '../course/course_search_screen.dart';
import '../teacher/manage_courses_screen.dart';
import '../planner/calendar_screen.dart';
import '../assignments/assignments_screen.dart';
import '../attendance/attendance_screen.dart';
import 'teacher_home_view.dart';

class DesktopDashboardView extends StatelessWidget {
  const DesktopDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // If teacher, render Teacher Dashboard
    if (auth.isTeacher) {
      return const TeacherHomeView();
    }

    final courseProv = Provider.of<CourseProvider>(context);
    final enrollProv = Provider.of<EnrollmentProvider>(context);
    final plannerProv = Provider.of<PlannerProvider>(context);
    final user = auth.currentUser;

    final enrolledCount = enrollProv.enrolledCount;
    final overallProgress = enrollProv.overallProgressPercentage;
    final pendingAssignments = plannerProv.assignments.where((a) => a.status == 'pending').length;
    final todayClasses = plannerProv.schedules.length;
    final attendancePercent = (plannerProv.attendanceRate * 100).toInt();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          courseProv.fetchCourses(),
          enrollProv.fetchMyEnrollments(),
          plannerProv.fetchAcademicData(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Greeting
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning,', style: AppStyles.caption.copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          user?.name ?? 'Ananya Sharma',
                          style: AppStyles.heading2.copyWith(fontSize: 24),
                        ),
                        const SizedBox(width: 6),
                        const Text('👋', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.role == 'teacher'
                          ? 'Manage your courses and student lessons from Teacher Studio'
                          : "Let's make today productive and achieve your goals!",
                      style: AppStyles.bodySmall,
                    ),
                  ],
                ),

                // Search & Actions
                Row(
                  children: [
                    // Search Box
                    Container(
                      width: 280,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        onSubmitted: (query) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseSearchScreen(initialCategory: query.isNotEmpty ? query : null),
                            ),
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for courses, classes...',
                          hintStyle: AppStyles.caption.copyWith(color: AppColors.textMuted),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Teacher Studio Button (Teacher / Admin)
                    if (auth.isTeacher || auth.isAdmin) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.school_rounded, size: 18),
                        label: const Text('Teacher Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                    ],

                    // Notification Icon
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary),
                        ),
                        if (pendingAssignments > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.coral,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$pendingAssignments',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. Quick Stats Row (4 Live Connected Cards)
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
                return Row(
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        title: 'Courses Enrolled',
                        value: '$enrolledCount',
                        subtitle: 'Active Courses',
                        icon: Icons.school_rounded,
                        iconColor: AppColors.primary,
                        iconBackgroundColor: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: cardWidth,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CalendarScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: StatCard(
                          title: 'Classes Today',
                          value: '$todayClasses',
                          subtitle: 'Scheduled',
                          icon: Icons.calendar_today_rounded,
                          iconColor: AppColors.purple,
                          iconBackgroundColor: const Color(0xFFF3E8FF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: cardWidth,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: StatCard(
                          title: 'Assignments Due',
                          value: '$pendingAssignments',
                          subtitle: 'Pending Tasks',
                          icon: Icons.assignment_outlined,
                          iconColor: AppColors.amber,
                          iconBackgroundColor: const Color(0xFFFEF3C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: cardWidth,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: StatCard(
                          title: 'Attendance',
                          value: '$attendancePercent%',
                          subtitle: 'This Month',
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppColors.emerald,
                          iconBackgroundColor: const Color(0xFFD1FAE5),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. Schedule & Learning Progress Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Schedule
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text("Today's Schedule", style: AppStyles.heading3.copyWith(fontSize: 16)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                                );
                              },
                              child: Text(
                                'View Timetable',
                                style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (plannerProv.schedules.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Text('No classes scheduled for today', style: AppStyles.caption),
                            ),
                          )
                        else
                          ...plannerProv.schedules.take(3).map((s) => ScheduleCard(schedule: s)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Learning Progress Donut Chart
                Expanded(
                  flex: 4,
                  child: ProgressDonutChart(
                    overallProgress: overallProgress > 0 ? overallProgress : (enrolledCount > 0 ? 50 : 0),
                    completedPercent: overallProgress,
                    inProgressPercent: (100 - overallProgress).clamp(0, 50),
                    notStartedPercent: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Study Goals, Streak & Performance Line Chart Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Study Goals
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.flag_rounded, color: AppColors.purple, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text('Study Goals', style: AppStyles.heading3.copyWith(fontSize: 16)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CourseSearchScreen()),
                                );
                              },
                              child: Text(
                                'Explore',
                                style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Goal 1
                        _buildGoalItem(
                          title: 'Complete Enrolled Lessons',
                          targetDate: 'Active Target: Oct 2026',
                          percent: (overallProgress / 100).clamp(0.0, 1.0),
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),

                        // Goal 2
                        _buildGoalItem(
                          title: 'Assignment Submissions',
                          targetDate: '$pendingAssignments Pending',
                          percent: plannerProv.assignments.isNotEmpty
                              ? ((plannerProv.assignments.length - pendingAssignments) / plannerProv.assignments.length)
                              : 0.50,
                          color: AppColors.emerald,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Current Streak Banner
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () {
                      CelebrationDialog.show(
                        context,
                        studentName: user?.name ?? 'Ananya',
                        percentage: overallProgress > 0 ? overallProgress : 72,
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.streakGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Streak',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFBBF24), size: 24),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Color(0xFFFBBF24),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${plannerProv.streakDays}',
                                  style: AppStyles.heading1.copyWith(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Days',
                                  style: AppStyles.caption.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              "Keep it up! You're doing great.",
                              style: AppStyles.caption.copyWith(color: Colors.white.withOpacity(0.75), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Performance Overview Graph
                const Expanded(
                  flex: 4,
                  child: PerformanceLineChart(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem({
    required String title,
    required String targetDate,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: AppStyles.caption.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(targetDate, style: AppStyles.caption),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 6,
          percent: percent.clamp(0.0, 1.0),
          backgroundColor: AppColors.surfaceSubtle,
          progressColor: color,
          barRadius: const Radius.circular(6),
        ),
      ],
    );
  }
}
