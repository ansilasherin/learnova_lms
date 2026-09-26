import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/planner_provider.dart';
import 'grade_submission_dialog.dart';

class TeacherSubmissionsModal extends StatefulWidget {
  final AssignmentItem assignment;

  const TeacherSubmissionsModal({
    super.key,
    required this.assignment,
  });

  static Future<void> show(BuildContext context, AssignmentItem assignment) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TeacherSubmissionsModal(assignment: assignment),
    );
  }

  @override
  State<TeacherSubmissionsModal> createState() => _TeacherSubmissionsModalState();
}

class _TeacherSubmissionsModalState extends State<TeacherSubmissionsModal> {
  int _filterIndex = 0; // 0: All, 1: Needs Review, 2: Graded

  @override
  Widget build(BuildContext context) {
    final planner = Provider.of<PlannerProvider>(context);
    // Locate the latest version of this assignment from provider
    final currentAssignment = planner.assignments.firstWhere(
      (a) => a.id == widget.assignment.id,
      orElse: () => widget.assignment,
    );

    final submissions = currentAssignment.submissions;

    List<StudentSubmissionItem> filtered;
    if (_filterIndex == 1) {
      filtered = submissions.where((s) => s.status != 'graded').toList();
    } else if (_filterIndex == 2) {
      filtered = submissions.where((s) => s.status == 'graded').toList();
    } else {
      filtered = submissions;
    }

    final pendingCount = submissions.where((s) => s.status != 'graded').length;
    final gradedCount = submissions.where((s) => s.status == 'graded').length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 18, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAssignment.title,
                      style: AppStyles.heading3.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currentAssignment.subject} • ${currentAssignment.dueDate}',
                      style: AppStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),

          // Quick Filter Segmented Buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildFilterTab(0, 'All (${submissions.length})'),
                _buildFilterTab(1, 'Needs Review ($pendingCount)'),
                _buildFilterTab(2, 'Graded ($gradedCount)'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Submissions List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _filterIndex == 1
                                ? Icons.task_alt_rounded
                                : Icons.people_outline_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filterIndex == 1
                                ? 'All submissions reviewed! 🎉'
                                : 'No submissions in this category',
                            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _filterIndex == 1
                                ? 'No pending tasks left to grade.'
                                : 'Students will appear here once they turn in work.',
                            style: AppStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sub = filtered[index];
                      return _buildSubmissionCard(context, currentAssignment, sub);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String title) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filterIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildSubmissionCard(
    BuildContext context,
    AssignmentItem assignment,
    StudentSubmissionItem sub,
  ) {
    final isGraded = sub.status == 'graded';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGraded ? AppColors.emerald.withValues(alpha: 0.35) : AppColors.cardBorder,
            width: isGraded ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isGraded
                  ? AppColors.emerald.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          initiallyExpanded: !isGraded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: isGraded
                ? AppColors.emerald.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              sub.studentName.isNotEmpty ? sub.studentName.substring(0, 1).toUpperCase() : 'S',
              style: TextStyle(
                color: isGraded ? AppColors.emerald : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            sub.studentName,
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sub.studentRollNo.isNotEmpty ? 'Roll: ${sub.studentRollNo}' : sub.studentEmail,
                    style: AppStyles.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isGraded
                        ? AppColors.emerald.withValues(alpha: 0.12)
                        : AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGraded ? Icons.verified_rounded : Icons.pending_actions_rounded,
                        size: 12,
                        color: isGraded ? AppColors.emerald : AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isGraded
                            ? '${sub.score?.toStringAsFixed(sub.score! % 1 == 0 ? 0 : 1)}/${sub.maxScore.toInt()} pts'
                            : 'Needs Review',
                        style: TextStyle(
                          color: isGraded ? AppColors.emerald : AppColors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          children: [
            Divider(color: AppColors.divider),
            const SizedBox(height: 6),

            // Submission timestamp
            if (sub.submittedAt != null) ...[
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted on ${DateFormat('dd MMM yyyy, hh:mm a').format(sub.submittedAt!)}',
                    style: AppStyles.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Student work / file attachment details
            if (sub.fileName.isNotEmpty || sub.submissionText.isNotEmpty) ...[
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
                    if (sub.fileName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sub.fileName,
                              style: AppStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
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
                    if (sub.submissionText.isNotEmpty) ...[
                      if (sub.fileName.isNotEmpty) const SizedBox(height: 6),
                      Text(
                        'Student Notes: "${sub.submissionText}"',
                        style: AppStyles.caption.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // If Graded: Show Score Rubric & Teacher Feedback Remarks
            if (isGraded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.military_tech_rounded, color: AppColors.emerald, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Score: ${sub.score?.toStringAsFixed(sub.score! % 1 == 0 ? 0 : 1)} / ${sub.maxScore.toInt()} pts',
                              style: AppStyles.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '${((sub.score ?? 0) / (sub.maxScore > 0 ? sub.maxScore : 100) * 100).toInt()}%',
                          style: AppStyles.heading3.copyWith(color: AppColors.emerald, fontSize: 14),
                        ),
                      ],
                    ),
                    if (sub.feedback.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Feedback: "${sub.feedback}"',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.emerald,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Action Button Row
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  GradeSubmissionDialog.show(
                    context,
                    assignment: assignment,
                    submission: sub,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGraded ? AppColors.surfaceSubtle : AppColors.primary,
                  foregroundColor: isGraded ? AppColors.primary : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isGraded ? const BorderSide(color: AppColors.primary, width: 1) : BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: Icon(
                  isGraded ? Icons.edit_note_rounded : Icons.rate_review_rounded,
                  size: 16,
                ),
                label: Text(
                  isGraded ? 'Edit Evaluation ✏️' : 'Grade Submission ✍️',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
