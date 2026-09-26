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
import '../../widgets/cards/course_card.dart';
import '../course/course_details_screen.dart';
import '../course/course_search_screen.dart';
import '../teacher/manage_courses_screen.dart';
import 'teacher_home_view.dart';

class MobileHomeView extends StatelessWidget {
  const MobileHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // If teacher, show dedicated Teacher Studio Dashboard
    if (auth.isTeacher) {
      return const TeacherHomeView();
    }

    final courseProv = Provider.of<CourseProvider>(context);
    final enrollProv = Provider.of<EnrollmentProvider>(context);
    final plannerProv = Provider.of<PlannerProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final user = auth.currentUser;

    final pendingAssignmentsCount = plannerProv.assignments.where((a) => a.status == 'pending').length;

    // Active continuous learning course
    final activeEnrollment = enrollProv.enrollments.isNotEmpty ? enrollProv.enrollments.first : null;
    final activeCourse = activeEnrollment?.course ?? (courseProv.courses.isNotEmpty ? courseProv.courses.first : null);
    final activeProgress = activeEnrollment?.progressPercentage ?? (enrollProv.enrollments.isNotEmpty ? 50 : 0);

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Greeting & Avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hi, ${user?.name.split(' ').first ?? 'Student'}',
                          style: AppStyles.heading2.copyWith(fontSize: 22),
                        ),
                        const SizedBox(width: 6),
                        const Text('👋', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.role == 'teacher'
                          ? 'Welcome to your Teacher Dashboard'
                          : "Let's continue learning today!",
                      style: AppStyles.bodySmall,
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
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Real-time Search Trigger Bar
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseSearchScreen()),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppStyles.cardDecoration(),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Search across ${courseProv.courses.length} courses, topics...',
                      style: AppStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Teacher Studio Quick Action (if Teacher or Admin)
            if (auth.isTeacher || auth.isAdmin) ...[
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teacher Studio 🎓',
                              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.purple),
                            ),
                            Text(
                              'Create new courses & add video lessons',
                              style: AppStyles.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.purple),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 4 Live Stats Quick Badges
            Row(
              children: [
                _buildMiniStatChip(
                  icon: Icons.school_rounded,
                  label: '${enrollProv.enrolledCount} Enrolled',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildMiniStatChip(
                  icon: Icons.assignment_outlined,
                  label: '$pendingAssignmentsCount Due',
                  color: AppColors.amber,
                ),
                const SizedBox(width: 8),
                _buildMiniStatChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: '${(plannerProv.attendanceRate * 100).toInt()}% Att.',
                  color: AppColors.emerald,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Dynamic "Continue Learning" Gradient Banner
            if (activeCourse != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            enrollProv.isEnrolledInCourse(activeCourse.id)
                                ? 'Continue Learning'
                                : 'Featured Course',
                            style: AppStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          activeCourse.category,
                          style: AppStyles.caption.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeCourse.title,
                                style: AppStyles.heading3.copyWith(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeCourse.lessons.isNotEmpty
                                    ? activeCourse.lessons.first.title
                                    : 'Start your first lesson today',
                                style: AppStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Play Button
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseDetailsScreen(course: activeCourse),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$activeProgress% Complete',
                          style: AppStyles.caption.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                        Text(
                          '${activeCourse.lessons.length} Lessons',
                          style: AppStyles.caption.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearPercentIndicator(
                      padding: EdgeInsets.zero,
                      lineHeight: 6,
                      percent: (activeProgress / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.25),
                      progressColor: Colors.white,
                      barRadius: const Radius.circular(6),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // Courses Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Explore Courses', style: AppStyles.heading3.copyWith(fontSize: 18)),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CourseSearchScreen()),
                    );
                  },
                  child: Text(
                    'View All (${courseProv.courses.length})',
                    style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Live Course List from Backend MongoDB
            if (courseProv.isLoading && courseProv.courses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (courseProv.courses.isNotEmpty)
              ...courseProv.courses.map((course) {
                final enrollment = enrollProv.getEnrollmentForCourse(course.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: CourseCard(
                    course: course,
                    isCompact: true,
                    progressPercentage: enrollment?.progressPercentage ?? 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailsScreen(course: course),
                        ),
                      ).then((_) {
                        enrollProv.fetchMyEnrollments();
                      });
                    },
                  ),
                );
              })
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: AppStyles.cardDecoration(),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text('No courses available', style: AppStyles.bodyMedium),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => courseProv.fetchCourses(),
                        child: const Text('Refresh Courses'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
