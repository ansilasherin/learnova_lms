import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/file_download_service.dart';
import 'create_assignment_dialog.dart';
import 'student_submit_dialog.dart';
import 'teacher_submissions_modal.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlannerProvider>(context, listen: false).fetchAcademicData();
    });
  }

  Future<void> _handleDownloadBrief(AssignmentItem item) async {
    final result = await FileDownloadService.downloadAssignmentBrief(assignment: item);
    if (mounted) {
      FileDownloadService.showDownloadFeedback(context, result);
    }
  }

  Future<void> _handleDeleteAssignment(AssignmentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment?'),
        content: Text('Are you sure you want to delete "${item.title}" and all its student submissions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final planner = Provider.of<PlannerProvider>(context, listen: false);
      final success = await planner.deleteAssignment(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Assignment deleted 🗑️' : 'Failed to delete assignment'),
            backgroundColor: success ? AppColors.emerald : AppColors.coral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final planner = Provider.of<PlannerProvider>(context);
    final isTeacher = auth.isTeacher;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isTeacher ? 'Teacher Task & Evaluation Studio' : 'Assignments & Tasks', style: AppStyles.heading3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: () => planner.fetchAcademicData(),
          ),
        ],
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => CreateAssignmentDialog.show(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Create Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => planner.fetchAcademicData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTeacher) ...[
                _buildTeacherSummaryHeader(planner),
                const SizedBox(height: 18),
                _buildTeacherTabs(planner),
                const SizedBox(height: 16),
                _buildTeacherAssignmentsList(planner),
              ] else ...[
                _buildStudentTabs(planner),
                const SizedBox(height: 16),
                _buildStudentAssignmentsList(planner),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TEACHER VIEW COMPONENTS
  // ==========================================

  Widget _buildTeacherSummaryHeader(PlannerProvider planner) {
    final totalAssignments = planner.assignments.length;
    final totalSubmissions = planner.assignments.fold<int>(0, (sum, a) => sum + a.totalSubmissions);
    final totalGraded = planner.assignments.fold<int>(0, (sum, a) => sum + a.gradedCount);
    final totalPending = totalSubmissions - totalGraded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.assessment_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Evaluation Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => CreateAssignmentDialog.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTeacherMetricBox('Tasks', '$totalAssignments', Icons.assignment_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTeacherMetricBox('Submissions', '$totalSubmissions', Icons.inbox_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTeacherMetricBox('Needs Review', '$totalPending', Icons.pending_actions_rounded, highlight: totalPending > 0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTeacherMetricBox('Graded', '$totalGraded', Icons.check_circle_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherMetricBox(String title, String value, IconData icon, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? Colors.amber.withOpacity(0.25) : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: highlight ? Border.all(color: Colors.amber, width: 1.2) : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: highlight ? Colors.amberAccent : Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 9, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherTabs(PlannerProvider planner) {
    final totalAssignments = planner.assignments.length;
    final needsGradingCount = planner.assignments.where((a) => a.pendingCount > 0).length;
    final gradedCount = planner.assignments.where((a) => a.gradedCount > 0).length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'All Tasks ($totalAssignments)'),
          _buildTabItem(1, 'Needs Grading ($needsGradingCount)'),
          _buildTabItem(2, 'Graded ($gradedCount)'),
        ],
      ),
    );
  }

  Widget _buildTeacherAssignmentsList(PlannerProvider planner) {
    List<AssignmentItem> list;
    if (_selectedTab == 1) {
      list = planner.assignments.where((a) => a.pendingCount > 0).toList();
    } else if (_selectedTab == 2) {
      list = planner.assignments.where((a) => a.gradedCount > 0).toList();
    } else {
      list = planner.assignments;
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                _selectedTab == 1 ? 'No submissions awaiting grading! 🎉' : 'No assignments found',
                style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedTab == 1
                    ? 'All student submissions are graded and up to date.'
                    : 'Click "Create Assignment" to assign coursework.',
                style: AppStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: list.map((a) => _buildTeacherAssignmentCard(planner, a)).toList(),
    );
  }

  Widget _buildTeacherAssignmentCard(PlannerProvider planner, AssignmentItem item) {
    Color priorityColor;
    if (item.priority == 'High Priority') {
      priorityColor = AppColors.coral;
    } else if (item.priority == 'Medium Priority') {
      priorityColor = AppColors.amber;
    } else {
      priorityColor = AppColors.cyan;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Subject, Priority & Delete Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.subject,
                  style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.priority,
                      style: AppStyles.caption.copyWith(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => _handleDeleteAssignment(item),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete Assignment',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Assignment Title
          Text(item.title, style: AppStyles.heading3.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(item.dueDate, style: AppStyles.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(width: 12),
              const Icon(Icons.stars_rounded, size: 14, color: AppColors.amber),
              const SizedBox(width: 4),
              Text('Max: ${item.maxScore.toInt()} pts', style: AppStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),

          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.description, style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],

          const SizedBox(height: 12),

          // Submissions Status Pill Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${item.totalSubmissions} Submissions',
                      style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (item.pendingCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.pendingCount} Needs Review',
                          style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (item.gradedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.gradedCount} Graded',
                          style: const TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Graded Submissions Expansion Summary if any graded
          if (item.gradedCount > 0) ...[
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  leading: const Icon(Icons.military_tech_rounded, color: AppColors.emerald, size: 20),
                  title: Text(
                    'Graded Submissions (${item.gradedCount} Evaluated)',
                    style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.emerald),
                  ),
                  subtitle: Text(
                    'Tap to preview evaluated student grades',
                    style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                  ),
                  children: [
                    Divider(color: AppColors.divider),
                    const SizedBox(height: 4),
                    ...item.submissions.where((s) => s.status == 'graded').map((sub) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sub.studentName,
                                  style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${sub.score?.toStringAsFixed(sub.score! % 1 == 0 ? 0 : 1)}/${sub.maxScore.toInt()} pts',
                                  style: const TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Action Buttons: View & Grade Submissions & Brief
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text('Brief 📄', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _handleDownloadBrief(item),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.pendingCount > 0 ? AppColors.primary : AppColors.emerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.rate_review_rounded, size: 16),
                label: Text(
                  item.totalSubmissions == 0
                      ? 'No Submissions Yet'
                      : 'Review & Grade (${item.totalSubmissions}) ✍️',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  TeacherSubmissionsModal.show(context, item);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STUDENT VIEW COMPONENTS
  // ==========================================

  Widget _buildStudentTabs(PlannerProvider planner) {
    final pendingCount = planner.assignments.where((a) => a.status == 'pending').length;
    final submittedCount = planner.assignments.where((a) => a.status == 'submitted').length;
    final gradedCount = planner.assignments.where((a) => a.status == 'graded' || a.score != null).length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Pending ($pendingCount)'),
          _buildTabItem(1, 'Submitted ($submittedCount)'),
          _buildTabItem(2, 'Graded ($gradedCount)'),
        ],
      ),
    );
  }

  Widget _buildStudentAssignmentsList(PlannerProvider planner) {
    List<AssignmentItem> filtered;
    if (_selectedTab == 0) {
      filtered = planner.assignments.where((a) => a.status == 'pending').toList();
    } else if (_selectedTab == 1) {
      filtered = planner.assignments.where((a) => a.status == 'submitted').toList();
    } else {
      filtered = planner.assignments.where((a) => a.status == 'graded' || a.score != null).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                _selectedTab == 2 ? Icons.military_tech_outlined : Icons.assignment_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text('No assignments in this category', style: AppStyles.bodyLarge),
              const SizedBox(height: 4),
              Text(
                _selectedTab == 0 ? 'All pending tasks completed! 🎉' : 'Assignments will appear here.',
                style: AppStyles.caption,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((a) => _buildStudentAssignmentCard(planner, a)).toList(),
    );
  }

  Widget _buildStudentAssignmentCard(PlannerProvider planner, AssignmentItem item) {
    Color priorityColor;
    if (item.priority == 'High Priority') {
      priorityColor = AppColors.coral;
    } else if (item.priority == 'Medium Priority') {
      priorityColor = AppColors.amber;
    } else {
      priorityColor = AppColors.cyan;
    }

    final isPending = item.status == 'pending';
    final isGraded = item.status == 'graded' || item.score != null;
    final isSubmitted = item.status == 'submitted';

    // Status icon and color
    IconData statusIcon;
    Color statusColor;
    String statusLabel;

    if (isGraded) {
      statusIcon = Icons.verified_rounded;
      statusColor = AppColors.emerald;
      statusLabel = '${item.score?.toStringAsFixed(item.score! % 1 == 0 ? 0 : 1)}/${item.maxScore.toInt()} pts';
    } else if (isSubmitted) {
      statusIcon = Icons.mark_email_read_rounded;
      statusColor = AppColors.amber;
      statusLabel = 'Submitted ⏳';
    } else {
      statusIcon = Icons.assignment_outlined;
      statusColor = priorityColor;
      statusLabel = item.priority.replaceAll(' Priority', '');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGraded
              ? AppColors.emerald.withValues(alpha: 0.35)
              : isSubmitted
                  ? AppColors.amber.withValues(alpha: 0.35)
                  : AppColors.cardBorder,
          width: isGraded || isSubmitted ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isGraded
                ? AppColors.emerald.withValues(alpha: 0.04)
                : isSubmitted
                    ? AppColors.amber.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          title: Text(
            item.title,
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.subject,
                    style: AppStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('•', style: AppStyles.caption),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Due: ${item.dueDate}',
                    style: AppStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textSecondary),
            ],
          ),
          children: [
            Divider(color: AppColors.divider),
            const SizedBox(height: 8),

            // Metadata row: Due Date, Priority, Max Score
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('Due ${item.dueDate}', style: AppStyles.caption.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.priority,
                    style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, size: 14, color: AppColors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Max: ${item.maxScore.toInt()} pts',
                      style: AppStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),

            // Description
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('Task Overview / Instructions:', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: AppStyles.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 1. If GRADED: Show Evaluation Breakdown & Teacher Remarks
            if (isGraded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score Gauge & Rubric Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded, color: AppColors.emerald, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Graded Evaluation', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.emerald)),
                                Text(
                                  'Score: ${item.score?.toStringAsFixed(item.score! % 1 == 0 ? 0 : 1)} / ${item.maxScore.toInt()} pts',
                                  style: AppStyles.heading3.copyWith(color: AppColors.emerald, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.military_tech_rounded, color: AppColors.emerald, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                ((item.score ?? 0) / (item.maxScore > 0 ? item.maxScore : 100)) >= 0.9
                                    ? 'Grade: A+ (Outstanding)'
                                    : (((item.score ?? 0) / (item.maxScore > 0 ? item.maxScore : 100)) >= 0.75
                                        ? 'Grade: A (Very Good)'
                                        : 'Grade: B (Completed)'),
                                style: const TextStyle(
                                  color: AppColors.emerald,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Teacher's Feedback Remarks
                    if (item.feedback != null && item.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: AppColors.emerald),
                                const SizedBox(width: 6),
                                Text(
                                  "Teacher's Remarks:",
                                  style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.emerald),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"${item.feedback}"',
                              style: AppStyles.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Student's submitted work if available
                    if (item.fileName != null && item.fileName!.isNotEmpty ||
                        item.submissionText != null && item.submissionText!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.fileName != null && item.fileName!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Submitted File: ${item.fileName}',
                                      style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (item.submissionText != null && item.submissionText!.isNotEmpty) ...[
                              if (item.fileName != null && item.fileName!.isNotEmpty) const SizedBox(height: 4),
                              Text(
                                'Your Note: "${item.submissionText}"',
                                style: AppStyles.caption.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ]
            // 2. If SUBMITTED (Under Review): Show Submitted Work & Status
            else if (isSubmitted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_read_rounded, color: AppColors.amber, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Submitted • Awaiting Teacher Evaluation', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                              if (item.submittedAt != null)
                                Text(
                                  'Submitted on ${DateFormat('dd MMM yyyy, hh:mm a').format(item.submittedAt!)}',
                                  style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Submitted file/text preview
                    if (item.fileName != null && item.fileName!.isNotEmpty ||
                        item.submissionText != null && item.submissionText!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.fileName != null && item.fileName!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_outlined, size: 15, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.fileName!,
                                      style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Attached 📎', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            if (item.submissionText != null && item.submissionText!.isNotEmpty) ...[
                              if (item.fileName != null && item.fileName!.isNotEmpty) const SizedBox(height: 4),
                              Text(
                                'Note: "${item.submissionText}"',
                                style: AppStyles.caption.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ]
            // 3. If PENDING: Show Progress Bar & Submission Call-to-action
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '${item.progress}%',
                    style: AppStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearPercentIndicator(
                padding: EdgeInsets.zero,
                lineHeight: 6,
                percent: (item.progress / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceSubtle,
                progressColor: priorityColor,
                barRadius: const Radius.circular(6),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons: Download Brief & Submit/Edit Solution
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: const Text('Brief 📄', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _handleDownloadBrief(item),
                ),
                if (isPending)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Submit Solution 📤', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => StudentSubmitDialog.show(context, item),
                  )
                else if (isSubmitted)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceSubtle,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Update Work ✏️', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => StudentSubmitDialog.show(context, item),
                  )
                else if (isGraded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          'Evaluated & Recorded 🌟',
                          style: AppStyles.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
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
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
