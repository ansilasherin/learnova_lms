import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/planner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/planner_provider.dart';
import '../../providers/theme_provider.dart';

class LiveClassesScreen extends StatefulWidget {
  final bool showBackButton;

  const LiveClassesScreen({super.key, this.showBackButton = false});

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> {
  int _selectedTab = 0; // 0: All Live & Scheduled, 1: Live Now, 2: Upcoming

  void _joinLiveSession(BuildContext context, ScheduleItem schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sensors_rounded, color: AppColors.emerald, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Live Lecture Room',
                style: AppStyles.heading3.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.title,
              style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('Instructor: ${schedule.instructor}', style: AppStyles.caption),
            if (schedule.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Location: ${schedule.location}', style: AppStyles.caption),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Live Broadcast Stream Active • 1080p HD Audio & Video Ready',
                      style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connected to live class: ${schedule.title} 🎓'),
                  backgroundColor: AppColors.emerald,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.videocam_rounded, size: 18),
            label: const Text('Enter Classroom', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final planner = Provider.of<PlannerProvider>(context);
    final isTeacher = auth.isTeacher;

    final teacherClasses = planner.teacherClasses;
    final liveNowClasses = teacherClasses.where((c) => c.isLive).toList();
    final upcomingClasses = teacherClasses.where((c) => !c.isLive).toList();

    List<ScheduleItem> displayedClasses;
    if (_selectedTab == 1) {
      displayedClasses = liveNowClasses;
    } else if (_selectedTab == 2) {
      displayedClasses = upcomingClasses;
    } else {
      displayedClasses = teacherClasses;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isTeacher ? 'Live Lecture Studio' : 'Live Interactive Classes', style: AppStyles.heading3),
        centerTitle: true,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Portal Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${liveNowClasses.length} Live Sessions Active',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.sensors_rounded, color: Colors.white70, size: 20),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isTeacher ? 'Broadcast Live Lectures' : 'Real-time Video Classrooms',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTeacher
                        ? 'Stream interactive live sessions, conduct Q&A with students, and present real-time slides.'
                        : 'Join scheduled live lecture sessions, participate in classroom discussions, and learn in real time.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Segmented Filter Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildTabItem(0, 'All Sessions (${teacherClasses.length})'),
                  _buildTabItem(1, '🔴 Live Now (${liveNowClasses.length})'),
                  _buildTabItem(2, '📅 Upcoming (${upcomingClasses.length})'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Live Class Cards
            Text(
              _selectedTab == 1
                  ? 'Active Live Now (${liveNowClasses.length})'
                  : _selectedTab == 2
                      ? 'Upcoming Scheduled Lectures (${upcomingClasses.length})'
                      : 'All Teaching Sessions (${teacherClasses.length})',
              style: AppStyles.heading3.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),

            if (displayedClasses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: AppStyles.cardDecoration(),
                child: Column(
                  children: [
                    Icon(Icons.videocam_off_outlined, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      _selectedTab == 1
                          ? 'No live sessions currently broadcasting.'
                          : 'No upcoming lectures scheduled.',
                      style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check back during your scheduled timetable class hours.',
                      style: AppStyles.caption,
                    ),
                  ],
                ),
              )
            else
              ...displayedClasses.map((c) => _buildLiveClassCard(context, c, isTeacher)),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: AppStyles.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveClassCard(BuildContext context, ScheduleItem schedule, bool isTeacher) {
    final isLive = schedule.isLive;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLive ? AppColors.emerald.withValues(alpha: 0.4) : AppColors.cardBorder,
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive ? AppColors.emerald.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Stream Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isLive ? AppColors.emerald : AppColors.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isLive ? Icons.sensors_rounded : Icons.videocam_outlined,
                    color: isLive ? AppColors.emerald : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emerald,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.circle, color: Colors.white, size: 8),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE NOW',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'SCHEDULED',
                                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 9),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            schedule.duration,
                            style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        schedule.title,
                        style: AppStyles.heading3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(schedule.instructor, style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                          if (schedule.location.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(width: 8),
                            Icon(Icons.room_outlined, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(schedule.location, style: AppStyles.caption),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Time and Join Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16, color: isLive ? AppColors.emerald : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      schedule.time,
                      style: AppStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isLive ? AppColors.emerald : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _joinLiveSession(context, schedule),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLive ? AppColors.emerald : AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: Icon(isLive ? Icons.videocam_rounded : Icons.info_outline_rounded, size: 16),
                  label: Text(
                    isLive ? (isTeacher ? 'Enter Broadcast Studio' : 'Join Live Class 🔴') : 'Class Details',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
