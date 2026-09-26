import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/theme_provider.dart';
import 'create_course_screen.dart';
import 'add_lesson_dialog.dart';
import 'manage_materials_dialog.dart';
import 'mark_attendance_screen.dart';
import '../course/course_details_screen.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Course Management', style: AppStyles.heading3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teacher Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Studio 🎓',
                          style: AppStyles.heading2.copyWith(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Publish courses, manage syllabus, and add video lessons.',
                          style: AppStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                        label: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Courses Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Published Courses (${courseProv.courses.length})',
                  style: AppStyles.heading3.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: AppColors.textMuted),
                  onPressed: () => courseProv.fetchCourses(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Course List
            if (courseProv.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (courseProv.courses.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: AppStyles.cardDecoration(),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No courses created yet', style: AppStyles.bodyLarge),
                      const SizedBox(height: 6),
                      Text('Click "+ New Course" to publish your first course!', style: AppStyles.caption),
                    ],
                  ),
                ),
              )
            else
              ...courseProv.courses.map((course) => _buildCourseManageTile(context, course)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseManageTile(BuildContext context, CourseModel course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: course.thumbnail,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 70,
                    height: 70,
                    color: AppColors.surfaceSubtle,
                    child: const Icon(Icons.school_rounded, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.category} • ${course.level}',
                      style: AppStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${course.lessons.length} Lessons',
                            style: AppStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          course.price == 0 ? 'Free' : '₹${course.price.toInt()}',
                          style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: Icon(Icons.visibility_outlined, size: 15, color: AppColors.textSecondary),
                label: Text('Preview', style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: course)),
                  );
                },
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emerald,
                  side: const BorderSide(color: AppColors.emerald, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                icon: const Icon(Icons.how_to_reg_rounded, size: 15),
                label: const Text('Attendance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MarkAttendanceScreen(initialCourse: course)),
                  );
                },
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF97316),
                  side: const BorderSide(color: Color(0xFFF97316), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                icon: const Icon(Icons.slideshow_rounded, size: 15),
                label: Text('Materials (${course.materials.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ManageMaterialsDialog.show(context, course: course).then((_) {
                    setState(() {});
                  });
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                label: const Text('Add Lesson', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  AddLessonDialog.show(
                    context,
                    courseId: course.id,
                    courseTitle: course.title,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
