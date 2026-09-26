import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/cards/schedule_card.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  String _selectedDate = '14';
  int _selectedCategoryTab = 0; // For Student: 0: All, 1: Teacher Classes, 2: Self Study. For Teacher: 0: All Classes, 1: Live Sessions

  // ==========================================
  // TEACHER-SPECIFIC MODAL: SCHEDULE A CLASS
  // ==========================================
  void _showTeacherAddClassSheet(BuildContext context, String teacherName) {
    final titleController = TextEditingController();
    final instructorController = TextEditingController(text: teacherName.isNotEmpty ? teacherName : 'Prof. Teacher');
    final locationController = TextEditingController(text: 'Lecture Hall 201');
    final timeController = TextEditingController(text: '10:00 AM - 11:30 AM');
    final durationController = TextEditingController(text: '1.5 hrs');
    Color selectedColor = AppColors.primary;
    bool isLive = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 22,
            left: 20,
            right: 20,
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Schedule Class Session', style: AppStyles.heading3.copyWith(fontSize: 17)),
                            Text('Add official lecture to student timetable', style: AppStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),

                // Subject / Course Name
                CustomTextField(
                  controller: titleController,
                  label: 'Subject / Course Name',
                  hint: 'e.g. Database Management Systems',
                  prefixIcon: Icons.school_rounded,
                ),
                const SizedBox(height: 14),

                // Instructor Name (Auto-filled)
                CustomTextField(
                  controller: instructorController,
                  label: 'Professor / Instructor',
                  hint: 'e.g. Prof. Mehta',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),

                // Hall / Room
                CustomTextField(
                  controller: locationController,
                  label: 'Lecture Hall / Lab Room',
                  hint: 'e.g. Hall 201 / CS Lab A',
                  prefixIcon: Icons.room_outlined,
                ),
                const SizedBox(height: 14),

                // Live class toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.sensors_rounded, color: AppColors.emerald, size: 20),
                          SizedBox(width: 8),
                          Text('Live Lecture Session', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      Switch.adaptive(
                        value: isLive,
                        activeTrackColor: AppColors.emerald,
                        onChanged: (val) => setModalState(() => isLive = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Time Slot & Duration
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: timeController,
                        label: 'Time Slot',
                        hint: '10:00 AM - 11:30 AM',
                        prefixIcon: Icons.access_time_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: durationController,
                        label: 'Duration',
                        hint: '1.5 hrs',
                        prefixIcon: Icons.timer_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tag Color Selection
                Text('Class Tag Color', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppColors.primary,
                    AppColors.emerald,
                    AppColors.amber,
                    AppColors.coral,
                    AppColors.purple,
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: AppColors.textPrimary, width: 2.5) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Submit Button
                CustomButton(
                  text: 'Publish Class Schedule 🏛️',
                  width: double.infinity,
                  height: 48,
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a subject name'), backgroundColor: AppColors.coral),
                      );
                      return;
                    }

                    final newSchedule = ScheduleItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      instructor: instructorController.text.trim().isNotEmpty ? instructorController.text.trim() : teacherName,
                      time: timeController.text.trim(),
                      duration: durationController.text.trim(),
                      isLive: isLive,
                      color: selectedColor,
                      type: 'class',
                      location: locationController.text.trim(),
                    );

                    Provider.of<PlannerProvider>(context, listen: false).addSchedule(newSchedule);
                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Class "${newSchedule.title}" scheduled for students! 🏛️'),
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

  // ==========================================
  // STUDENT-SPECIFIC MODAL: ADD SELF-STUDY GOAL
  // ==========================================
  void _showStudentAddSelfStudySheet(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final timeController = TextEditingController(text: '06:00 PM - 07:30 PM');
    final durationController = TextEditingController(text: '1.5 hrs');
    Color selectedColor = AppColors.amber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 22,
            left: 20,
            right: 20,
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.track_changes_rounded, color: AppColors.amber, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Self-Study Goal', style: AppStyles.heading3.copyWith(fontSize: 17)),
                            Text('Plan your personal revision routine', style: AppStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),

                // Subject / Self-Study Goal
                CustomTextField(
                  controller: titleController,
                  label: 'Subject / Revision Goal',
                  hint: 'e.g. Algorithms Revision / LeetCode Practice',
                  prefixIcon: Icons.menu_book_rounded,
                ),
                const SizedBox(height: 14),

                // Specific Study Notes / Targets
                CustomTextField(
                  controller: notesController,
                  label: 'Focus Notes & Targets',
                  hint: 'e.g. Solve 3 Binary Search Tree questions, review slides',
                  prefixIcon: Icons.edit_note_rounded,
                ),
                const SizedBox(height: 14),

                // Time Slot & Duration
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: timeController,
                        label: 'Study Time Slot',
                        hint: '06:00 PM - 07:30 PM',
                        prefixIcon: Icons.access_time_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: durationController,
                        label: 'Duration',
                        hint: '1.5 hrs',
                        prefixIcon: Icons.timer_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tag Color Selection
                Text('Goal Color', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppColors.amber,
                    AppColors.emerald,
                    AppColors.primary,
                    AppColors.coral,
                    AppColors.purple,
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: AppColors.textPrimary, width: 2.5) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Submit Button
                CustomButton(
                  text: 'Add to My Study Plan 🎯',
                  width: double.infinity,
                  height: 48,
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a revision goal title'), backgroundColor: AppColors.coral),
                      );
                      return;
                    }

                    final newSchedule = ScheduleItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      instructor: 'Self Study',
                      time: timeController.text.trim(),
                      duration: durationController.text.trim(),
                      isLive: false,
                      color: selectedColor,
                      type: 'self_study',
                      notes: notesController.text.trim(),
                    );

                    Provider.of<PlannerProvider>(context, listen: false).addSchedule(newSchedule);
                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${newSchedule.title}" to your study plan! 🎯'),
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

  // ==========================================
  // DETAIL MODAL: VIEW LECTURE / SESSION INFO
  // ==========================================
  void _showClassDetailsSheet(BuildContext context, ScheduleItem schedule, bool isTeacher) {
    final isClass = schedule.type == 'class';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClass ? AppColors.primary.withValues(alpha: 0.12) : AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isClass ? Icons.school_rounded : Icons.track_changes_rounded,
                        color: isClass ? AppColors.primary : AppColors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isClass ? (!isTeacher ? 'Official Class (Read Only 🔒)' : 'Teaching Lecture') : 'Personal Study Goal',
                        style: TextStyle(
                          color: isClass ? AppColors.primary : AppColors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(schedule.title, style: AppStyles.heading2.copyWith(fontSize: 20)),
            const SizedBox(height: 8),

            // Time & Duration
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(schedule.time, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('(${schedule.duration})', style: AppStyles.caption),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 14),

            if (isClass) ...[
              // Instructor & Location info
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Instructor: ', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  Text(schedule.instructor, style: AppStyles.bodyMedium),
                ],
              ),
              if (schedule.location.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.room_outlined, size: 18, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Text('Location: ', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                    Text(schedule.location, style: AppStyles.bodyMedium),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(schedule.isLive ? Icons.sensors_rounded : Icons.offline_bolt_outlined, size: 18, color: schedule.isLive ? AppColors.emerald : AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text('Status: ', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  Text(schedule.isLive ? 'Live Interactive Session' : 'Scheduled Offline Lecture', style: AppStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        !isTeacher
                            ? 'This lecture is published by your professor. It will automatically update in your timetable.'
                            : 'This lecture is visible to all enrolled students on their class timetable.',
                        style: AppStyles.caption.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Self-Study Notes
              Text('Focus Notes & Targets', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                schedule.notes.isNotEmpty ? schedule.notes : 'No specific focus notes attached.',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final planner = Provider.of<PlannerProvider>(context);
    final isTeacher = auth.isTeacher;
    final userName = auth.currentUser?.name ?? '';

    final totalClassesCount = planner.teacherClasses.length;
    final liveClassesCount = planner.teacherClasses.where((s) => s.isLive).length;
    final totalSelfStudyCount = planner.selfStudyTasks.length;
    final completedSelfStudyCount = planner.selfStudyTasks.where((s) => s.isCompleted).length;

    // Filter schedules according to role & selected tab
    List<ScheduleItem> displayedSchedules;
    if (isTeacher) {
      // Teachers only see their classes
      if (_selectedCategoryTab == 1) {
        displayedSchedules = planner.teacherClasses.where((s) => s.isLive).toList();
      } else {
        displayedSchedules = planner.teacherClasses;
      }
    } else {
      // Students see classes (read-only) + their own self-study tasks
      if (_selectedCategoryTab == 1) {
        displayedSchedules = planner.teacherClasses;
      } else if (_selectedCategoryTab == 2) {
        displayedSchedules = planner.selfStudyTasks;
      } else {
        displayedSchedules = planner.schedules;
      }
    }

    // Week dates
    final days = [
      {'day': 'SUN', 'date': '13'},
      {'day': 'MON', 'date': '14'},
      {'day': 'TUE', 'date': '15'},
      {'day': 'WED', 'date': '16'},
      {'day': 'THU', 'date': '17'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isTeacher ? 'Teaching Timetable' : 'Study Planner & Timetable',
          style: AppStyles.heading3,
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isTeacher) {
            _showTeacherAddClassSheet(context, userName);
          } else {
            _showStudentAddSelfStudySheet(context);
          }
        },
        backgroundColor: isTeacher ? AppColors.primary : AppColors.amber,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(isTeacher ? Icons.add_rounded : Icons.add_task_rounded, size: 22),
        label: Text(
          isTeacher ? 'Schedule Class 🏛️' : 'Add Self-Study 🎯',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal Week Days Strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((item) {
                final isSelected = item['date'] == _selectedDate;
                return InkWell(
                  onTap: () => setState(() => _selectedDate = item['date']!),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          item['day']!,
                          style: AppStyles.caption.copyWith(
                            color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['date']!,
                          style: AppStyles.heading3.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Role-Specific Overview Metric Summary Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isTeacher ? AppColors.purple : AppColors.primary,
                    isTeacher ? AppColors.primary : AppColors.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (isTeacher ? AppColors.purple : AppColors.primary).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              isTeacher ? 'My Teaching Classes' : 'Teacher Classes',
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$totalClassesCount Lectures', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.white24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isTeacher ? Icons.sensors_rounded : Icons.track_changes_rounded, color: Colors.amberAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              isTeacher ? 'Live Broadcasts' : 'Self-Study Routine',
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTeacher ? '$liveClassesCount Active Sessions' : '$completedSelfStudyCount/$totalSelfStudyCount Done',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Role-Specific Filter Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: isTeacher
                    ? [
                        _buildTabItem(0, 'All Classes ($totalClassesCount)'),
                        _buildTabItem(1, '🔴 Live ($liveClassesCount)'),
                      ]
                    : [
                        _buildTabItem(0, 'All (${planner.schedules.length})'),
                        _buildTabItem(1, '🏛️ Classes ($totalClassesCount)'),
                        _buildTabItem(2, '🎯 Self Study ($totalSelfStudyCount)'),
                      ],
              ),
            ),
            const SizedBox(height: 16),

            // Schedule List Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTeacher
                      ? (_selectedCategoryTab == 1 ? 'Live Lecture Sessions' : 'Your Teaching Timetable')
                      : (_selectedCategoryTab == 1
                          ? 'Teacher Lectures (Official Timetable)'
                          : _selectedCategoryTab == 2
                              ? 'Personal Self-Study Goals'
                              : "Today's Schedule & Routine"),
                  style: AppStyles.heading3.copyWith(fontSize: 15),
                ),
                Text(
                  '${displayedSchedules.length} Items',
                  style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Schedule Cards List with Dismissible
            if (displayedSchedules.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: AppStyles.cardDecoration(),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        isTeacher || _selectedCategoryTab == 1 ? Icons.school_outlined : Icons.self_improvement_rounded,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isTeacher
                            ? 'No classes scheduled for this day.'
                            : (_selectedCategoryTab == 1
                                ? 'No official classes scheduled for this day.'
                                : _selectedCategoryTab == 2
                                    ? 'No self-study goals added yet.'
                                    : 'No schedule items for today.'),
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTeacher
                            ? 'Tap "Schedule Class" to add a lecture session.'
                            : 'Tap "Add Self-Study" to plan your personal revision.',
                        style: AppStyles.caption,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...displayedSchedules.map(
                (schedule) {
                  final isTeacherClass = schedule.type == 'class';
                  // Only teachers can delete official classes. Students can only delete their self-study tasks.
                  final canDelete = isTeacher ? isTeacherClass : !isTeacherClass;

                  return Dismissible(
                    key: Key(schedule.id),
                    direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      if (!canDelete) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Official teacher classes cannot be deleted by students 🔒 (View Only)'),
                            backgroundColor: AppColors.coral,
                          ),
                        );
                        return false;
                      }
                      return true;
                    },
                    onDismissed: (_) {
                      planner.removeSchedule(schedule.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "${schedule.title}"'),
                          backgroundColor: AppColors.coral,
                        ),
                      );
                    },
                    child: ScheduleCard(
                      schedule: schedule,
                      onTap: () => _showClassDetailsSheet(context, schedule, isTeacher),
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isSelected = _selectedCategoryTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
          child: Center(
            child: Text(
              title,
              style: AppStyles.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
