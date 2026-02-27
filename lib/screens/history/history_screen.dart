import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prompt_provider.dart';
import '../../data/models/prompt_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../result/result_screen.dart';
import '../auth/login_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Image Generation', 'Coding', 'Writing', 'Business', 'General'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final promptProvider = Provider.of<PromptProvider>(context, listen: false);
       promptProvider.setSearchQuery('');
       promptProvider.setCategoryFilter('All');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showClearAllConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear History?', style: AppTextStyles.headingMedium),
        content: Text('This action cannot be undone. Are you sure you want to delete all your prompt history?', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textSecondaryLight)),
          ),
          TextButton(
             onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                Provider.of<PromptProvider>(context, listen: false).clearAllHistory(authProvider.currentUser);
                Navigator.pop(context);
             },
             child: Text('Clear All', style: AppTextStyles.button.copyWith(color: Colors.red)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
           title: Text('History', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primaryLight)),
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
          : Consumer<PromptProvider>(
              builder: (context, promptProvider, _) {
                return promptProvider.isLoading
                  ? _buildShimmerLoading()
                  : Column(
                      children: [
                        _buildSearchBar(theme, promptProvider),
                        _buildFilters(theme, promptProvider),
                        Expanded(
                           child: promptProvider.prompts.isEmpty
                             ? _buildEmptyHistory(theme)
                             : ListView.builder(
                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                 itemCount: promptProvider.prompts.length,
                                 itemBuilder: (context, index) {
                                    final prompt = promptProvider.prompts[index];
                                    return PromptHistoryCard(prompt: prompt);
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
           onChanged: (val) => provider.setSearchQuery(val),
           decoration: InputDecoration(
              hintText: 'Search prompts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                 ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
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

   const PromptHistoryCard({super.key, required this.prompt});

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

      return GestureDetector(
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
         onLongPress: () {
             // Show options: Copy, Share, Favourite, Delete
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
      );
   }
}
