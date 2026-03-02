import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prompt_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/adaptive_widgets.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../history/history_screen.dart'; // Reuse PromptHistoryCard
import '../auth/login_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final promptProvider = Provider.of<PromptProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AdaptiveAppBar(title: 'Favourites'),
        body: !authProvider.isAuthenticated
            ? _buildGuestEmptyState(context, theme)
            : promptProvider.isLoading
                ? _buildShimmerLoading()
                : promptProvider.favouritePrompts.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: promptProvider.favouritePrompts.length,
                        itemBuilder: (context, index) {
                          final prompt = promptProvider.favouritePrompts[index];
                          return Stack(
                            children: [
                               PromptHistoryCard(
                                 prompt: prompt,
                                 onDelete: () async {
                                   final success = await promptProvider.deletePrompt(authProvider.currentUser, prompt.id);
                                   if (!success && context.mounted) {
                                     SnackbarUtils.showError(
                                       context,
                                       promptProvider.error ?? 'Failed to delete prompt',
                                     );
                                   }
                                 },
                               ),
                               Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.star, color: Colors.amber, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        final success = await promptProvider.toggleFavourite(authProvider.currentUser, prompt);
                                        if (!success && context.mounted) {
                                          SnackbarUtils.showError(
                                            context,
                                            promptProvider.error ?? 'Failed to update favourite',
                                          );
                                        }
                                      },
                                    ),
                                  ),
                               )
                            ],
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(Icons.star_border, size: 80, color: AppColors.dividerLight),
          const SizedBox(height: 24),
          Text(
            'No favourites yet',
            style: AppTextStyles.headingMedium.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Star a prompt to save it here!',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondaryLight),
          )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: List.generate(
          5,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerCard(height: 120),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestEmptyState(BuildContext context, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Flexible(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_border,
                  size: 60,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Sign in to see favourites",
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Create an account to keep your favourite prompts handy across all your devices.",
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
          ),
        ),
      ],
    );
  }
}
