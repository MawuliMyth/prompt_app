import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
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
  final Map<String, List<_TemplateItem>> _templatesMap = {
    'General': [
      _TemplateItem(
        title: 'Explain a concept',
        icon: Icons.lightbulb_outline,
        desc: 'Explain a concept simply as if to a child.',
        content: 'Explain [concept] simply.',
      ),
      _TemplateItem(
        title: 'Pros and Cons',
        icon: Icons.balance_outlined,
        desc: 'Give me pros and cons of a topic.',
        content: 'Give me pros and cons of...',
      ),
      _TemplateItem(
        title: 'Decision Maker',
        icon: Icons.help_outline,
        desc: 'Help me make a decision about...',
        content: 'Help me make a decision about...',
      ),
    ],
    'Image Generation': [
      _TemplateItem(
        title: 'Realistic Portrait',
        icon: Icons.person_outline,
        desc: 'Create a realistic portrait photo with dramatic lighting.',
        content: 'Create a realistic portrait of...',
      ),
      _TemplateItem(
        title: 'Landscape Scene',
        icon: Icons.landscape_outlined,
        desc: 'Generate a cinematic landscape scene.',
        content: 'Generate a landscape scene with...',
      ),
      _TemplateItem(
        title: 'Logo Design',
        icon: Icons.auto_awesome_outlined,
        desc: 'Design a vector logo for a brand.',
        content: 'Design a logo for...',
      ),
    ],
    'Coding': [
      _TemplateItem(
        title: 'Build a Function',
        icon: Icons.code_outlined,
        desc: 'Help me build a specific programming function.',
        content: 'Help me build a function that...',
      ),
      _TemplateItem(
        title: 'Code Review',
        icon: Icons.visibility_outlined,
        desc: 'Review and improve a snippet of code.',
        content: 'Review and improve this code...',
      ),
      _TemplateItem(
        title: 'Error Fix',
        icon: Icons.bug_report_outlined,
        desc: 'Explain an error message and provide the fix.',
        content: 'Explain this error and fix it...',
      ),
    ],
    'Writing': [
      _TemplateItem(
        title: 'Professional Email',
        icon: Icons.email_outlined,
        desc: 'Write a formal email addressing a topic.',
        content: 'Write a professional email about...',
      ),
      _TemplateItem(
        title: 'Social Caption',
        icon: Icons.alternate_email,
        desc: 'Create a catchy social media caption.',
        content: 'Create a social media caption for...',
      ),
      _TemplateItem(
        title: 'Blog Post Outline',
        icon: Icons.article_outlined,
        desc: 'Create an outline for a new blog post.',
        content: 'Write a blog post about...',
      ),
    ],
    'Business': [
      _TemplateItem(
        title: 'Business Plan',
        icon: Icons.trending_up_outlined,
        desc: 'Create a detailed business plan outline.',
        content: 'Create a business plan for...',
      ),
      _TemplateItem(
        title: 'Marketing Strategy',
        icon: Icons.campaign_outlined,
        desc: 'Write a marketing go-to-market strategy.',
        content: 'Write a marketing strategy for...',
      ),
      _TemplateItem(
        title: 'Formal Proposal',
        icon: Icons.description_outlined,
        desc: 'Draft a professional business proposal.',
        content: 'Draft a professional proposal for...',
      ),
    ],
  };

  String _selectedCategory = 'General';

  void _useTemplate(String content, String category) {
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    templateProvider.setTemplate(content, category);

    Navigator.of(context).pushAndRemoveUntil(
      PlatformUtils.adaptivePageRoute(const HomeScreen()),
      (route) => false,
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Image Generation':
        return AppColors.categoryImageGeneration;
      case 'Coding':
        return AppColors.categoryCoding;
      case 'Writing':
        return AppColors.categoryWriting;
      case 'Business':
        return AppColors.categoryBusiness;
      default:
        return AppColors.categoryGeneral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _templatesMap.keys.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isSmallScreen = screenWidth < 360;
    final isCupertino = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

    return Scaffold(
      appBar: AdaptiveAppBar(title: 'Templates'),
      body: Column(
        children: [
          if (isCupertino)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing12,
              ),
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
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing8),
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
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  final color = _getCategoryColor(cat);
                  return Padding(
                    padding: const EdgeInsets.only(right: AppConstants.spacing8, bottom: AppConstants.spacing8),
                    child: FilterChip(
                      avatar: Icon(
                        _getCategoryIcon(cat),
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                      },
                      backgroundColor: theme.colorScheme.surface,
                      selectedColor: color,
                      side: BorderSide(
                        color: isSelected ? color : AppColors.borderLight,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusChip),
                      ),
                    ),
                  );
                },
              ),
            ),
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
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Image Generation':
        return Icons.palette_outlined;
      case 'Coding':
        return Icons.code_outlined;
      case 'Writing':
        return Icons.edit_outlined;
      case 'Business':
        return Icons.business_center_outlined;
      default:
        return Icons.public_outlined;
    }
  }

  Widget _buildTemplatesGrid(
    List<_TemplateItem> templates,
    String category,
    ThemeData theme,
    bool isTablet,
    bool isSmallScreen,
  ) {
    final categoryColor = _getCategoryColor(category);

    return GridView.builder(
      padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing16,
        mainAxisSpacing: isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing16,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final t = templates[index];
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppColors.cardShadowLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? AppConstants.spacing12 : AppConstants.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacing8),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          t.icon,
                          size: isSmallScreen ? 22 : 28,
                          color: categoryColor,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? AppConstants.spacing8 : AppConstants.spacing12),
                      Text(
                        t.title,
                        style: AppTextStyles.subtitle.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: isSmallScreen ? 13 : 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.desc,
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
                onTap: () => _useTemplate(t.content, category),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? AppConstants.spacing8 : AppConstants.spacing12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppConstants.radiusCard),
                    ),
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

class _TemplateItem {
  final String title;
  final IconData icon;
  final String desc;
  final String content;

  _TemplateItem({
    required this.title,
    required this.icon,
    required this.desc,
    required this.content,
  });
}
