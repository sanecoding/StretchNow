import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/widgets/exercise_motion_player.dart';

Future<void> showExerciseDetailSheet({
  required BuildContext context,
  required StretchExercise exercise,
  required RoutineTier activeTier,
  required bool isFavorite,
  required VoidCallback onToggleFavorite,
  ValueChanged<RoutineTier>? onSelectTier,
  required ValueChanged<RoutineTier> onPlaySingle,
  required ValueChanged<RoutineTier> onStartFromHere,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExerciseDetailSheet(
      exercise: exercise,
      activeTier: activeTier,
      initialIsFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
      onSelectTier: onSelectTier,
      onPlaySingle: onPlaySingle,
      onStartFromHere: onStartFromHere,
    ),
  );
}

class _ExerciseDetailSheet extends StatefulWidget {
  final StretchExercise exercise;
  final RoutineTier activeTier;
  final bool initialIsFavorite;
  final VoidCallback onToggleFavorite;
  final ValueChanged<RoutineTier>? onSelectTier;
  final ValueChanged<RoutineTier> onPlaySingle;
  final ValueChanged<RoutineTier> onStartFromHere;

  const _ExerciseDetailSheet({
    required this.exercise,
    required this.activeTier,
    required this.initialIsFavorite,
    required this.onToggleFavorite,
    this.onSelectTier,
    required this.onPlaySingle,
    required this.onStartFromHere,
  });

  @override
  State<_ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<_ExerciseDetailSheet> {
  late RoutineTier _selectedTier;
  late MotionCue _selectedCue;
  late bool _isFavorite;
  bool _isPlaying = true;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.activeTier;
    _selectedCue = widget.exercise.previewCueFor(widget.activeTier);
    _isFavorite = widget.initialIsFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ex = widget.exercise;
    final tierColor = _selectedTier.accentColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ex.block.accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '#${ex.number} · ${ex.block.title}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ex.block.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ex.focusArea,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                      widget.onToggleFavorite();
                    },
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color:
                          _isFavorite ? Colors.redAccent : colorScheme.outline,
                    ),
                    tooltip: _isFavorite
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                ex.name,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),

              // Live interactive motion player
              ExerciseMotionPlayer(
                exercise: ex,
                cueOverride: _selectedCue,
                isPlaying: _isPlaying,
                isPreview: true,
                speedMultiplier: _speed,
                primaryColor: tierColor,
                height: 195,
              ),

              const SizedBox(height: 10),

              // Playback controls + speed on one clean scrollable strip if narrow
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _isPlaying = !_isPlaying),
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(_isPlaying ? 'Pause' : 'Play'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final s in [0.75, 1.0, 1.25])
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: ChoiceChip(
                                  label: Text('${s == 1.0 ? '1' : s}×'),
                                  selected: _speed == s,
                                  onSelected: (_) => setState(() => _speed = s),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Phase / variant switcher chips in a single horizontal strip
              if (ex.previewOptions.length > 1) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ex.previewOptions.map((opt) {
                      final selected = opt.cue == _selectedCue;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(opt.label),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedCue = opt.cue),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Form cue card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  ex.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 4-Option Prescription Comparison
              Text(
                'Options',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              for (final pair in const [
                [RoutineTier.halfway, RoutineTier.sweatless],
                [RoutineTier.sweaty, RoutineTier.intense],
              ]) ...[
                Row(
                  children: [
                    for (var i = 0; i < pair.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _TierSummaryTile(
                          tier: pair[i],
                          prescription: ex.forTier(pair[i]),
                          isCurrent: pair[i] == _selectedTier,
                          onTap: () {
                            setState(() => _selectedTier = pair[i]);
                            widget.onSelectTier?.call(pair[i]);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onPlaySingle(_selectedTier);
                      },
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Play Move'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onStartFromHere(_selectedTier);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Start From #${ex.number}'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: tierColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TierSummaryTile extends StatelessWidget {
  final RoutineTier tier;
  final TierPrescription prescription;
  final bool isCurrent;
  final VoidCallback onTap;

  const _TierSummaryTile({
    required this.tier,
    required this.prescription,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isCurrent
          ? tier.accentColor.withValues(alpha: 0.14)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrent
              ? tier.accentColor
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tier.badge} · ${tier.label}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isCurrent
                      ? tier.accentColor
                      : colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                prescription.variantTag != null
                    ? '${prescription.targetSummary} · ${prescription.variantTag}'
                    : prescription.targetSummary,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
