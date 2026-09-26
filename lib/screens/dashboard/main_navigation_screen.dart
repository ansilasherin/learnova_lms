import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/sidebar_navigation.dart';
import '../../widgets/navigation/curved_animated_navbar.dart';
import '../achievements/achievements_screen.dart';
import '../assignments/assignments_screen.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/class_attendance_sheet_screen.dart';
import '../course/live_classes_screen.dart';
import '../course/my_courses_screen.dart';
import '../grades/grades_screen.dart';
import '../planner/calendar_screen.dart';
import '../planner/study_planner_screen.dart';
import '../profile/profile_screen.dart';
import 'desktop_dashboard_view.dart';
import 'mobile_home_view.dart';
import 'teacher_home_view.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Live real-world initial data fetch across all services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchCourses();
      Provider.of<EnrollmentProvider>(context, listen: false).fetchMyEnrollments();
      Provider.of<PlannerProvider>(context, listen: false).fetchAcademicData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // React immediately to any theme switch
    Provider.of<ThemeProvider>(context);

    return ResponsiveLayout(
      mobile: const _MobileMainLayout(),
      tablet: const _MobileMainLayout(),
      desktop: const _DesktopMainLayout(),
    );
  }
}

// ==========================================
// Desktop & Web Layout with Sidebar
// ==========================================
class _DesktopMainLayout extends StatelessWidget {
  const _DesktopMainLayout();

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final nav = Provider.of<NavigationProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isTeacher = auth.isTeacher || auth.isAdmin;

    Widget getDesktopBody() {
      switch (nav.desktopNavIndex) {
        case 0:
          return isTeacher ? const TeacherHomeView() : const DesktopDashboardView();
        case 1:
          return const MyCoursesScreen();
        case 2:
          return const LiveClassesScreen();
        case 3:
          return const CalendarScreen();
        case 4:
          return const AssignmentsScreen();
        case 5:
          return isTeacher ? const ClassAttendanceSheetScreen() : const AttendanceScreen();
        case 6:
          return const GradesScreen();
        case 7:
          return const StudyPlannerScreen();
        case 8:
          return const AchievementsScreen();
        case 9:
          return const ProfileScreen();
        default:
          return isTeacher ? const TeacherHomeView() : const DesktopDashboardView();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const SidebarNavigation(),
          Expanded(child: getDesktopBody()),
        ],
      ),
    );
  }
}

// ==========================================
// Mobile & Tablet Layout with Bottom Bar
// ==========================================
class _MobileMainLayout extends StatelessWidget {
  const _MobileMainLayout();

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final nav = Provider.of<NavigationProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isTeacher = auth.isTeacher || auth.isAdmin;

    final List<Widget> mobileScreens = [
      const CalendarScreen(),
      const StudyPlannerScreen(),
      isTeacher ? const TeacherHomeView() : const MobileHomeView(),
      const AssignmentsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: nav.currentIndex,
          children: mobileScreens,
        ),
      ),
      bottomNavigationBar: CurvedAnimatedNavBar(
        currentIndex: nav.currentIndex,
        onTap: (index) => nav.setCurrentIndex(index),
        items: const [
          CurvedNavBarItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Classes',
          ),
          CurvedNavBarItem(
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
            label: 'Planner',
          ),
          CurvedNavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          CurvedNavBarItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Tasks',
          ),
          CurvedNavBarItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
