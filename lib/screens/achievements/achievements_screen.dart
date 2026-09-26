import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/dialogs/celebration_dialog.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final planner = Provider.of<PlannerProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Achievements', style: AppStyles.heading3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppStyles.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Achievements', style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('12', style: AppStyles.heading1.copyWith(fontSize: 28)),
                              Text(' / 20', style: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                          Text('Completed', style: AppStyles.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      // Trophy trigger button
                      InkWell(
                        onTap: () {
                          CelebrationDialog.show(
                            context,
                            studentName: user?.name ?? 'Ananya',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: AppColors.amber, size: 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Circular Icons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMilestoneIcon(Icons.local_fire_department_rounded, AppColors.amber),
                      _buildMilestoneIcon(Icons.auto_stories_rounded, AppColors.pink),
                      _buildMilestoneIcon(Icons.psychology_rounded, AppColors.cyan),
                      _buildMilestoneIcon(Icons.military_tech_rounded, AppColors.emerald),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Recent Badges
            Text('Recent Badges', style: AppStyles.heading3.copyWith(fontSize: 18)),
            const SizedBox(height: 14),

            ...planner.badges.map((badge) => _buildBadgeTile(badge)),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildBadgeTile(BadgeItem badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badge.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(badge.icon, color: badge.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(badge.description, style: AppStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 22),
        ],
      ),
    );
  }
}
