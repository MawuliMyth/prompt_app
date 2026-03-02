import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prompt_provider.dart';
import '../../providers/premium_provider.dart';
import '../../data/models/prompt_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../result/result_screen.dart';
import '../auth/login_screen.dart';
import '../paywall/paywall_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Image Generation', 'Coding', 'Writing', 'Business', 'General'];
  Timer? _debounceTimer;

  static const int _freeUserHistoryLimit = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final promptProvider = Provider.of<PromptProvider>(context, listen: false);
      promptProvider.setSearchQuery('');
      promptProvider.setCategoryFilter('All');
    });
  }

  void _onSearchChanged() {
    setState(() {});

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final promptProvider = Provider.of<PromptProvider>(context, listen: false);
      promptProvider.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showClearAllConfirm() async {
    final confirmed = await AdaptiveDialog.show(
      context: context,
      title: 'Clear History?',
      content: 'This action cannot be undone. Are you sure you want to delete all your prompt history?',
      cancelText: 'Cancel',
      confirmText: 'Clear All',
      isDestructive: true,
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final promptProvider = Provider.of<PromptProvider>(context, listen: false);
      final success = await promptProvider.clearAllHistory(authProvider.currentUser);
      if (!success && context.mounted) {
        SnackbarUtils.showError(
          context,
          promptProvider.error ?? 'Failed to clear history',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AdaptiveAppBar(
        title: 'History',
        actions: [
          Consumer<PromptProvider>(
            builder: (context, promptProvider, _) {
              if (authProvider.isAuthenticated && promptProvider.prompts.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _showClearAllConfirm,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: !authProvider.isAuthenticated
          ? _buildGuestEmptyState(theme)
          : Consumer2<PromptProvider, PremiumProvider>(
              builder: (context, promptProvider, premiumProvider, _) {
                final hasPremium = premiumProvider.hasPremiumAccess;
                final allPrompts = promptProvider.prompts;

                final displayPrompts = hasPremium
                    ? allPrompts
                    : allPrompts.take(_freeUserHistoryLimit).toList();
                final isLimited = !hasPremium && allPrompts.length > _freeUserHistoryLimit;

                return promptProvider.isLoading
                    ? _buildShimmerLoading()
                    : Column(
                        children: [
                          _buildSearchBar(theme, promptProvider),
                          _buildFilters(theme, promptProvider),
                          if (isLimited) _buildLimitBanner(theme, allPrompts.length),
                          Expanded(
                            child: displayPrompts.isEmpty
                                ? _buildEmptyHistory(theme)
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.spacing24,
                                      vertical: AppConstants.spacing8,
                                    ),
                                    itemCount: displayPrompts.length,
                                    itemBuilder: (context, index) {
                                      final prompt = displayPrompts[index];
                                      return PromptHistoryCard(
                                        prompt: prompt,
                                        onDelete: () async {
                                          final success = await promptProvider.deletePrompt(
                                            authProvider.currentUser,
                                            prompt.id,
                                          );
                                          if (!success && mounted) {
                                            SnackbarUtils.showError(
                                              context,
                                              promptProvider.error ?? 'Failed to delete prompt',
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                          )
                        ],
                      );
              },
            ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, PromptProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing24,
        vertical: AppConstants.spacing12,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search prompts...',
          prefixIcon: const Icon(Icons.search_outlined, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _debounceTimer?.cancel();
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing16,
            vertical: AppConstants.spacing12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme, PromptProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = provider.selectedCategoryFilter == cat;

          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacing8, bottom: AppConstants.spacing8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                provider.setCategoryFilter(cat);
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: AppColors.primaryLight,
              side: BorderSide(
                color: isSelected ? AppColors.primaryLight : AppColors.borderLight,
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
    );
  }

  Widget _buildLimitBanner(ThemeData theme, int totalPrompts) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing24,
        vertical: AppConstants.spacing8,
      ),
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.cardShadowLight,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacing8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing $_freeUserHistoryLimit of $totalPrompts prompts',
                  style: AppTextStyles.subtitle.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upgrade to Premium for unlimited history',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing24,
        vertical: AppConstants.spacing8,
      ),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppConstants.spacing16),
        child: ShimmerCard(height: 120),
      ),
    );
  }

  Widget _buildEmptyHistory(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacing32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 40,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),
          Text(
            'No prompts found',
            style: AppTextStyles.title.copyWith(color: theme.colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            'Start creating prompts from the Home tab',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          )
        ],
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildGuestEmptyState(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacing32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_outlined,
              size: 50,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: AppConstants.spacing32),
          Text(
            'Sign in to view your prompt history',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacing12),
          Text(
            'Your history connects across all devices and stays safely backed up.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacing32),
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Sign In'),
            ),
          )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PromptHistoryCard extends StatelessWidget {
  final PromptModel prompt;
  final VoidCallback onDelete;

  const PromptHistoryCard({
    super.key,
    required this.prompt,
    required this.onDelete,
  });

  IconData _getIconForCategory(String category) {
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

  Color _getColorForCategory(String category) {
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

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.info;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getColorForCategory(prompt.category);

    return Dismissible(
      key: Key(prompt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacing16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spacing20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacing12),
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            ),
            title: Text('Delete Prompt?', style: AppTextStyles.title),
            content: Text(
              'This action cannot be undone.',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.button.copyWith(color: AppColors.textSecondaryLight),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: AppTextStyles.button.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prompt deleted'),
            backgroundColor: theme.colorScheme.onSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                originalText: prompt.originalText,
                enhancedPrompt: prompt.enhancedPrompt,
                category: prompt.category,
                existingPrompt: prompt,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppConstants.spacing16),
          padding: const EdgeInsets.all(AppConstants.spacing16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppColors.cardShadowLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacing8),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForCategory(prompt.category),
                          size: 16,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacing8),
                      Text(
                        prompt.category,
                        style: AppTextStyles.caption.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing8,
                      vertical: AppConstants.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(prompt.strengthScore).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: _getScoreColor(prompt.strengthScore),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${prompt.strengthScore}',
                          style: AppTextStyles.caption.copyWith(
                            color: _getScoreColor(prompt.strengthScore),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacing12),
              Text(
                prompt.originalText,
                style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.spacing8),
              Text(
                prompt.enhancedPrompt,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.spacing8),
              Text(
                AppDateUtils.formatDateTime(prompt.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
