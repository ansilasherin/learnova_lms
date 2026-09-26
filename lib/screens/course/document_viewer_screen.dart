import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../services/file_download_service.dart';
import '../../widgets/common/custom_button.dart';

class DocumentViewerScreen extends StatefulWidget {
  final MaterialModel material;
  final String courseTitle;

  const DocumentViewerScreen({
    super.key,
    required this.material,
    required this.courseTitle,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  int _currentSlide = 1;
  final int _totalSlides = 8;
  bool _isDownloading = false;

  // Mock slide titles and points for presentation preview
  final List<Map<String, dynamic>> _slideContents = [
    {
      'title': '01. Overview & Architecture',
      'points': [
        'Introduction to System Component Structure',
        'Data Flow from Client to Server and Database',
        'Core Principles of High-Throughput Design'
      ]
    },
    {
      'title': '02. Key Concepts & Definitions',
      'points': [
        'Time & Space Complexity Tradeoffs',
        'State Management across Stateless Nodes',
        'Memory Allocation and Garbage Collection'
      ]
    },
    {
      'title': '03. Implementation Blueprint',
      'points': [
        'Step-by-step Execution Pipeline',
        'Error Handling and Edge Case Validations',
        'Security Best Practices and Sanitization'
      ]
    },
    {
      'title': '04. Real-world Case Study',
      'points': [
        'Handling 10,000+ Concurrent Requests',
        'Database Indexing and Query Optimization',
        'Caching with In-Memory Key-Value Stores'
      ]
    },
    {
      'title': '05. Code Walkthrough & Snippets',
      'points': [
        'Controller, Service, and Repository Layers',
        'Middleware Authentication Guard Pipeline',
        'Unit & Integration Testing Guidelines'
      ]
    },
    {
      'title': '06. Performance Optimization',
      'points': [
        'Reducing Latency via Payload Minimization',
        'Asynchronous Background Job Queues',
        'Connection Pooling Strategies'
      ]
    },
    {
      'title': '07. Common Pitfalls & Anti-patterns',
      'points': [
        'Avoiding N+1 Query Problems',
        'Preventing Memory Leaks in Closures',
        'Proper Graceful Shutdown Handling'
      ]
    },
    {
      'title': '08. Summary & Next Action Items',
      'points': [
        'Review Module Practice Exercises',
        'Complete Assigned Hands-on Lab',
        'Prepare for Module Quiz'
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isSlide = widget.material.type == 'slide' || widget.material.type == 'pdf';
    final slideData = _slideContents[(_currentSlide - 1) % _slideContents.length];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark presentation backdrop
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.material.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.heading3.copyWith(color: Colors.white, fontSize: 16),
            ),
            Text(
              widget.courseTitle,
              style: AppStyles.caption.copyWith(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document link copied to clipboard! 🔗'),
                  backgroundColor: AppColors.emerald,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Slide / Document Canvas Viewer
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 680, maxHeight: 420),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Slide Background Header Accent
                      Container(
                        height: 70,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isSlide ? Icons.slideshow_rounded : Icons.description_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.material.type.toUpperCase(),
                                      style: AppStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Page $_currentSlide of $_totalSlides',
                                    style: AppStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),

                            // Slide Title
                            Text(
                              slideData['title'] as String,
                              style: AppStyles.heading2.copyWith(
                                fontSize: 20,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Slide Bullet Points
                            Expanded(
                              child: ListView(
                                children: (slideData['points'] as List<String>).map((point) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            point,
                                            style: AppStyles.bodyLarge.copyWith(
                                              color: AppColors.textPrimary,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Slide Navigation Controls Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Slide Button
                      IconButton(
                        onPressed: _currentSlide > 1
                            ? () => setState(() => _currentSlide--)
                            : null,
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        tooltip: 'Previous Slide',
                      ),

                      // Slide Indicator Slider / Text
                      Row(
                        children: [
                          Text(
                            'Slide $_currentSlide',
                            style: AppStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' / $_totalSlides',
                            style: AppStyles.bodyMedium.copyWith(color: Colors.white60),
                          ),
                        ],
                      ),

                      // Next Slide Button
                      IconButton(
                        onPressed: _currentSlide < _totalSlides
                            ? () => setState(() => _currentSlide++)
                            : null,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                        tooltip: 'Next Slide',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Download / Save Action Button
                  CustomButton(
                    text: _isDownloading ? 'Downloading...' : 'Download File (${widget.material.fileSize}) ⬇️',
                    isLoading: _isDownloading,
                    backgroundColor: AppColors.primary,
                    width: double.infinity,
                    height: 48,
                    onPressed: () async {
                      setState(() => _isDownloading = true);
                      final result = await FileDownloadService.downloadStudyMaterial(
                        material: widget.material,
                        courseTitle: widget.courseTitle,
                      );
                      if (mounted) {
                        setState(() => _isDownloading = false);
                      }
                      if (context.mounted) {
                        FileDownloadService.showDownloadFeedback(context, result);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
