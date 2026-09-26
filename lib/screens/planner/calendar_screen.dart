import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlannerProvider>(context, listen: false).fetchAcademicData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeProvider for instantaneous Dark/Light reactive updates
    Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final plannerProv = Provider.of<PlannerProvider>(context);
    final isTeacher = auth.isTeacher;
    final userName = auth.currentUser?.name ?? 'Professor';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isTeacher ? 'Teaching Calendar' : 'Class Timetable Calendar', style: AppStyles.heading3),
        centerTitle: true,
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () {
                final titleCtrl = TextEditingController();
                final locationCtrl = TextEditingController(text: 'Lecture Hall 201');
                final timeCtrl = TextEditingController(text: 'Today, 10:00 AM - 11:30 AM');
                bool isLive = true;

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setModalState) => Container(
                      padding: EdgeInsets.only(
                        top: 24,
                        left: 24,
                        right: 24,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Schedule Lecture Class 🏛️', style: AppStyles.heading3.copyWith(fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: titleCtrl,
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Subject / Lecture Title',
                              labelStyle: TextStyle(color: AppColors.textSecondary),
                              hintText: 'e.g. Advanced Operating Systems',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              prefixIcon: const Icon(Icons.school_rounded, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.cardBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: locationCtrl,
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Lecture Hall / Room',
                              labelStyle: TextStyle(color: AppColors.textSecondary),
                              hintText: 'Hall 201 / CS Lab',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              prefixIcon: const Icon(Icons.room_outlined, color: AppColors.emerald),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.cardBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: timeCtrl,
                            style: TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Time Slot',
                              labelStyle: TextStyle(color: AppColors.textSecondary),
                              hintText: 'Today, 10:00 AM - 11:30 AM',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.amber),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.cardBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.sensors_rounded, color: AppColors.emerald, size: 20),
                                    SizedBox(width: 8),
                                    Text('Live Lecture Session', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                                Switch.adaptive(
                                  value: isLive,
                                  activeTrackColor: AppColors.emerald,
                                  onChanged: (val) => setModalState(() => isLive = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                if (titleCtrl.text.trim().isNotEmpty) {
                                  plannerProv.addSchedule(
                                    ScheduleItem(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      title: titleCtrl.text.trim(),
                                      instructor: userName,
                                      location: locationCtrl.text.trim(),
                                      time: timeCtrl.text.trim(),
                                      duration: '1.5 hrs',
                                      isLive: isLive,
                                      color: AppColors.primary,
                                      type: 'class',
                                    ),
                                  );
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lecture "${titleCtrl.text.trim()}" published to student calendar! 🏛️'),
                                      backgroundColor: AppColors.emerald,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Publish Class Lecture 🏛️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('Schedule Class 🏛️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            )
          : null, // Students cannot add official classes, read-only
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Box
            Container(
              decoration: AppStyles.cardDecoration(),
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.utc(2025, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() => _calendarFormat = format);
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: AppStyles.heading3.copyWith(fontSize: 16),
                  leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                  weekendStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  weekendTextStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  outsideTextStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
                  disabledTextStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.3)),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming Official Classes & Events Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTeacher ? 'Scheduled Teaching Classes' : 'Upcoming Official Lectures 🏛️',
                  style: AppStyles.heading3.copyWith(fontSize: 17),
                ),
                if (!isTeacher)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Read-Only 🔒', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (plannerProv.teacherClasses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppStyles.cardDecoration(),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 36, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('No official lectures scheduled yet', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        isTeacher ? 'Tap "Schedule Class" to add a lecture session.' : 'Your teachers will publish lecture schedules here.',
                        style: AppStyles.caption,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...plannerProv.teacherClasses.map(
                (c) => _buildUpcomingCard(
                  title: c.title,
                  subtitle: '${c.time}${c.location.isNotEmpty ? " • ${c.location}" : ""} (${c.instructor})',
                  isLive: c.isLive,
                  color: c.color,
                  icon: c.isLive ? Icons.sensors_rounded : Icons.school_rounded,
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard({
    required String title,
    required String subtitle,
    required bool isLive,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppStyles.caption),
              ],
            ),
          ),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Live',
                style: AppStyles.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold),
              ),
            )
          else
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
