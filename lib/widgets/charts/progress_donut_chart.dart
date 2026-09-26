import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class ProgressDonutChart extends StatelessWidget {
  final int overallProgress;
  final int completedPercent;
  final int inProgressPercent;
  final int notStartedPercent;

  const ProgressDonutChart({
    super.key,
    this.overallProgress = 72,
    this.completedPercent = 72,
    this.inProgressPercent = 20,
    this.notStartedPercent = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.donut_large_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Learning Progress', style: AppStyles.heading3.copyWith(fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('This Week', style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 48,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            color: AppColors.primary,
                            value: completedPercent.toDouble(),
                            title: '',
                            radius: 16,
                          ),
                          PieChartSectionData(
                            color: AppColors.amber,
                            value: inProgressPercent.toDouble(),
                            title: '',
                            radius: 16,
                          ),
                          PieChartSectionData(
                            color: AppColors.cardBorder,
                            value: notStartedPercent.toDouble(),
                            title: '',
                            radius: 16,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$overallProgress%',
                          style: AppStyles.heading2.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Overall Progress',
                          style: AppStyles.caption.copyWith(fontSize: 9, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Completed', '$completedPercent%', AppColors.primary),
                    const SizedBox(height: 12),
                    _buildLegendItem('In Progress', '$inProgressPercent%', AppColors.amber),
                    const SizedBox(height: 12),
                    _buildLegendItem('Not Started', '$notStartedPercent%', AppColors.cardBorder),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
