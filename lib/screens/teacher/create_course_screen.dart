import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/course_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _thumbnailController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=600',
  );

  String _selectedCategory = 'Computer Science';
  String _selectedLevel = 'Beginner';

  final List<String> _categories = [
    'Computer Science',
    'Databases',
    'System Architecture',
    'Web Development',
    'Mobile Development',
    'Artificial Intelligence',
  ];

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced', 'All Levels'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final courseProv = Provider.of<CourseProvider>(context, listen: false);
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    final success = await courseProv.createCourse(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      price: price,
      level: _selectedLevel,
      thumbnail: _thumbnailController.text.trim().isNotEmpty ? _thumbnailController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course published successfully! 🎉'),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(courseProv.errorMessage ?? 'Course creation failed'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Create New Course', style: AppStyles.heading3),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course Information', style: AppStyles.heading2.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text('Fill in the details to publish your course on Learnova LMS', style: AppStyles.caption),
              const SizedBox(height: 20),

              // Title
              CustomTextField(
                label: 'Course Title',
                hint: 'e.g. Complete Flutter & Dart Bootcamp',
                controller: _titleController,
                prefixIcon: Icons.school_outlined,
                validator: (val) => (val == null || val.isEmpty) ? 'Course title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                label: 'Course Description',
                hint: 'What will students learn in this course?',
                controller: _descController,
                maxLines: 4,
                prefixIcon: Icons.description_outlined,
                validator: (val) => (val == null || val.isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: AppStyles.cardDecoration(),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat, style: AppStyles.bodyMedium));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Level & Price Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Difficulty Level', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: AppStyles.cardDecoration(),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLevel,
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                              items: _levels.map((lvl) {
                                return DropdownMenuItem(value: lvl, child: Text(lvl, style: AppStyles.bodyMedium));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedLevel = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      label: 'Price (₹ 0 for Free)',
                      hint: '0',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.currency_rupee_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Thumbnail URL
              CustomTextField(
                label: 'Cover Image URL',
                hint: 'https://images.unsplash.com/...',
                controller: _thumbnailController,
                prefixIcon: Icons.image_outlined,
              ),
              const SizedBox(height: 32),

              // Publish Button
              CustomButton(
                text: 'Publish Course 🎓',
                isLoading: courseProv.isLoading,
                width: double.infinity,
                height: 52,
                onPressed: _handleCreateCourse,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
