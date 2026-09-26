import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/file_download_service.dart';
import '../../widgets/common/custom_button.dart';
import '../teacher/add_lesson_dialog.dart';
import 'lesson_player_screen.dart';
import 'document_viewer_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  int _selectedTab = 0; // 0: Lessons, 1: Study Materials & Slides

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final enrollProv = Provider.of<EnrollmentProvider>(context, listen: false);
    final courseProv = Provider.of<CourseProvider>(context, listen: false);
    await Future.wait([
      enrollProv.fetchCourseProgress(widget.course.id),
      courseProv.fetchCourseDetails(widget.course.id),
    ]);
  }

  Future<void> _handleDeleteLesson(String lessonId, String lessonTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "$lessonTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final courseProv = Provider.of<CourseProvider>(context, listen: false);
    final success = await courseProv.deleteLesson(
      courseId: widget.course.id,
      lessonId: lessonId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson deleted successfully! 🗑️'),
          backgroundColor: AppColors.emerald,
        ),
      );
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(courseProv.errorMessage ?? 'Failed to delete lesson'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  void _showAddMaterialDialog(BuildContext context, String courseId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final sizeCtrl = TextEditingController(text: '16 Slides • 3.2 MB');
    String materialType = 'slide';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Study Material / Slide', style: AppStyles.heading3.copyWith(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Material Title',
                    hintText: 'e.g. Module 01 - Architecture Slide Deck.pdf',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description / Notes',
                    hintText: 'Summary notes and practice slides',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: materialType,
                        decoration: InputDecoration(
                          labelText: 'Format',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'slide', child: Text('Slide Deck (PPT)')),
                          DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                          DropdownMenuItem(value: 'document', child: Text('Notes / Doc')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => materialType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: sizeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Size / Pages',
                          hintText: '16 Slides • 3.2 MB',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Save Study Material 📑',
                  width: double.infinity,
                  height: 48,
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;

                    final newMat = MaterialModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      type: materialType,
                      fileUrl: 'https://sample.pdf',
                      fileSize: sizeCtrl.text.trim(),
                    );

                    setState(() {
                      widget.course.materials.add(newMat);
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Study material "${newMat.title}" added successfully! 📑'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final enrollProv = Provider.of<EnrollmentProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);

    final currentCourse = (courseProv.selectedCourse != null && courseProv.selectedCourse!.id == widget.course.id)
        ? courseProv.selectedCourse!
        : widget.course;

    final isEnrolled = enrollProv.isEnrolledInCourse(currentCourse.id);
    final enrollment = enrollProv.getEnrollmentForCourse(currentCourse.id);

    final isInstructorOrAdmin = authProv.currentUser?.role == 'admin' ||
        authProv.currentUser?.role == 'teacher' ||
        (authProv.currentUser != null &&
            currentCourse.instructor != null &&
            authProv.currentUser!.id == currentCourse.instructor!.id);

    // Fallback study materials for demonstration if none added yet
    final displayMaterials = currentCourse.materials.isNotEmpty
        ? currentCourse.materials
        : [
            MaterialModel(
              id: 'm1',
              title: '${currentCourse.title} - Official Slide Deck.pdf',
              description: 'Complete slide presentation covering all theoretical & architectural concepts.',
              type: 'slide',
              fileUrl: 'https://example.com/slides.pdf',
              fileSize: '24 Slides • 4.8 MB',
            ),
            MaterialModel(
              id: 'm2',
              title: 'Masterclass Quick Cheat Sheet & Code Snippets.pdf',
              description: 'Quick reference formulas, syntax cheat-sheets, and step-by-step blueprints.',
              type: 'pdf',
              fileUrl: 'https://example.com/cheatsheet.pdf',
              fileSize: '8 Pages • 1.5 MB',
            ),
            MaterialModel(
              id: 'm3',
              title: 'Hands-on Practice Exercises & Solutions.docx',
              description: 'Curated assignments, problem sets, and interview prep questions.',
              type: 'document',
              fileUrl: 'https://example.com/exercises.docx',
              fileSize: '12 Pages • 2.1 MB',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(currentCourse.title, style: AppStyles.heading3.copyWith(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Course & Lessons',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Banner
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: currentCourse.thumbnail,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: AppColors.surfaceSubtle,
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: AppColors.surfaceSubtle,
                        child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 50),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentCourse.level,
                          style: AppStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category & Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentCourse.category.toUpperCase(),
                      style: AppStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${currentCourse.rating}',
                        style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${currentCourse.enrolledCount} enrolled)',
                        style: AppStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Description
              Text(currentCourse.title, style: AppStyles.heading2.copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              Text(currentCourse.description, style: AppStyles.bodyMedium.copyWith(height: 1.5)),
              const SizedBox(height: 20),

              // Progress Banner (If Enrolled)
              if (isEnrolled && enrollment != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppStyles.cardDecoration(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your Course Progress', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '${enrollment.progressPercentage}%',
                            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 6,
                        percent: (enrollment.progressPercentage / 100).clamp(0.0, 1.0),
                        backgroundColor: AppColors.surfaceSubtle,
                        progressColor: AppColors.primary,
                        barRadius: const Radius.circular(6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Segmented Tab Selector (Video Lessons vs Study Materials)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildTabItem(0, 'Video Lessons (${currentCourse.lessons.length})', Icons.play_circle_outline_rounded),
                    _buildTabItem(1, 'Slides & Notes (${displayMaterials.length})', Icons.slideshow_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TAB 0: VIDEO LESSONS
              if (_selectedTab == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Course Lessons (${currentCourse.lessons.length})',
                      style: AppStyles.heading3.copyWith(fontSize: 18),
                    ),
                    if (isInstructorOrAdmin)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Add Lesson', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          AddLessonDialog.show(
                            context,
                            courseId: currentCourse.id,
                            courseTitle: currentCourse.title,
                          ).then((_) => _refreshData());
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                if (currentCourse.lessons.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppStyles.cardDecoration(),
                    child: Center(
                      child: Text('No lessons uploaded for this course yet.', style: AppStyles.bodyMedium),
                    ),
                  )
                else
                  ...currentCourse.lessons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final lesson = entry.value;
                    final isCompleted = enrollment?.completedLessons.contains(lesson.id) ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppStyles.cardDecoration(),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.emerald.withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 20)
                                : Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          lesson.title,
                          style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${lesson.duration} ${lesson.isFreePreview ? '• Free Preview' : ''}',
                          style: AppStyles.caption,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isInstructorOrAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
                                tooltip: 'Delete Lesson',
                                onPressed: () => _handleDeleteLesson(lesson.id, lesson.title),
                              ),
                            const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonPlayerScreen(
                                course: currentCourse,
                                lesson: lesson,
                                isCompleted: isCompleted,
                              ),
                            ),
                          ).then((_) {
                            _refreshData();
                          });
                        },
                      ),
                    );
                  }),
              ]

              // TAB 1: STUDY MATERIALS & SLIDES
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Study Materials & Slides (${displayMaterials.length})',
                      style: AppStyles.heading3.copyWith(fontSize: 18),
                    ),
                    if (isInstructorOrAdmin)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple.withValues(alpha: 0.12),
                          foregroundColor: AppColors.purple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: const Text('Add Material', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _showAddMaterialDialog(context, currentCourse.id),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                ...displayMaterials.map((mat) => _buildMaterialCard(context, mat, currentCourse.title)),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: !isEnrolled
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Course Fee', style: AppStyles.caption),
                      Text(
                        currentCourse.price == 0 ? 'Free' : '₹${currentCourse.price.toInt()}',
                        style: AppStyles.heading2.copyWith(color: AppColors.primary, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: CustomButton(
                      text: 'Enroll Now 🎓',
                      isLoading: enrollProv.isLoading,
                      onPressed: () async {
                        final success = await enrollProv.enrollInCourse(currentCourse.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Successfully Enrolled in ${currentCourse.title}! 🚀'
                                    : enrollProv.errorMessage ?? 'Enrollment failed',
                              ),
                              backgroundColor: success ? AppColors.emerald : AppColors.coral,
                            ),
                          );
                          if (success) {
                            _refreshData();
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, MaterialModel mat, String courseTitle) {
    Color typeColor;
    IconData typeIcon;

    if (mat.type == 'slide') {
      typeColor = const Color(0xFFF97316); // Orange for Presentations / Slides
      typeIcon = Icons.slideshow_rounded;
    } else if (mat.type == 'pdf') {
      typeColor = AppColors.coral; // Red for PDFs
      typeIcon = Icons.picture_as_pdf_rounded;
    } else {
      typeColor = AppColors.primary; // Blue/Indigo for Notes
      typeIcon = Icons.description_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mat.title,
                      style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mat.description.isNotEmpty ? mat.description : 'Comprehensive lecture study resource.',
                      style: AppStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mat.type.toUpperCase(),
                            style: AppStyles.caption.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(mat.fileSize, style: AppStyles.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),

          // Action Buttons: Open & Read vs Download
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentViewerScreen(
                          material: mat,
                          courseTitle: courseTitle,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text('Open & Read Slide 📖', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () async {
                  final result = await FileDownloadService.downloadStudyMaterial(
                    material: mat,
                    courseTitle: courseTitle,
                  );
                  if (context.mounted) {
                    FileDownloadService.showDownloadFeedback(context, result);
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceSubtle,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.download_rounded, color: AppColors.textPrimary, size: 20),
                tooltip: 'Download File',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
