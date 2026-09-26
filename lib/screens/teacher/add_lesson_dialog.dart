import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/course_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/course_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class AddLessonDialog extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const AddLessonDialog({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  static Future<bool?> show(BuildContext context, {required String courseId, required String courseTitle}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddLessonDialog(courseId: courseId, courseTitle: courseTitle),
    );
  }

  @override
  State<AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<AddLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _durationController = TextEditingController(text: '15 mins');
  final _descController = TextEditingController();
  bool _isFreePreview = false;

  // Upload state
  int _selectedSourceTab = 0; // 0: From Device, 1: YouTube / URL
  bool _isUploading = false;
  String? _pickedFileName;
  int? _pickedFileSize;
  String? _uploadStatusMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _videoUrlController.dispose();
    _durationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() {
        _pickedFileName = file.name;
        _pickedFileSize = file.size;
        _isUploading = true;
        _uploadStatusMessage = 'Uploading ${file.name} to server...';
      });

      // Auto pre-fill title if empty
      if (_titleController.text.trim().isEmpty) {
        final rawName = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
        _titleController.text = rawName.replaceAll('_', ' ').replaceAll('-', ' ');
      }

      final uploadRes = await CourseService.uploadVideoFile(file);

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      if (uploadRes['success'] == true && uploadRes['videoUrl'] != null) {
        setState(() {
          _videoUrlController.text = uploadRes['videoUrl'];
          _uploadStatusMessage = 'Uploaded successfully! 🎬';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video uploaded successfully: ${file.name} 🚀'),
            backgroundColor: AppColors.emerald,
          ),
        );
      } else {
        setState(() {
          _uploadStatusMessage = 'Upload failed ❌';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadRes['message'] ?? 'Failed to upload video'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadStatusMessage = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading video: $e'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_videoUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a video URL first!'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final courseProv = Provider.of<CourseProvider>(context, listen: false);
    final success = await courseProv.addLesson(
      courseId: widget.courseId,
      title: _titleController.text.trim(),
      videoUrl: _videoUrlController.text.trim(),
      duration: _durationController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      isFreePreview: _isFreePreview,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson added successfully! 🎬'),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(courseProv.errorMessage ?? 'Failed to add lesson'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.video_collection_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text('Add New Lesson', style: AppStyles.heading3.copyWith(fontSize: 18)),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Course: ${widget.courseTitle}', style: AppStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                // Lesson Title
                CustomTextField(
                  label: 'Lesson Title',
                  hint: 'e.g. 1. Introduction to State Management',
                  controller: _titleController,
                  validator: (val) => (val == null || val.isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 18),

                // Video Source Tabs (From Device vs YouTube/URL)
                Text('Video Source', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedSourceTab = 0),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedSourceTab == 0 ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedSourceTab == 0
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_file_rounded,
                                  size: 16,
                                  color: _selectedSourceTab == 0 ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Upload from Device 📁',
                                  style: AppStyles.caption.copyWith(
                                    fontWeight: _selectedSourceTab == 0 ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedSourceTab == 0 ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedSourceTab = 1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedSourceTab == 1 ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedSourceTab == 1
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  size: 16,
                                  color: _selectedSourceTab == 1 ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'YouTube / Direct Link 🔗',
                                  style: AppStyles.caption.copyWith(
                                    fontWeight: _selectedSourceTab == 1 ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedSourceTab == 1 ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Source Section 0: Device Video Picker
                if (_selectedSourceTab == 0) ...[
                  InkWell(
                    onTap: _isUploading ? null : _pickAndUploadVideo,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _videoUrlController.text.isNotEmpty ? AppColors.emerald : AppColors.primary.withOpacity(0.4),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isUploading) ...[
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _uploadStatusMessage ?? 'Uploading video...',
                              style: AppStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text('Please do not close this dialog', style: AppStyles.caption),
                          ] else if (_pickedFileName != null && _videoUrlController.text.isNotEmpty) ...[
                            const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _pickedFileName!,
                              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_pickedFileSize != null)
                              Text(_formatFileSize(_pickedFileSize!), style: AppStyles.caption),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Video Uploaded & Linked ✅ (Tap to change)',
                                style: AppStyles.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.video_file_rounded, color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(height: 10),
                            Text('Click to Pick Video from Computer / Phone', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Supports MP4, MOV, MKV, WEBM (Up to 500 MB)', style: AppStyles.caption),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_videoUrlController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Server Stream URL: ${_videoUrlController.text}',
                      style: AppStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ] else ...[
                  // Source Section 1: Direct URL / YouTube
                  CustomTextField(
                    label: 'Video Link (YouTube URL or Direct MP4)',
                    hint: 'https://www.youtube.com/watch?v=... or https://...mp4',
                    controller: _videoUrlController,
                    validator: (val) => (val == null || val.isEmpty) ? 'Please enter a video URL' : null,
                  ),
                ],
                const SizedBox(height: 16),

                // Duration & Free Preview Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Duration',
                        hint: 'e.g. 20 mins',
                        controller: _durationController,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Free Preview', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Public preview', style: AppStyles.caption.copyWith(fontSize: 11)),
                              ],
                            ),
                            Switch(
                              value: _isFreePreview,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => setState(() => _isFreePreview = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                CustomTextField(
                  label: 'Description (Optional)',
                  hint: 'Key concepts covered in this lesson...',
                  controller: _descController,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isUploading ? null : () => Navigator.pop(context),
                        child: Text('Cancel', style: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        text: 'Add Lesson 🚀',
                        isLoading: courseProv.isLoading || _isUploading,
                        onPressed: _isUploading ? null : _handleSubmit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

