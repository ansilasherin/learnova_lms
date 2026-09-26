import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/theme_provider.dart';
import '../teacher/create_course_screen.dart';
import '../teacher/manage_courses_screen.dart';
import 'course_details_screen.dart';
import 'course_search_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  final bool showBackButton;

  const MyCoursesScreen({super.key, this.showBackButton = false});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  int _selectedFilterTab = 0; // 0: Enrolled, 1: In Progress, 2: Completed, 3: All Catalog
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);
    final enrollProv = Provider.of<EnrollmentProvider>(context);
    final isTeacher = auth.isTeacher;

    final myEnrollments = enrollProv.enrollments;
    final allCourses = courseProv.courses;

    // Filter enrollments according to query & tab
    List<EnrollmentModel> filteredEnrollments = myEnrollments.where((e) {
      final title = (e.course?.title ?? '').toLowerCase();
      final instructor = (e.course?.instructor?.name ?? '').toLowerCase();
      final category = (e.course?.category ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          title.contains(query) ||
          instructor.contains(query) ||
          category.contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilterTab == 1) {
        // In Progress
        return e.progressPercentage > 0 && e.progressPercentage < 100;
      } else if (_selectedFilterTab == 2) {
        // Completed
        return e.progressPercentage >= 100;
      }
      return true; // All Enrolled
    }).toList();

    // Catalog courses for tab 3
    List<CourseModel> filteredCatalog = allCourses.where((c) {
      final query = _searchQuery.toLowerCase();
      final title = (c.title).toLowerCase();
      final instructor = (c.instructor?.name ?? '').toLowerCase();
      final category = (c.category).toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          title.contains(query) ||
          instructor.contains(query) ||
          category.contains(query);
      return matchesQuery;
    }).toList();

    final inProgressCount = myEnrollments.where((e) => e.progressPercentage > 0 && e.progressPercentage < 100).length;
    final completedCount = myEnrollments.where((e) => e.progressPercentage >= 100).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isTeacher ? 'My Published Courses' : 'My Courses & Learning', style: AppStyles.heading3),
        centerTitle: true,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              tooltip: 'Create New Course',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.explore_outlined, color: AppColors.primary),
              tooltip: 'Browse All Courses',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseSearchScreen()),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            enrollProv.fetchMyEnrollments(),
            courseProv.fetchCourses(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      isTeacher ? AppColors.purple : const Color(0xFF6366F1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(isTeacher ? Icons.cast_for_education : Icons.school_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                isTeacher ? 'Instructor Portal' : 'Student Learning Hub',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isTeacher ? '${allCourses.length} Courses Total' : '${enrollProv.enrolledCount} Enrolled',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isTeacher ? 'Course Management Studio' : 'Track Your Learning Journey',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTeacher
                          ? 'Manage published video lectures, curriculum, and distribute lesson materials.'
                          : 'Access all your enrolled subjects, watch video lessons, and track syllabus completion.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (!isTeacher) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Overall Progress', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                    Text('${enrollProv.overallProgressPercentage}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearPercentIndicator(
                                  padding: EdgeInsets.zero,
                                  lineHeight: 6,
                                  percent: (enrollProv.overallProgressPercentage / 100).clamp(0.0, 1.0),
                                  backgroundColor: Colors.white24,
                                  progressColor: const Color(0xFFFBBF24),
                                  barRadius: const Radius.circular(6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        icon: const Icon(Icons.video_library_rounded, size: 18),
                        label: const Text('Manage Video Lessons', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: AppStyles.cardDecoration(),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by course title or instructor...',
                    hintStyle: AppStyles.caption.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filter Tabs (Enrolled, In Progress, Completed, All Catalog)
              if (!isTeacher) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(0, 'Enrolled (${myEnrollments.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(1, 'In Progress ($inProgressCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip(2, 'Completed ($completedCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip(3, 'Browse Catalog (${allCourses.length})'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Course Content List
              if (_selectedFilterTab == 3) ...[
                // Catalog View
                Text('Available Course Catalog (${filteredCatalog.length})', style: AppStyles.heading3.copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                if (filteredCatalog.isEmpty)
                  _buildEmptyState('No courses found matching "$_searchQuery".')
                else
                  ...filteredCatalog.map((c) => _buildCatalogCourseCard(context, c, enrollProv)),
              ] else if (isTeacher) ...[
                // Teacher Courses
                Text('Your Published Courses (${allCourses.length})', style: AppStyles.heading3.copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                if (allCourses.isEmpty)
                  _buildEmptyState('You have not published any courses yet.')
                else
                  ...allCourses.map((c) => _buildTeacherCourseItem(context, c)),
              ] else ...[
                // Student Enrolled Courses
                Text(
                  _selectedFilterTab == 1
                      ? 'In Progress Courses (${filteredEnrollments.length})'
                      : _selectedFilterTab == 2
                          ? 'Completed Courses (${filteredEnrollments.length})'
                          : 'All Enrolled Courses (${filteredEnrollments.length})',
                  style: AppStyles.heading3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (filteredEnrollments.isEmpty)
                  _buildEmptyState(
                    _selectedFilterTab == 1
                        ? 'No courses currently in progress.'
                        : _selectedFilterTab == 2
                            ? 'No completed courses yet.'
                            : 'You have not enrolled in any courses yet.',
                    showExploreButton: _selectedFilterTab == 0,
                  )
                else
                  ...filteredEnrollments.map((e) => _buildEnrollmentCard(context, e)),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilterTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentCard(BuildContext context, EnrollmentModel enrollment) {
    final course = enrollment.course;
    if (course == null) return const SizedBox.shrink();

    final progress = (enrollment.progressPercentage / 100).clamp(0.0, 1.0);
    final isCompleted = enrollment.progressPercentage >= 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppStyles.cardDecoration(),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailsScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Category Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                course.category,
                                style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 12),
                                    SizedBox(width: 4),
                                    Text('Completed', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.title,
                          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Instructor: ${course.instructor?.name ?? "Instructor"}',
                          style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Progress Bar & Resume Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${enrollment.completedLessons.length} / ${course.lessons.length} Lessons',
                    style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${enrollment.progressPercentage}% Completed',
                    style: AppStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? AppColors.emerald : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearPercentIndicator(
                padding: EdgeInsets.zero,
                lineHeight: 6,
                percent: progress,
                backgroundColor: AppColors.surfaceSubtle,
                progressColor: isCompleted ? AppColors.emerald : AppColors.primary,
                barRadius: const Radius.circular(6),
              ),
              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailsScreen(course: course),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? AppColors.surfaceSubtle : AppColors.primary,
                    foregroundColor: isCompleted ? AppColors.textPrimary : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(isCompleted ? Icons.replay_rounded : Icons.play_circle_fill_rounded, size: 16),
                  label: Text(
                    isCompleted ? 'Review Course Lessons' : 'Continue Learning',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogCourseCard(BuildContext context, CourseModel course, EnrollmentProvider enrollProv) {
    final isEnrolled = enrollProv.isEnrolledInCourse(course.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppStyles.cardDecoration(),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailsScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.purple, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${course.instructor?.name ?? "Instructor"} • ${course.lessons.length} Lessons', style: AppStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailsScreen(course: course),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnrolled ? AppColors.surfaceSubtle : AppColors.primary,
                  foregroundColor: isEnrolled ? AppColors.textPrimary : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(isEnrolled ? 'Open' : 'Enroll', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherCourseItem(BuildContext context, CourseModel course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${course.lessons.length} Video Lessons • ${course.category}', style: AppStyles.caption),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(course: course),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, {bool showExploreButton = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          if (showExploreButton) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedFilterTab = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.explore_rounded, size: 16),
              label: const Text('Explore Course Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
