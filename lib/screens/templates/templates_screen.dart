import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
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

  void _useTemplate(String content, String category) {
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    templateProvider.setTemplate(content, category);

    // Navigate to HomeScreen which will switch to HomeView
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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

    return DefaultTabController(
      length: categories.length,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
             title: Text('Templates', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primaryLight)),
             bottom: TabBar(
                isScrollable: true,
                indicatorColor: AppColors.primaryLight,
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: AppColors.textSecondaryLight,
                labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                tabs: categories.map((c) => Tab(text: c)).toList(),
             ),
          ),
          body: TabBarView(
             children: categories.map((category) {
                final templates = _templatesMap[category]!;
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
                                                 fontSize: isSmallScreen ? 13 : 15
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                           ),
                                           const SizedBox(height: 4),
                                           Text(
                                              t['desc']!,
                                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight, fontSize: isSmallScreen ? 11 : 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                           ),
                                        ],
                                     ),
                                  ),
                               ),
                               InkWell(
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
                                        style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: isSmallScreen ? 12 : 14)
                                     ),
                                  ),
                               )
                            ],
                         ),
                      );
                   },
                );
             }).toList(),
          ),
        ),
      ),
    );
  }
}
