import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/widgets/exercise_detail_sheet.dart';
import 'package:stretchnow/core/widgets/exercise_motion_player.dart';
import 'package:stretchnow/features/home/home_view_model.dart';
import 'package:stretchnow/features/routine/routine_player_screen.dart';
import 'package:stretchnow/features/schedule/schedule_view_model.dart';
import 'package:stretchnow/features/stretches/stretches_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer2<HomeViewModel, StretchesViewModel>(
        builder: (context, homeVm, stretchesVm, _) {
          final todayStr = DateFormat('EEEE, MMM d').format(DateTime.now());
          final selectedTier = homeVm.selectedTier;
          final tierColor = selectedTier.accentColor;
          final currentEx = homeVm.currentExercise;
          final currentPresc = currentEx.forTier(selectedTier);
          final completedCount = homeVm.completedExerciseCount;
          final totalCount = homeVm.totalExerciseCount;
          final allDoneToday = completedCount >= totalCount;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                homeVm.greeting,
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Builder(
                                builder: (context) {
                                  final scheduleVm =
                                      context.watch<ScheduleViewModel>();
                                  final wakeInfo = scheduleVm.reminderEnabled
                                      ? '$todayStr · Wake-up ${scheduleVm.formattedStretchTime}'
                                      : todayStr;
                                  return Text(
                                    wakeInfo,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        _StreakBadge(streak: homeVm.currentStreak),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Tier Selector Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Routine Pace',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '12 moves · ~${homeVm.formattedEstimatedDuration}',
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: tierColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: RoutineTier.values.map((tier) {
                              final isSelected = tier == selectedTier;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: tier == RoutineTier.intense ? 0 : 6,
                                  ),
                                  child: _TierOptionPill(
                                    tier: tier,
                                    isSelected: isSelected,
                                    onTap: () => homeVm.selectTier(tier),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${selectedTier.optionNote} · ${selectedTier.subtitle}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (allDoneToday
                                          ? const Color(0xFF22C55E)
                                          : tierColor)
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '$completedCount / $totalCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: allDoneToday
                                        ? const Color(0xFF22C55E)
                                        : tierColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: (completedCount / totalCount)
                                  .clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                allDoneToday
                                    ? const Color(0xFF22C55E)
                                    : tierColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Hero Routine Launch Card with Live Motion
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tierColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    allDoneToday
                                        ? 'ROUTINE COMPLETE'
                                        : 'UP NEXT · #${currentEx.number}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: tierColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentPresc.targetSummary,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentEx.name,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentEx.shortCue,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => _openExerciseSheet(
                              context,
                              currentEx,
                              homeVm,
                              stretchesVm,
                            ),
                            child: ExerciseMotionPlayer(
                              exercise: currentEx,
                              cueOverride:
                                  currentEx.previewCueFor(selectedTier),
                              isPlaying: true,
                              isPreview: true,
                              primaryColor: tierColor,
                              height: 170,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    var startIdx = homeVm.nextExerciseIndex;
                                    if (allDoneToday) {
                                      await homeVm.resetTodayChecklist();
                                      startIdx = 0;
                                    }
                                    if (!context.mounted) return;
                                    _launchRoutine(
                                      context,
                                      exercises: homeVm.routine,
                                      initialIndex: startIdx,
                                      tier: selectedTier,
                                      title: 'Lazy Full Body Routine',
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(
                                    allDoneToday
                                        ? 'Start Another Round'
                                        : (completedCount > 0
                                            ? 'Resume Routine (#${currentEx.number})'
                                            : 'Start Full Routine'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: tierColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Quick Block Shortcuts
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: RoutineBlock.values.map((block) {
                                final blockExercises =
                                    StretchExercise.byBlock(block);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    avatar: Icon(
                                      block.icon,
                                      size: 16,
                                      color: block.accentColor,
                                    ),
                                    label: Text(
                                      'Play ${block.title}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () => _launchRoutine(
                                      context,
                                      exercises: blockExercises,
                                      initialIndex: 0,
                                      tier: selectedTier,
                                      title: block.title,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Routine Sequence Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Routine Flow (1–12)',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (completedCount > 0)
                          TextButton(
                            onPressed: homeVm.resetTodayChecklist,
                            child: const Text('Clear checks'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Grouped Blocks
                    for (final block in RoutineBlock.values) ...[
                      _BlockHeader(block: block),
                      const SizedBox(height: 8),
                      ...StretchExercise.byBlock(block).map((exercise) {
                        final isDone =
                            homeVm.isExerciseDoneToday(exercise.id);
                        final presc = exercise.forTier(selectedTier);
                        return _RoutineStepTile(
                          exercise: exercise,
                          prescription: presc,
                          tierColor: tierColor,
                          isDone: isDone,
                          onTap: () => _openExerciseSheet(
                            context,
                            exercise,
                            homeVm,
                            stretchesVm,
                          ),
                          onPlayTap: () => _launchRoutine(
                            context,
                            exercises: homeVm.routine,
                            initialIndex: exercise.number - 1,
                            tier: selectedTier,
                            title: 'Lazy Full Body Routine',
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openExerciseSheet(
    BuildContext context,
    StretchExercise exercise,
    HomeViewModel homeVm,
    StretchesViewModel stretchesVm,
  ) {
    showExerciseDetailSheet(
      context: context,
      exercise: exercise,
      activeTier: homeVm.selectedTier,
      isFavorite: stretchesVm.isFavorite(exercise.id),
      onToggleFavorite: () => stretchesVm.toggleFavorite(exercise.id),
      onPlaySingle: () => _launchRoutine(
        context,
        exercises: [exercise],
        initialIndex: 0,
        tier: homeVm.selectedTier,
        title: exercise.name,
      ),
      onStartFromHere: () => _launchRoutine(
        context,
        exercises: homeVm.routine,
        initialIndex: exercise.number - 1,
        tier: homeVm.selectedTier,
        title: 'Lazy Full Body Routine',
      ),
    );
  }

  void _launchRoutine(
    BuildContext context, {
    required List<StretchExercise> exercises,
    required int initialIndex,
    required RoutineTier tier,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutinePlayerScreen(
          exercises: exercises,
          initialIndex: initialIndex,
          tier: tier,
          sessionTitle: title,
        ),
      ),
    );
  }
}

class _TierOptionPill extends StatelessWidget {
  final RoutineTier tier;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierOptionPill({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = tier.accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          children: [
            Text(
              tier.badge,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tier.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockHeader extends StatelessWidget {
  final RoutineBlock block;
  const _BlockHeader({required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: block.accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(block.icon, size: 18, color: block.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${block.title} · ${block.rangeLabel}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: block.accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  block.flowNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineStepTile extends StatelessWidget {
  final StretchExercise exercise;
  final TierPrescription prescription;
  final Color tierColor;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback onPlayTap;

  const _RoutineStepTile({
    required this.exercise,
    required this.prescription,
    required this.tierColor,
    required this.isDone,
    required this.onTap,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF22C55E).withValues(alpha: 0.16)
                      : tierColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isDone
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Color(0xFF22C55E),
                      )
                    : Text(
                        exercise.number.toString().padLeft(2, '0'),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prescription.variantTag != null
                          ? '${exercise.focusArea} · ${prescription.variantTag}'
                          : exercise.focusArea,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  prescription.targetSummary,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: tierColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onPlayTap,
                icon: Icon(
                  Icons.play_circle_fill_rounded,
                  color: tierColor,
                  size: 26,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Start from #${exercise.number}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = streak > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFFF7ED)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFED7AA)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: isActive ? const Color(0xFFEA580C) : colorScheme.outline,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF9A3412) : colorScheme.outline,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
