import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/academic_service.dart';
import '../../services/file_download_service.dart';
import '../assignments/assignments_screen.dart';
import '../assignments/create_assignment_dialog.dart';
import '../attendance/class_attendance_sheet_screen.dart';
import '../teacher/add_lesson_dialog.dart';
import '../teacher/create_course_screen.dart';
import '../teacher/manage_courses_screen.dart';
import '../teacher/manage_materials_dialog.dart';
import '../teacher/mark_attendance_screen.dart';

class TeacherHomeView extends StatefulWidget {
  const TeacherHomeView({super.key});

  @override
  State<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends State<TeacherHomeView> {
  List<Map<String, dynamic>> _roster = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final rosterList = await AcademicService.getRoster();
      setState(() {
        _roster = rosterList;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);
    final plannerProv = Provider.of<PlannerProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final user = auth.currentUser;

    final myCourses = courseProv.courses;
    final totalLessons = myCourses.fold<int>(0, (sum, c) => sum + c.lessons.length);
    final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          courseProv.fetchCourses(),
          plannerProv.fetchAcademicData(),
          _loadTeacherData(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Teacher Header Banner & Avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Welcome, ${user?.name.split(' ').first ?? 'Professor'} 🎓',
                          style: AppStyles.heading2.copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Teacher Studio & Class Command Center',
                      style: AppStyles.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        themeProv.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: themeProv.isDarkMode ? const Color(0xFFFBBF24) : AppColors.textSecondary,
                        size: 22,
                      ),
                      tooltip: themeProv.isDarkMode ? 'Light Mode' : 'Dark Mode',
                      onPressed: () => themeProv.toggleTheme(),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.purple.withValues(alpha: 0.15),
                      child: Text(
                        (user?.name ?? 'T').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Teacher Studio Banner (Graduated Hero Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Teacher Studio Active', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(DateTime.now()),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Classroom Attendance & Course Management',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage class attendance registers, upload real video lessons, and distribute lecture notes.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
                          ).then((_) => _loadTeacherData());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                        label: const Text('Take Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ClassAttendanceSheetScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.table_chart_rounded, size: 18),
                        label: const Text('View Sheet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Teacher Studio Quick Metrics (4 items)
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Courses',
                    value: '${myCourses.length}',
                    subtitle: 'Published',
                    icon: Icons.school_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Roster',
                    value: '${_roster.length}',
                    subtitle: 'Students',
                    icon: Icons.people_rounded,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Videos',
                    value: '$totalLessons',
                    subtitle: 'Lessons',
                    icon: Icons.play_circle_fill_rounded,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Tasks',
                    value: '${plannerProv.assignments.length}',
                    subtitle: 'Evaluations',
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Teacher Command Center (Quick Action Grid)
            Text('Studio Actions', style: AppStyles.heading3.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  title: 'Grade Tasks',
                  subtitle: 'Review & grade work',
                  icon: Icons.rate_review_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'Attendance Sheet',
                  subtitle: 'Take & Download CSV',
                  icon: Icons.how_to_reg_rounded,
                  color: AppColors.emerald,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClassAttendanceSheetScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'New Assignment',
                  subtitle: 'Post task for class',
                  icon: Icons.assignment_add,
                  color: const Color(0xFFF97316),
                  onTap: () {
                    CreateAssignmentDialog.show(context);
                  },
                ),
                _buildActionCard(
                  title: 'Course Studio',
                  subtitle: 'Add video lessons',
                  icon: Icons.video_collection_rounded,
                  color: AppColors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'Create Course',
                  subtitle: 'Publish new course',
                  icon: Icons.add_circle_outline_rounded,
                  color: AppColors.cyan,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'Student Roster',
                  subtitle: 'Add new students',
                  icon: Icons.person_add_rounded,
                  color: AppColors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. My Published Courses Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Courses (${myCourses.length})', style: AppStyles.heading3.copyWith(fontSize: 18)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
                    );
                  },
                  child: const Text('Manage All'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (myCourses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppStyles.cardDecoration(),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text('No courses published yet', style: AppStyles.bodyLarge),
                      const SizedBox(height: 4),
                      Text('Click "+ Create Course" to add your first course!', style: AppStyles.caption),
                    ],
                  ),
                ),
              )
            else
              ...myCourses.take(3).map((c) => _buildCourseTeacherCard(context, c)),

            const SizedBox(height: 24),

            // 6. Quick Attendance Export Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.file_download_outlined, color: AppColors.emerald, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Download Today\'s Attendance Sheet', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Export official CSV attendance report for $todayStr', style: AppStyles.caption),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final subject = myCourses.isNotEmpty ? myCourses.first.title : 'Computer Science';
                      final res = await AcademicService.getClassAttendanceSheet(subject: subject, date: todayStr);
                      final sheet = res['sheet'] is List ? List<Map<String, dynamic>>.from(res['sheet']) : <Map<String, dynamic>>[];
                      final downloadRes = await FileDownloadService.downloadAttendanceSheet(
                        subject: subject,
                        date: todayStr,
                        records: sheet,
                      );
                      if (context.mounted) {
                        FileDownloadService.showDownloadFeedback(context, downloadRes);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppStyles.heading2.copyWith(fontSize: 22, color: AppColors.textPrimary)),
          Text(subtitle, style: AppStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppStyles.caption.copyWith(fontSize: 10), maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseTeacherCard(BuildContext context, CourseModel course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold), maxLines: 1),
                    const SizedBox(height: 2),
                    Text('${course.category} • ${course.lessons.length} Lessons • ${course.materials.length} Materials', style: AppStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emerald,
                  side: const BorderSide(color: AppColors.emerald, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.how_to_reg_rounded, size: 14),
                label: const Text('Attendance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MarkAttendanceScreen(initialCourse: course)),
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                label: const Text('Add Lesson', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  AddLessonDialog.show(
                    context,
                    courseId: course.id,
                    courseTitle: course.title,
                  );
                },
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF97316),
                  side: const BorderSide(color: Color(0xFFF97316), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.slideshow_rounded, size: 14),
                label: Text('Materials (${course.materials.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ManageMaterialsDialog.show(context, course: course);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
