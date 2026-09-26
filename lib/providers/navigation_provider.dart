import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 2; // 0: Classes, 1: Planner, 2: Home (Center), 3: Tasks, 4: Profile

  // Desktop sidebar index
  // 0: Dashboard, 1: My Courses, 2: Live Classes, 3: Calendar, 4: Assignments,
  // 5: Attendance, 6: Grades, 7: Study Planner, 8: Resources, 9: Messages, 10: Settings
  int _desktopNavIndex = 0;

  int get currentIndex => _currentIndex;
  int get desktopNavIndex => _desktopNavIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setDesktopNavIndex(int index) {
    _desktopNavIndex = index;
    notifyListeners();
  }
}