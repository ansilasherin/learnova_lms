import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final int? progressPercentage;
  final VoidCallback onTap;
  final bool isCompact;

  const CourseCard({
    super.key,
    required this.course,
    this.progressPercentage,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppStyles.cardDecoration(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: course.thumbnail,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceSubtle,
                      child: const Center(child: Icon(Icons.school, color: AppColors.primaryLight)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceSubtle,
                      child: const Icon(Icons.school, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course.instructor?.name ?? 'Prof. Mehta',
                        style: AppStyles.caption,
                      ),
                      if (progressPercentage != null) ...[
                        const SizedBox(height: 6),
                        LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 5,
                          percent: (progressPercentage! / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.surfaceSubtle,
                          progressColor: AppColors.primary,
                          barRadius: const Radius.circular(6),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (progressPercentage != null)
                  Text(
                    '$progressPercentage%',
                    style: AppStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      );
    }

    // Full Card
    return Container(
      decoration: AppStyles.cardDecoration(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: course.thumbnail,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 140,
                      color: AppColors.surfaceSubtle,
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 140,
                      color: AppColors.surfaceSubtle,
                      child: const Center(child: Icon(Icons.school_rounded, color: AppColors.primary, size: 40)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.level,
                        style: AppStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.category.toUpperCase(),
                      style: AppStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.heading3.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toString(),
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${course.lessons.length} Lessons',
                            style: AppStyles.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        course.price == 0 ? 'Free' : '₹${course.price.toInt()}',
                        style: AppStyles.heading3.copyWith(
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
