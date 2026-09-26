import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/planner_provider.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleItem schedule;
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isTeacher = auth.isTeacher;
    final isSelfStudy = schedule.type == 'self_study';
    final isCompleted = schedule.isCompleted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.surfaceSubtle.withValues(alpha: 0.6) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelfStudy
                ? AppColors.amber.withValues(alpha: isCompleted ? 0.2 : 0.4)
                : AppColors.primary.withValues(alpha: isCompleted ? 0.2 : 0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    schedule.time.split('-').first.trim(),
                    style: AppStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                  if (schedule.time.contains('-')) ...[
                    const SizedBox(height: 2),
                    Text(
                      schedule.time.split('-')[1].trim(),
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Color Stripe
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.textMuted : schedule.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Main Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Type Badge (Teacher Class vs Self-Study)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isSelfStudy
                              ? AppColors.amber.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isSelfStudy
                                  ? '🎯 Self Study'
                                  : (!isTeacher ? '🏛️ Official Class 🔒' : '🏛️ Teaching Class'),
                              style: TextStyle(
                                color: isSelfStudy ? AppColors.amber : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (schedule.location.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${schedule.location}',
                            style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    schedule.title,
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Instructor or Notes
                  Row(
                    children: [
                      if (!isSelfStudy) ...[
                        Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          schedule.notes.isNotEmpty ? schedule.notes : schedule.instructor,
                          style: AppStyles.caption.copyWith(
                            color: isCompleted ? AppColors.textMuted : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Trailing action / status
            if (isSelfStudy)
              InkWell(
                onTap: () {
                  Provider.of<PlannerProvider>(context, listen: false).toggleScheduleCompletion(schedule.id);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isCompleted ? AppColors.emerald : AppColors.textMuted,
                    size: 24,
                  ),
                ),
              )
            else if (schedule.isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
