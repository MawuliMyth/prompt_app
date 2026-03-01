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
import '../../core/utils/date_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/platform_utils.dart';
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
    setState(() {}); // Rebuild to update clear button visibility

    // Debounce search to avoid excessive filtering
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

    return SafeArea(
      child: Scaffold(
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

                // Limit prompts for free users
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
                        // Show upgrade banner for free users with limited history
                        if (isLimited) _buildLimitBanner(theme, allPrompts.length),
                        Expanded(
                           child: displayPrompts.isEmpty
                             ? _buildEmptyHistory(theme)
                             : ListView.builder(
                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, PromptProvider provider) {
     return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: TextField(
           controller: _searchController,
           decoration: InputDecoration(
              hintText: 'Search prompts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                 ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                         _debounceTimer?.cancel();
                         _searchController.clear();
                         provider.setSearchQuery('');
                      },
                   )
                 : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
           ),
        ),
     );
  }

  Widget _buildFilters(ThemeData theme, PromptProvider provider) {
     return SizedBox(
        height: 50,
        child: ListView.builder(
           scrollDirection: Axis.horizontal,
           padding: const EdgeInsets.symmetric(horizontal: 20),
           itemCount: _categories.length,
           itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = provider.selectedCategoryFilter == cat;

               return Padding(
                 padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                 child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                       provider.setCategoryFilter(cat);
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                 ),
               );
           },
        )
     );
  }

  Widget _buildLimitBanner(ThemeData theme, int totalPrompts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing $_freeUserHistoryLimit of $totalPrompts prompts',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upgrade to Premium for unlimited history',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
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
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Upgrade',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: ShimmerCard(height: 120),
      ),
    );
  }

  Widget _buildEmptyHistory(ThemeData theme) {
     return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.history_toggle_off, size: 80, color: AppColors.dividerLight),
             const SizedBox(height: 24),
             Text(
                'No prompts found',
                style: AppTextStyles.headingMedium.copyWith(color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center,
             ),
             const SizedBox(height: 8),
             Text(
                'Start creating prompts from the Home tab!',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
             )
           ],
        ),
     );
  }

  Widget _buildGuestEmptyState(ThemeData theme) {
      return SingleChildScrollView(
         padding: const EdgeInsets.all(32.0),
         child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                 width: 120,
                 height: 120,
                 decoration: BoxDecoration(
                   color: AppColors.primaryLight.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(
                   Icons.history,
                   size: 60,
                   color: AppColors.primaryLight,
                 ),
               ),
              const SizedBox(height: 32),
              Text(
                'Sign in to view your prompt history',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your history connects across all devices and stays safely backed up.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                 onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                 },
                 style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                 ),
                 child: const Text('Sign In'),
              )
           ],
         ),
      );
  }
}

class PromptHistoryCard extends StatelessWidget {
   final PromptModel prompt;
   final VoidCallback onDelete;

   const PromptHistoryCard({super.key, required this.prompt, required this.onDelete});

   String _getEmojiForCategory(String category) {
      switch(category) {
         case 'Image Generation': return '🎨';
         case 'Coding': return '💻';
         case 'Writing': return '✍️';
         case 'Business': return '📊';
         default: return '🌐';
      }
   }

   Color _getScoreColor(int score) {
      if (score >= 80) return Colors.green;
      if (score >= 60) return Colors.blue;
      if (score >= 40) return Colors.orange;
      return Colors.red;
   }

   @override
   Widget build(BuildContext context) {
      final theme = Theme.of(context);

      return Dismissible(
         key: Key(prompt.id),
         direction: DismissDirection.endToStart,
         background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
               color: Colors.red.shade400,
               borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
               Icons.delete,
               color: Colors.white,
               size: 28,
            ),
         ),
         confirmDismiss: (direction) async {
            return await showDialog(
               context: context,
               builder: (context) => AlertDialog(
                  title: Text('Delete Prompt?', style: AppTextStyles.headingMedium),
                  content: Text('This action cannot be undone.', style: AppTextStyles.body),
                  actions: [
                     TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textSecondaryLight)),
                     ),
                     TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete', style: AppTextStyles.button.copyWith(color: Colors.red)),
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
                  backgroundColor: AppColors.primaryLight,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
               ),
            );
         },
         child: GestureDetector(
            onTap: () {
                Navigator.of(context).push(
                   MaterialPageRoute(builder: (_) => ResultScreen(
                      originalText: prompt.originalText,
                      enhancedPrompt: prompt.enhancedPrompt,
                      category: prompt.category,
                      existingPrompt: prompt, // Pass existing prompt to prevent duplicate save
                   ))
                );
            },
            child: Container(
               margin: const EdgeInsets.only(bottom: 16),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerLight),
               ),
               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(AppDateUtils.formatDateTime(prompt.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight)),
                           Row(
                              children: [
                                 Text(_getEmojiForCategory(prompt.category), style: const TextStyle(fontSize: 16)),
                                 const SizedBox(width: 4),
                                 Text(prompt.category, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight, fontWeight: FontWeight.bold)),
                              ],
                           )
                        ],
                     ),
                     const SizedBox(height: 12),
                     Text(prompt.originalText, style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                     const SizedBox(height: 8),
                     Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                           color: theme.colorScheme.surface,
                           borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                           children: [
                              Container(
                                 width: 32,
                                 height: 32,
                                 decoration: BoxDecoration(
                                    color: _getScoreColor(prompt.strengthScore).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                 ),
                                 child: Center(
                                    child: Text('${prompt.strengthScore}', style: AppTextStyles.caption.copyWith(color: _getScoreColor(prompt.strengthScore), fontWeight: FontWeight.bold)),
                                 ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                 child: Text(prompt.enhancedPrompt, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryLight), maxLines: 2, overflow: TextOverflow.ellipsis),
                              )
                           ],
                        ),
                     )
                  ],
               ),
            ),
         ),
      );
   }
}
