import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/dialogs/celebration_dialog.dart';

class LessonPlayerScreen extends StatefulWidget {
  final CourseModel course;
  final LessonModel lesson;
  final bool isCompleted;

  const LessonPlayerScreen({
    super.key,
    required this.course,
    required this.lesson,
    this.isCompleted = false,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late bool _completed;
  YoutubePlayerController? _youtubeController;
  String? _youtubeVideoId;

  @override
  void initState() {
    super.initState();
    _completed = widget.isCompleted;
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoUrl = widget.lesson.videoUrl;
    _youtubeVideoId = _extractYoutubeId(videoUrl);

    if (_youtubeVideoId != null) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: _youtubeVideoId!,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          showVideoAnnotations: false,
          mute: false,
          enableCaption: true,
        ),
      );
    }
  }

  String? _extractYoutubeId(String url) {
    if (url.trim().isEmpty) return null;
    final trimmed = url.trim();

    // Direct 11 character ID check
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    return match?.group(1);
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  Future<void> _handleCompleteLesson() async {
    final enrollProv = Provider.of<EnrollmentProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final res = await enrollProv.completeLesson(widget.course.id, widget.lesson.id);

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() => _completed = true);

      final isAllDone = res['isCompleted'] == true;
      if (isAllDone) {
        CelebrationDialog.show(
          context,
          studentName: auth.currentUser?.name ?? 'Student',
          message: 'Congratulations! You completed the entire course!',
          percentage: 100,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Lesson progress updated! ✅'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update progress'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  Future<void> _launchExternalVideo() async {
    var url = widget.lesson.videoUrl.trim();
    if (url.isEmpty) return;

    if (!kIsWeb) {
      try {
        if (Platform.isAndroid && url.contains('localhost:5000')) {
          url = url.replaceAll('localhost:5000', '10.0.2.2:5000');
        }
      } catch (_) {}
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open video URL'), backgroundColor: AppColors.coral),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.lesson.title, style: AppStyles.heading3.copyWith(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.lesson.videoUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
              tooltip: 'Open in Browser / YouTube',
              onPressed: _launchExternalVideo,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Container (Embedded YouTube Player or Direct Stream)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildVideoPlayerWidget(),
              ),
            ),
            const SizedBox(height: 24),

            // Lesson Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.lesson.title,
                    style: AppStyles.heading2.copyWith(fontSize: 20),
                  ),
                ),
                if (_completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: AppStyles.caption.copyWith(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Duration: ${widget.lesson.duration}', style: AppStyles.caption),
                if (widget.lesson.isFreePreview) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Free Preview',
                      style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Video Link Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _youtubeVideoId != null ? Icons.play_circle_filled_rounded : Icons.link_rounded,
                    color: _youtubeVideoId != null ? AppColors.coral : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _youtubeVideoId != null
                          ? 'Streaming from YouTube (ID: $_youtubeVideoId)'
                          : widget.lesson.videoUrl.isNotEmpty
                              ? widget.lesson.videoUrl
                              : 'No video stream attached',
                      style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _launchExternalVideo,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                    child: Text('Open ↗', style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text('About this Lesson', style: AppStyles.heading3.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              widget.lesson.description != null && widget.lesson.description!.trim().isNotEmpty
                  ? widget.lesson.description!
                  : 'In this lesson, you will explore the core concepts, watch the practical lecture, and gain hands-on architectural understanding to build high-performance systems.',
              style: AppStyles.bodyMedium.copyWith(height: 1.5),
            ),
            const SizedBox(height: 36),

            // Mark as Completed Button
            Consumer<EnrollmentProvider>(
              builder: (context, enroll, _) {
                return CustomButton(
                  text: _completed ? 'Completed ✅' : 'Mark Lesson as Completed 🎯',
                  backgroundColor: _completed ? AppColors.emerald : AppColors.primary,
                  isLoading: enroll.isLoading,
                  width: double.infinity,
                  height: 50,
                  onPressed: _completed ? null : _handleCompleteLesson,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayerWidget() {
    // 1. If YouTube Video ID exists -> Render Real Interactive YouTube Player
    if (_youtubeController != null && _youtubeVideoId != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        aspectRatio: 16 / 9,
      );
    }

    // 2. Direct Video or Fallback Player Banner
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Course Thumbnail Background
          if (widget.course.thumbnail.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.course.thumbnail,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF0F172A)),
            ),
          Container(
            color: Colors.black.withOpacity(0.55),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _launchExternalVideo,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Click to Play Video Stream',
                  style: AppStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.lesson.duration,
                  style: AppStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
