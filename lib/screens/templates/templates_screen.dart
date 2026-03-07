import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_icon_mapper.dart';
import '../../core/widgets/page_header.dart';
import '../../data/models/app_config_model.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/shell_provider.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String? _selectedCategoryId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categories = context.read<AppConfigProvider>().templateCategories;
    _selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configProvider = context.watch<AppConfigProvider>();
    final shellProvider = context.read<ShellProvider>();
    final isCupertino = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

    final categories = configProvider.templateCategories;
    final templates = configProvider.templates
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 160),
          children: [
            const PageHeader(
              title: 'Templates',
              subtitle: 'Start with a strong structure, then make it yours.',
            ),
            const SizedBox(height: AppConstants.spacing20),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, separator) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category.id == _selectedCategoryId;
                  return ChoiceChip(
                    label: Text(category.label),
                    avatar: Icon(
                      resolveIcon(category.iconKey, cupertino: isCupertino),
                      size: 16,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                    selected: selected,
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(color: theme.dividerColor),
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedCategoryId = category.id),
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.spacing24),
            ...templates.map((template) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacing16),
                child: _TemplateCard(
                  template: template,
                  onUse: () {
                    shellProvider.openComposer(
                      initialText: template.promptBody,
                      categoryId: template.categoryId,
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onUse});

  final TemplateConfig template;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.dark
            ? AppColors.cardShadowDark
            : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.featureLavender,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusControl,
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded),
              ),
              const Spacer(),
              Text(
                template.isQuick ? 'Quick' : 'Template',
                style: AppTextStyles.caption.copyWith(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing20),
          Text(
            template.title,
            style: AppTextStyles.heading.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            template.summary,
            style: AppTextStyles.body.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: AppConstants.spacing20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(AppConstants.radiusControl),
            ),
            child: Text(
              template.promptBody,
              style: AppTextStyles.body.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacing20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUse,
              child: const Text('Use Template'),
            ),
          ),
        ],
      ),
    );
  }
}
