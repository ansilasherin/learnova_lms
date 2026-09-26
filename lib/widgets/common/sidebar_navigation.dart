import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../dialogs/theme_selection_dialog.dart';

class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;

    final navItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_rounded, 'index': 0},
      {'title': 'My Courses', 'icon': Icons.menu_book_rounded, 'index': 1},
      {'title': 'Live Classes', 'icon': Icons.videocam_rounded, 'index': 2},
      {'title': 'Calendar', 'icon': Icons.calendar_today_rounded, 'index': 3},
      {'title': 'Assignments', 'icon': Icons.assignment_rounded, 'index': 4},
      {'title': 'Attendance', 'icon': Icons.check_circle_outline_rounded, 'index': 5},
      {'title': 'Grades', 'icon': Icons.assessment_rounded, 'index': 6},
      {'title': 'Study Planner', 'icon': Icons.lightbulb_outline_rounded, 'index': 7},
      {'title': 'Achievements', 'icon': Icons.emoji_events_rounded, 'index': 8},
      {'title': 'Settings', 'icon': Icons.settings_outlined, 'index': 9},
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Branding Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learnova',
                      style: AppStyles.heading3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'LMS PLATFORM',
                      style: AppStyles.caption.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: navItems.length,
              itemBuilder: (context, i) {
                final item = navItems[i];
                final isSelected = navProvider.desktopNavIndex == item['index'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: AppStyles.bodyMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      navProvider.setDesktopNavIndex(item['index'] as int);
                    },
                  ),
                );
              },
            ),
          ),

          // Theme Switcher Row for Desktop
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => ThemeSelectionDialog.show(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          themeProv.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          size: 18,
                          color: themeProv.isDarkMode ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          themeProv.isDarkMode ? 'Dark Mode' : 'Light Mode',
                          style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Switch(
                      value: themeProv.isDarkMode,
                      activeColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val) => themeProv.toggleTheme(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // User Profile Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                navProvider.setDesktopNavIndex(9); // Settings/Profile
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Learnova User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            user?.role.toUpperCase() ?? 'STUDENT',
                            style: AppStyles.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
