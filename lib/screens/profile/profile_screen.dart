import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/dialogs/theme_selection_dialog.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile & Settings', style: AppStyles.heading3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProv.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: themeProv.isDarkMode ? const Color(0xFFFBBF24) : AppColors.textSecondary,
            ),
            tooltip: themeProv.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => themeProv.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Avatar & Name
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'Learnova User',
                    style: AppStyles.heading2.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'user@learnova.com',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.role.toUpperCase() ?? 'STUDENT',
                      style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Theme Switcher Tile
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppStyles.cardDecoration(
                border: Border.all(
                  color: themeProv.isDarkMode ? AppColors.primary.withOpacity(0.4) : AppColors.cardBorder,
                  width: themeProv.isDarkMode ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProv.isDarkMode
                        ? const Color(0xFF818CF8).withOpacity(0.15)
                        : const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProv.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: themeProv.isDarkMode ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                title: Text('Appearance & Theme', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  themeProv.themeMode == ThemeMode.system
                      ? 'System Default'
                      : (themeProv.isDarkMode ? 'Dark Mode (Active 🌙)' : 'Light Mode (Active ☀️)'),
                  style: AppStyles.caption.copyWith(color: AppColors.primary),
                ),
                trailing: Switch(
                  value: themeProv.isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (val) => themeProv.toggleTheme(),
                ),
                onTap: () => ThemeSelectionDialog.show(context),
              ),
            ),

            // Profile Options Menu
            _buildProfileOption(
              title: 'Edit Profile',
              icon: Icons.person_outline_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _buildProfileOption(
              title: 'Account Settings',
              icon: Icons.settings_outlined,
              onTap: () {},
            ),
            _buildProfileOption(
              title: 'Notification Preferences',
              icon: Icons.notifications_none_rounded,
              onTap: () {},
            ),
            _buildProfileOption(
              title: 'Privacy & Security',
              icon: Icons.shield_outlined,
              onTap: () {},
            ),
            _buildProfileOption(
              title: 'Help & Support',
              icon: Icons.help_outline_rounded,
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // Logout Option
            InkWell(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout from Learnova LMS?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: AppStyles.cardDecoration(
                  color: AppColors.coral.withOpacity(0.06),
                  border: Border.all(color: AppColors.coral.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: AppColors.coral, size: 20),
                    const SizedBox(width: 14),
                    Text(
                      'Logout',
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppStyles.cardDecoration(),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon, color: AppColors.textSecondary, size: 20),
        title: Text(title, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }
}
