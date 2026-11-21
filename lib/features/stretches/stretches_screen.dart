import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/widgets/exercise_detail_sheet.dart';
import 'package:stretchnow/core/widgets/exercise_motion_player.dart';
import 'package:stretchnow/core/widgets/routine_tier_selector.dart';
import 'package:stretchnow/features/routine/routine_player_screen.dart';
import 'package:stretchnow/features/stretches/stretches_view_model.dart';

class StretchesScreen extends StatelessWidget {
  const StretchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Consumer<StretchesViewModel>(
              builder: (context, viewModel, _) {
                final exercises = viewModel.filteredExercises;
                final activeTier = viewModel.selectedTier;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exercise Motions',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All 12 full-body routine moves · ${activeTier.label} targets shown',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RoutineTierSelector(
                              selectedTier: activeTier,
                              onSelect: viewModel.selectTier,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // Block & Favorites filter chips
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _FilterChip(
                              label: 'All (12)',
                              isSelected: viewModel.selectedBlock == null &&
                                  !viewModel.favoritesOnly,
                              onTap: viewModel.selectAll,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            ...RoutineBlock.values.map(
                              (block) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterChip(
                                  label: block.title,
                                  isSelected: !viewModel.favoritesOnly &&
                                      viewModel.selectedBlock == block,
                                  onTap: () => viewModel.selectBlock(block),
                                  color: block.accentColor,
                                ),
                              ),
                            ),
                            _FilterChip(
                              label: 'Favorites',
                              isSelected: viewModel.favoritesOnly,
                              onTap: viewModel.selectFavoritesOnly,
                              color: Colors.redAccent,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    if (exercises.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_border_rounded,
                                  size: 48,
                                  color: colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No favorite moves yet.\nTap the heart on any exercise to pin it here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ex = exercises[index];
                              return _ExerciseMotionCard(
                                exercise: ex,
                                activeTier: activeTier,
                                isFavorite: viewModel.isFavorite(ex.id),
                                onFavoriteTap: () =>
                                    viewModel.toggleFavorite(ex.id),
                                onTap: () => showExerciseDetailSheet(
                                  context: context,
                                  exercise: ex,
                                  activeTier: activeTier,
                                  isFavorite: viewModel.isFavorite(ex.id),
                                  onToggleFavorite: () =>
                                      viewModel.toggleFavorite(ex.id),
                                  onSelectTier: viewModel.selectTier,
                                  onPlaySingle: (tier) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => RoutinePlayerScreen(
                                          exercises: [ex],
                                          initialIndex: 0,
                                          tier: tier,
                                          sessionTitle: ex.name,
                                        ),
                                      ),
                                    );
                                  },
                                  onStartFromHere: (tier) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => RoutinePlayerScreen(
                                          exercises: StretchExercise.routine,
                                          initialIndex: ex.number - 1,
                                          tier: tier,
                                          sessionTitle:
                                              'Lazy Full Body Routine',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: exercises.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? color : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ExerciseMotionCard extends StatelessWidget {
  final StretchExercise exercise;
  final RoutineTier activeTier;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _ExerciseMotionCard({
    required this.exercise,
    required this.activeTier,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final presc = exercise.forTier(activeTier);
    final accent = exercise.block.accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${exercise.number.toString().padLeft(2, '0')}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onFavoriteTap,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : colorScheme.outline,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ExerciseMotionPlayer(
                exercise: exercise,
                cueOverride: exercise.previewCueFor(activeTier),
                isPlaying: true,
                isPreview: true,
                compact: true,
                primaryColor: activeTier.accentColor,
                height: double.infinity,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exercise.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.focusArea,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  presc.targetSummary,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: activeTier.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
