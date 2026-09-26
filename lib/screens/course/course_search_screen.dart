import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/cards/course_card.dart';
import 'course_details_screen.dart';

class CourseSearchScreen extends StatefulWidget {
  final String? initialCategory;

  const CourseSearchScreen({super.key, this.initialCategory});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Computer Science',
    'Databases',
    'System Architecture',
    'Web Development',
    'Mobile Development',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);
    final enrollProv = Provider.of<EnrollmentProvider>(context);

    // Filter courses based on query and category
    final query = _searchQuery.toLowerCase().trim();
    final filteredCourses = courseProv.courses.where((course) {
      final title = (course.title).toLowerCase();
      final desc = (course.description).toLowerCase();
      final cat = (course.category).toLowerCase();
      final inst = (course.instructor?.name ?? '').toLowerCase();

      final matchesQuery = query.isEmpty ||
          title.contains(query) ||
          desc.contains(query) ||
          cat.contains(query) ||
          inst.contains(query);

      final matchesCategory = _selectedCategory == 'All' ||
          course.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Browse & Search Courses', style: AppStyles.heading3),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Field
            Container(
              decoration: AppStyles.cardDecoration(),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search courses by title, topic, or keyword...',
                  hintStyle: AppStyles.caption.copyWith(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Category Filter Pills
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: AppStyles.caption.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Results count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Results (${filteredCourses.length})',
                  style: AppStyles.heading3.copyWith(fontSize: 16),
                ),
                if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'All';
                      });
                    },
                    child: Text('Reset Filters', style: AppStyles.caption.copyWith(color: AppColors.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Course Results List
            if (filteredCourses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                decoration: AppStyles.cardDecoration(),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 50, color: AppColors.textMuted),
                      const SizedBox(height: 14),
                      Text('No courses match your query', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Try searching with different keywords or categories.', style: AppStyles.caption),
                    ],
                  ),
                ),
              )
            else
              ...filteredCourses.map((course) {
                final enrollment = enrollProv.getEnrollmentForCourse(course.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: CourseCard(
                    course: course,
                    isCompact: false,
                    progressPercentage: enrollment?.progressPercentage ?? 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: course)),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
