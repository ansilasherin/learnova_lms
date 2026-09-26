import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final planner = Provider.of<PlannerProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Grades', style: AppStyles.heading3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPA Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppStyles.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GPA', style: AppStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                      const Icon(Icons.star_rounded, color: AppColors.emerald, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${planner.gpa}', style: AppStyles.heading1.copyWith(fontSize: 32, fontWeight: FontWeight.w900)),
                      Text(' / 10', style: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                  Text('Excellent!', style: AppStyles.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Weekly Bar Chart
                  SizedBox(
                    height: 120,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (val.toInt() >= 0 && val.toInt() < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      days[val.toInt()],
                                      style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          _buildBarGroup(0, 7),
                          _buildBarGroup(1, 8.5),
                          _buildBarGroup(2, 6.5),
                          _buildBarGroup(3, 9),
                          _buildBarGroup(4, 8),
                          _buildBarGroup(5, 7.5),
                          _buildBarGroup(6, 9.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Subjects Breakdown
            Text('Subjects', style: AppStyles.heading3.copyWith(fontSize: 18)),
            const SizedBox(height: 14),

            ...planner.grades.map((grade) => _buildGradeItem(context, grade)),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: 14,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildGradeItem(BuildContext context, GradeItem grade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyles.cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.emerald, size: 20),
              ),
              title: Text(
                grade.subject,
                style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                'Tap to view score breakdown',
                style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      grade.grade,
                      style: AppStyles.caption.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${grade.score}',
                    style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              children: [
                Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubGradeMetric('Assignments', '95%', Icons.assignment_turned_in_rounded),
                    _buildSubGradeMetric('Mid-Terms', '92%', Icons.quiz_rounded),
                    _buildSubGradeMetric('Practicals', '96%', Icons.biotech_rounded),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.verified_rounded, size: 14, color: AppColors.emerald),
                          SizedBox(width: 6),
                          Text('Status: Passed with Distinction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text('Credits: 4.0', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildSubGradeMetric(String label, String score, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(height: 4),
        Text(score, style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}
