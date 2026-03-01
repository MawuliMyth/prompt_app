import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/utils/platform_utils.dart';
import '../../providers/template_provider.dart';
import '../home/home_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  // Built in templates specs:
  final Map<String, List<Map<String, String>>> _templatesMap = {
     'General': [
        {'title': 'Explain a concept', 'icon': '🧠', 'desc': 'Explain a concept simply as if to a child.', 'content': 'Explain [concept] simply.'},
        {'title': 'Pros and Cons', 'icon': '⚖️', 'desc': 'Give me pros and cons of a topic.', 'content': 'Give me pros and cons of...'},
        {'title': 'Decision Maker', 'icon': '🤔', 'desc': 'Help me make a decision about...', 'content': 'Help me make a decision about...'},
     ],
     'Image Generation': [
        {'title': 'Realistic Portrait', 'icon': '👤', 'desc': 'Create a realistic portrait photo with dramatic lighting.', 'content': 'Create a realistic portrait of...'},
        {'title': 'Landscape Scene', 'icon': '🏞️', 'desc': 'Generate a cinematic landscape scene.', 'content': 'Generate a landscape scene with...'},
        {'title': 'Logo Design', 'icon': '✨', 'desc': 'Design a vector logo for a brand.', 'content': 'Design a logo for...'},
     ],
     'Coding': [
        {'title': 'Build a Function', 'icon': '🏗️', 'desc': 'Help me build a specific programming function.', 'content': 'Help me build a function that...'},
        {'title': 'Code Review', 'icon': '👀', 'desc': 'Review and improve a snippet of code.', 'content': 'Review and improve this code...'},
        {'title': 'Error Fix', 'icon': '🐛', 'desc': 'Explain an error message and provide the fix.', 'content': 'Explain this error and fix it...'},
     ],
     'Writing': [
        {'title': 'Professional Email', 'icon': '✉️', 'desc': 'Write a formal email addressing a topic.', 'content': 'Write a professional email about...'},
        {'title': 'Social Caption', 'icon': '📱', 'desc': 'Create a catchy social media caption.', 'content': 'Create a social media caption for...'},
        {'title': 'Blog Post Outline', 'icon': '📝', 'desc': 'Create an outline for a new blog post.', 'content': 'Write a blog post about...'},
     ],
     'Business': [
        {'title': 'Business Plan', 'icon': '📉', 'desc': 'Create a detailed business plan outline.', 'content': 'Create a business plan for...'},
        {'title': 'Marketing Strategy', 'icon': '🎯', 'desc': 'Write a marketing go-to-market strategy.', 'content': 'Write a marketing strategy for...'},
        {'title': 'Formal Proposal', 'icon': '💼', 'desc': 'Draft a professional business proposal.', 'content': 'Draft a professional proposal for...'},
     ],
  };

  String _selectedCategory = 'General';

  void _useTemplate(String content, String category) {
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    templateProvider.setTemplate(content, category);

    // Navigate to HomeScreen which will switch to HomeView
    Navigator.of(context).pushAndRemoveUntil(
      PlatformUtils.adaptivePageRoute(const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _templatesMap.keys.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 360;
    final isCupertino = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

    return SafeArea(
      child: Scaffold(
        appBar: AdaptiveAppBar(title: 'Templates'),
        body: Column(
          children: [
            // Category Selector
            if (isCupertino)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _selectedCategory,
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                    children: Map.fromEntries(
                      categories.map((cat) => MapEntry(
                        cat,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            cat,
                            style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                          ),
                        ),
                      )),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() => _selectedCategory = cat);
                        },
                        backgroundColor: theme.colorScheme.surface,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Templates Grid
            Expanded(
              child: _buildTemplatesGrid(
                _templatesMap[_selectedCategory]!,
                _selectedCategory,
                theme,
                isTablet,
                isSmallScreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesGrid(
    List<Map<String, String>> templates,
    String category,
    ThemeData theme,
    bool isTablet,
    bool isSmallScreen,
  ) {
    return GridView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: isSmallScreen ? 12 : 16,
        mainAxisSpacing: isSmallScreen ? 12 : 16,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final t = templates[index];
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['icon']!, style: TextStyle(fontSize: isSmallScreen ? 22 : 28)),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Text(
                        t['title']!,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: isSmallScreen ? 13 : 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t['desc']!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _useTemplate(t['content']!, category),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Text(
                    'Use Template',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
