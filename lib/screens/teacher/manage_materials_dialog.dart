import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../course/document_viewer_screen.dart';

class ManageMaterialsDialog extends StatefulWidget {
  final CourseModel course;

  const ManageMaterialsDialog({super.key, required this.course});

  static Future<void> show(BuildContext context, {required CourseModel course}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManageMaterialsDialog(course: course),
    );
  }

  @override
  State<ManageMaterialsDialog> createState() => _ManageMaterialsDialogState();
}

class _ManageMaterialsDialogState extends State<ManageMaterialsDialog> {
  bool _isAdding = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _sizeController = TextEditingController(text: '16 Slides • 3.5 MB');
  final _fileUrlController = TextEditingController(text: 'https://example.com/slides.pdf');
  String _selectedType = 'slide'; // 'slide', 'pdf', 'document'
  MaterialModel? _editingMaterial;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _sizeController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  void _startEditing(MaterialModel mat) {
    setState(() {
      _editingMaterial = mat;
      _isAdding = true;
      _titleController.text = mat.title;
      _descController.text = mat.description;
      _sizeController.text = mat.fileSize;
      _fileUrlController.text = mat.fileUrl;
      _selectedType = mat.type;
    });
  }

  void _resetForm() {
    setState(() {
      _editingMaterial = null;
      _isAdding = false;
      _titleController.clear();
      _descController.clear();
      _sizeController.text = '16 Slides • 3.5 MB';
      _fileUrlController.text = 'https://example.com/slides.pdf';
      _selectedType = 'slide';
    });
  }

  void _handleSaveMaterial() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter material title!'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    if (_editingMaterial != null) {
      // Edit / Replace existing
      final index = widget.course.materials.indexWhere((m) => m.id == _editingMaterial!.id);
      if (index != -1) {
        widget.course.materials[index] = MaterialModel(
          id: _editingMaterial!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          type: _selectedType,
          fileUrl: _fileUrlController.text.trim(),
          fileSize: _sizeController.text.trim(),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${_titleController.text.trim()}" successfully! ✅'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } else {
      // Add new
      final newMat = MaterialModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        fileUrl: _fileUrlController.text.trim(),
        fileSize: _sizeController.text.trim(),
      );
      widget.course.materials.add(newMat);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded & attached "${newMat.title}"! 📑'),
          backgroundColor: AppColors.emerald,
        ),
      );
    }

    Provider.of<CourseProvider>(context, listen: false).fetchCourses();
    _resetForm();
  }

  void _handleDeleteMaterial(MaterialModel mat) {
    setState(() {
      widget.course.materials.removeWhere((m) => m.id == mat.id);
    });
    Provider.of<CourseProvider>(context, listen: false).fetchCourses();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${mat.title}" 🗑️'),
        backgroundColor: AppColors.coral,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage Study Materials & Slides', style: AppStyles.heading3.copyWith(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(
                    widget.course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle: View List vs Add/Edit Form
          if (_isAdding) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingMaterial != null ? 'Edit / Replace Material ✏️' : 'Upload New Material 📑',
                          style: AppStyles.heading3.copyWith(fontSize: 16, color: AppColors.primary),
                        ),
                        TextButton(
                          onPressed: _resetForm,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _titleController,
                      label: 'Document / Slide Title',
                      hint: 'e.g. Module 01 - Architecture Slide Deck.pdf',
                      prefixIcon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _descController,
                      label: 'Summary / Topics Covered',
                      hint: 'Theoretical concepts and architecture diagrams',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: InputDecoration(
                              labelText: 'Document Type',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'slide', child: Text('Slide Deck (PPT)')),
                              DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                              DropdownMenuItem(value: 'document', child: Text('Notes / Word Doc')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _sizeController,
                            label: 'Size / Pages',
                            hint: '16 Slides • 3.5 MB',
                            prefixIcon: Icons.pages_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // File Upload / URL simulator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            _editingMaterial != null ? 'Replace Attached File' : 'Upload Slide or Document File',
                            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Supported formats: PPT, PDF, DOCX (Max 50MB)',
                            style: AppStyles.caption.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.attach_file_rounded, size: 16),
                            label: const Text('Choose File from Device', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setState(() {
                                _fileUrlController.text = 'uploads/documents/lecture_slides_${DateTime.now().millisecondsSinceEpoch}.pdf';
                                _sizeController.text = '20 Slides • 4.2 MB';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('File selected: lecture_slides.pdf ✅'),
                                  backgroundColor: AppColors.emerald,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: _editingMaterial != null ? 'Update & Replace Material ✅' : 'Save & Attach Material 📑',
                      width: double.infinity,
                      height: 48,
                      onPressed: _handleSaveMaterial,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Button to Add Material
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attached Materials (${widget.course.materials.length})',
                  style: AppStyles.heading3.copyWith(fontSize: 16),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => setState(() => _isAdding = true),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Material List
            Expanded(
              child: widget.course.materials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.slideshow_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Text('No study materials attached yet.', style: AppStyles.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Click "+ Add Material" to attach slides, PDFs, or lecture notes.',
                            style: AppStyles.caption,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.course.materials.length,
                      itemBuilder: (ctx, i) {
                        final mat = widget.course.materials[i];
                        return _buildMaterialRow(mat);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialRow(MaterialModel mat) {
    Color typeColor;
    IconData typeIcon;

    if (mat.type == 'slide') {
      typeColor = const Color(0xFFF97316);
      typeIcon = Icons.slideshow_rounded;
    } else if (mat.type == 'pdf') {
      typeColor = AppColors.coral;
      typeIcon = Icons.picture_as_pdf_rounded;
    } else {
      typeColor = AppColors.primary;
      typeIcon = Icons.description_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mat.title,
                  style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${mat.type.toUpperCase()} • ${mat.fileSize}',
                  style: AppStyles.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Preview / View Slide
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary, size: 20),
            tooltip: 'Preview Slide Deck',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentViewerScreen(
                    material: mat,
                    courseTitle: widget.course.title,
                  ),
                ),
              );
            },
          ),

          // Edit / Replace
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.amber, size: 20),
            tooltip: 'Edit / Replace',
            onPressed: () => _startEditing(mat),
          ),

          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
            tooltip: 'Delete Material',
            onPressed: () => _handleDeleteMaterial(mat),
          ),
        ],
      ),
    );
  }
}
