import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/planner_provider.dart';

class GradeSubmissionDialog extends StatefulWidget {
  final AssignmentItem assignment;
  final StudentSubmissionItem submission;

  const GradeSubmissionDialog({
    super.key,
    required this.assignment,
    required this.submission,
  });

  static Future<bool?> show(
    BuildContext context, {
    required AssignmentItem assignment,
    required StudentSubmissionItem submission,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GradeSubmissionDialog(
        assignment: assignment,
        submission: submission,
      ),
    );
  }

  @override
  State<GradeSubmissionDialog> createState() => _GradeSubmissionDialogState();
}

class _GradeSubmissionDialogState extends State<GradeSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _scoreController;
  late TextEditingController _feedbackController;
  bool _isSubmitting = false;

  final List<String> _quickFeedbackSuggestions = [
    'Outstanding solution! Clean, well structured, and optimal. 🌟',
    'Great implementation! Good documentation and logic. 👍',
    'Good attempt. Make sure to handle edge cases properly. 💡',
    'Please review time complexity and optimize data structures. ⚠️',
    'Well documented submission with clear reasoning. ✅',
  ];

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(
      text: widget.submission.score != null
          ? (widget.submission.score! % 1 == 0
              ? widget.submission.score!.toInt().toString()
              : widget.submission.score!.toString())
          : widget.assignment.maxScore.toInt().toString(),
    );
    _feedbackController = TextEditingController(text: widget.submission.feedback);
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _applyQuickScore(double percentage) {
    final computed = (widget.assignment.maxScore * percentage);
    final text = computed % 1 == 0 ? computed.toInt().toString() : computed.toStringAsFixed(1);
    setState(() {
      _scoreController.text = text;
    });
  }

  Future<void> _handleSaveGrade() async {
    if (!_formKey.currentState!.validate()) return;

    final scoreVal = double.tryParse(_scoreController.text.trim());
    if (scoreVal == null) return;

    setState(() => _isSubmitting = true);
    final planner = Provider.of<PlannerProvider>(context, listen: false);

    final success = await planner.gradeSubmission(
      assignmentId: widget.assignment.id,
      submissionId: widget.submission.id,
      score: scoreVal,
      feedback: _feedbackController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Grade & feedback submitted for ${widget.submission.studentName}! 🌟',
            ),
            backgroundColor: AppColors.emerald,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save grade. Please try again.'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.submission;
    final maxScore = widget.assignment.maxScore;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
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
                          color: AppColors.emerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.rate_review_rounded, color: AppColors.emerald, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grade Submission', style: AppStyles.heading3.copyWith(fontSize: 18)),
                          Text(
                            widget.assignment.title,
                            style: AppStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 12),

              // Student Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(
                        sub.studentName.isNotEmpty ? sub.studentName.substring(0, 1).toUpperCase() : 'S',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub.studentName, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            sub.studentRollNo.isNotEmpty
                                ? 'Roll: ${sub.studentRollNo} • ${sub.studentEmail}'
                                : sub.studentEmail,
                            style: AppStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (sub.submittedAt != null)
                      Text(
                        DateFormat('dd MMM, hh:mm a').format(sub.submittedAt!),
                        style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),

              // Student's Submission content (File or Notes)
              if (sub.fileName.isNotEmpty || sub.submissionText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student Submission Content:', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (sub.fileName.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                sub.fileName,
                                style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      if (sub.submissionText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"${sub.submissionText}"',
                          style: AppStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Score Entry & Quick Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Score / Marks *', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  Text('Out of ${maxScore.toInt()} pts', style: AppStyles.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _scoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppStyles.heading2.copyWith(fontSize: 20, color: AppColors.emerald),
                decoration: AppStyles.inputDecoration(
                  hintText: '${maxScore.toInt()}',
                  prefixIcon: const Icon(Icons.military_tech_rounded, color: AppColors.emerald, size: 22),
                  suffixText: '/ ${maxScore.toInt()} pts',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a score';
                  final num = double.tryParse(val.trim());
                  if (num == null) return 'Invalid number';
                  if (num < 0 || num > maxScore) return 'Must be between 0 and ${maxScore.toInt()}';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Quick percentage chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildScoreChip('100%', 1.0),
                    _buildScoreChip('90%', 0.90),
                    _buildScoreChip('85%', 0.85),
                    _buildScoreChip('75%', 0.75),
                    _buildScoreChip('60%', 0.60),
                    _buildScoreChip('50%', 0.50),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Teacher Feedback / Remarks
              Text('Teacher Feedback & Remarks', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: AppStyles.inputDecoration(
                  hintText: 'Add constructive feedback, strengths, and areas to improve...',
                ),
              ),
              const SizedBox(height: 10),

              // Feedback suggestion chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickFeedbackSuggestions.map((suggestion) {
                  return ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    backgroundColor: AppColors.surfaceSubtle,
                    label: Text(
                      suggestion,
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    onPressed: () {
                      setState(() {
                        _feedbackController.text = suggestion;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSaveGrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Submitting Grade...' : 'Save & Publish Grade ✨',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChip(String label, double pct) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          side: BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _applyQuickScore(pct),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ),
    );
  }
}
