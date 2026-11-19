import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/widgets/exercise_motion_player.dart';
import 'package:stretchnow/features/home/home_view_model.dart';

class RoutinePlayerScreen extends StatefulWidget {
  final List<StretchExercise> exercises;
  final int initialIndex;
  final RoutineTier tier;
  final String sessionTitle;

  const RoutinePlayerScreen({
    super.key,
    required this.exercises,
    this.initialIndex = 0,
    required this.tier,
    this.sessionTitle = 'Full Routine',
  });

  @override
  State<RoutinePlayerScreen> createState() => _RoutinePlayerScreenState();
}

class _RoutinePlayerScreenState extends State<RoutinePlayerScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _lastTick;

  late int _exerciseIndex;
  int _stepIndex = 0;

  bool _isInPrep = false;
  double _prepElapsed = 0;
  int _prepDuration = 5;

  double _stepElapsed = 0;
  int _completedRepsInStep = 0;
  bool _manualRepMode = false;

  bool _isPaused = false;
  bool _isFinished = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  double _totalActiveSeconds = 0;
  int _exercisesCompletedInRun = 0;

  @override
  void initState() {
    super.initState();
    final homeVm = context.read<HomeViewModel>();
    _prepDuration = homeVm.prepSeconds;
    _soundEnabled = homeVm.soundCueEnabled;
    _vibrationEnabled = homeVm.vibrationEnabled;

    _exerciseIndex =
        widget.initialIndex.clamp(0, widget.exercises.length - 1);
    _initExercise(usePrep: _prepDuration > 0);

    _ticker = createTicker(_onTick)..start();
  }

  StretchExercise get _exercise => widget.exercises[_exerciseIndex];
  TierPrescription get _prescription => _exercise.forTier(widget.tier);
  List<ExercisePhaseStep> get _steps => _prescription.steps;
  ExercisePhaseStep get _step => _steps[_stepIndex];

  void _initExercise({required bool usePrep}) {
    _stepIndex = 0;
    _stepElapsed = 0;
    _completedRepsInStep = 0;
    _isInPrep = usePrep && _prepDuration > 0;
    _prepElapsed = 0;
    _lastTick = null;
  }

  void _onTick(Duration elapsed) {
    if (_isPaused || _isFinished) {
      _lastTick = elapsed;
      return;
    }

    final dt = _lastTick == null
        ? 0.0
        : ((elapsed - _lastTick!).inMicroseconds / 1000000.0)
            .clamp(0.0, 0.1);
    _lastTick = elapsed;
    if (dt <= 0) return;

    if (_isInPrep) {
      setState(() {
        _prepElapsed += dt;
        if (_prepElapsed >= _prepDuration) {
          _isInPrep = false;
          _stepElapsed = 0;
          _playCue(strong: true);
        }
      });
      return;
    }

    _totalActiveSeconds += dt;

    if (_step.isRepBased) {
      if (_manualRepMode) return;
      setState(() {
        _stepElapsed += dt;
        final repsNow = (_stepElapsed / _step.secondsPerRep).floor();
        if (repsNow > _completedRepsInStep) {
          _completedRepsInStep = repsNow;
          if (_completedRepsInStep >= _step.targetReps) {
            _advanceStepOrExercise();
          } else {
            _playCue(strong: false);
          }
        }
      });
    } else {
      setState(() {
        _stepElapsed += dt;
        if (_stepElapsed >= _step.durationSeconds) {
          _advanceStepOrExercise();
        }
      });
    }
  }

  Future<void> _playCue({required bool strong}) async {
    try {
      if (_soundEnabled) {
        await SystemSound.play(SystemSoundType.click);
      }
      if (_vibrationEnabled) {
        if (strong) {
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.selectionClick();
        }
      }
    } catch (_) {
      // Ignore on unsupported desktop/web platforms
    }
  }

  void _advanceStepOrExercise() {
    if (_stepIndex + 1 < _steps.length) {
      _stepIndex++;
      _stepElapsed = 0;
      _completedRepsInStep = 0;
      _playCue(strong: true);
      return;
    }
    _completeCurrentExercise();
  }

  void _completeCurrentExercise() {
    final completedId = _exercise.id;
    _exercisesCompletedInRun++;
    context.read<HomeViewModel>().markExerciseDone(completedId);
    _playCue(strong: true);

    if (_exerciseIndex + 1 < widget.exercises.length) {
      setState(() {
        _exerciseIndex++;
        _initExercise(usePrep: _prepDuration > 0);
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  void _skipCurrentExercise() {
    if (_exerciseIndex + 1 < widget.exercises.length) {
      setState(() {
        _exerciseIndex++;
        _initExercise(usePrep: _prepDuration > 0);
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  void _goPreviousExercise() {
    if (_exerciseIndex > 0) {
      setState(() {
        _exerciseIndex--;
        _initExercise(usePrep: false);
      });
    } else {
      setState(() {
        _initExercise(usePrep: false);
      });
    }
  }

  void _incrementManualRep() {
    if (!_step.isRepBased) return;
    _playCue(strong: false);
    setState(() {
      _completedRepsInStep++;
      if (_completedRepsInStep >= _step.targetReps) {
        _advanceStepOrExercise();
      }
    });
  }

  double? _resolveExternalProgress() {
    if (_isInPrep) return null;
    if (_step.isRepBased) {
      if (_manualRepMode) return null;
      return ((_stepElapsed % _step.secondsPerRep) / _step.secondsPerRep)
          .clamp(0.0, 1.0);
    }
    final cue = _step.motionCue;
    if (cue == MotionCue.twistLeft ||
        cue == MotionCue.twistRight ||
        cue == MotionCue.hollowHold ||
        cue == MotionCue.restFlat ||
        cue == MotionCue.neckTurnRight ||
        cue == MotionCue.neckTurnLeft ||
        cue == MotionCue.neckTiltRight ||
        cue == MotionCue.neckTiltLeft ||
        cue == MotionCue.neckRoll) {
      final total = _step.durationSeconds.clamp(1, 300);
      return (_stepElapsed / total).clamp(0.0, 1.0);
    }
    return null;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isFinished) {
      return _buildFinishedView(context, theme, colorScheme);
    }

    final tierColor = widget.tier.accentColor;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Exit Routine',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sessionTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Exercise ${_exerciseIndex + 1} of ${widget.exercises.length} · ${_exercise.block.title}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: tierColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '${widget.tier.badge} · ${widget.tier.label}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tierColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => setState(() {
                          _soundEnabled = !_soundEnabled;
                        }),
                        icon: Icon(
                          _soundEnabled
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          size: 20,
                        ),
                        tooltip: _soundEnabled ? 'Mute cues' : 'Enable cues',
                      ),
                    ],
                  ),
                ),

                // Segmented progress strip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: List.generate(widget.exercises.length, (idx) {
                      final done = idx < _exerciseIndex;
                      final active = idx == _exerciseIndex;
                      return Expanded(
                        child: Container(
                          height: 4.5,
                          margin: EdgeInsets.only(
                            right: idx == widget.exercises.length - 1 ? 0 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: done
                                ? const Color(0xFF22C55E)
                                : active
                                    ? tierColor
                                    : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: _isInPrep
                        ? _buildPrepBody(context, theme, colorScheme, tierColor)
                        : _buildActiveBody(
                            context, theme, colorScheme, tierColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrepBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Color tierColor,
  ) {
    final prepLeft =
        (_prepDuration - _prepElapsed).ceil().clamp(0, _prepDuration);
    final prepFrac =
        (1 - (_prepElapsed / _prepDuration.clamp(1, 30))).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'GET READY · EXERCISE #${_exercise.number}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _exercise.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_prescription.detailText} · ${_exercise.focusArea}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ExerciseMotionPlayer(
          exercise: _exercise,
          cueOverride: _steps.first.motionCue,
          isPlaying: !_isPaused,
          isPreview: true,
          primaryColor: tierColor,
          height: 180,
          phaseBadgeText: 'UP NEXT',
        ),
        const SizedBox(height: 12),
        Text(
          _exercise.shortCue,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: CircularProgressIndicator(
                  value: prepFrac,
                  strokeWidth: 6.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                ),
              ),
              Text(
                '${prepLeft}s',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _skipCurrentExercise,
                child: const Text('Skip Move'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isInPrep = false;
                    _stepElapsed = 0;
                    _playCue(strong: true);
                  });
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Start Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Color tierColor,
  ) {
    final step = _step;
    final activeAccent =
        step.isRest ? const Color(0xFF14B8A6) : tierColor;

    final double ringProgress;
    final String primaryCounter;
    final String counterSubLabel;

    if (step.isRepBased) {
      final total = step.targetReps.clamp(1, 100);
      final doneReps = _completedRepsInStep.clamp(0, total);
      final fracRep = _manualRepMode
          ? 0.0
          : ((_stepElapsed / step.secondsPerRep) - doneReps).clamp(0.0, 1.0);
      ringProgress = ((doneReps + fracRep) / total).clamp(0.0, 1.0);
      primaryCounter = '$doneReps/$total';
      counterSubLabel = _manualRepMode ? 'tap per rep' : 'auto-paced reps';
    } else {
      final total = step.durationSeconds.clamp(1, 300);
      final remaining = (total - _stepElapsed).ceil().clamp(0, total);
      ringProgress = ((total - _stepElapsed) / total).clamp(0.0, 1.0);
      primaryCounter = '${remaining}s';
      counterSubLabel = step.isRest ? 'rest & breathe' : 'hold / flow';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & block badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '#${_exercise.number} · ${_exercise.focusArea}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: activeAccent,
                ),
              ),
            ),
            if (_prescription.variantTag != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _prescription.variantTag!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _exercise.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),

        // Live Motion Stage
        ExerciseMotionPlayer(
          exercise: _exercise,
          cueOverride: step.motionCue,
          isPlaying: !_isPaused,
          isPreview: false,
          cycleDurationSeconds:
              step.isRepBased ? step.secondsPerRep : _exercise.previewCycleSeconds,
          externalProgress: _resolveExternalProgress(),
          primaryColor: activeAccent,
          height: 205,
          phaseBadgeText: step.title.toUpperCase(),
        ),

        // Sub-step indicator strip if multiple steps (Y-T-W, Neck rounds, Hollow sets, etc.)
        if (_steps.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            children: List.generate(_steps.length, (i) {
              final isDone = i < _stepIndex;
              final isCurrent = i == _stepIndex;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i == _steps.length - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF22C55E)
                        : isCurrent
                            ? activeAccent
                            : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              );
            }),
          ),
        ],

        const SizedBox(height: 12),

        // Compact dashboard card: Progress Ring + Step Cue & Rep Mode
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: CircularProgressIndicator(
                      value: ringProgress,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(activeAccent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        primaryCounter,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: step.isRepBased ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        counterSubLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: activeAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.instruction,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    if (step.isRepBased) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: Text(
                              _manualRepMode ? 'Manual Tap' : 'Auto-Paced',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            avatar: Icon(
                              _manualRepMode
                                  ? Icons.touch_app_rounded
                                  : Icons.autorenew_rounded,
                              size: 14,
                            ),
                            selected: !_manualRepMode,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) {
                              setState(() {
                                _manualRepMode = !_manualRepMode;
                              });
                            },
                          ),
                          if (_manualRepMode)
                            FilledButton.tonalIcon(
                              onPressed: _incrementManualRep,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Rep Done'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Transport Controls
        Row(
          children: [
            IconButton.outlined(
              onPressed: _goPreviousExercise,
              icon: const Icon(Icons.skip_previous_rounded),
              tooltip: 'Previous exercise',
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _isPaused = !_isPaused;
                  });
                },
                icon: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(_isPaused ? 'Resume' : 'Pause'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _completeCurrentExercise,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  _exerciseIndex + 1 == widget.exercises.length
                      ? 'Finish'
                      : 'Done',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: activeAccent,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: _skipCurrentExercise,
              icon: const Icon(Icons.skip_next_rounded),
              tooltip: 'Skip exercise',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinishedView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final homeVm = context.watch<HomeViewModel>();
    final elapsedText = StretchExercise.formatDuration(
      _totalActiveSeconds.round().clamp(1, 7200),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22C55E),
                        size: 56,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Routine Complete!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nice work moving your body through ${widget.sessionTitle} (${widget.tier.label}).',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _CompleteStat(
                          label: 'Completed',
                          value: '$_exercisesCompletedInRun',
                          icon: Icons.fitness_center_rounded,
                          color: widget.tier.accentColor,
                        ),
                        _CompleteStat(
                          label: 'Time',
                          value: elapsedText,
                          icon: Icons.timer_outlined,
                          color: const Color(0xFF14B8A6),
                        ),
                        _CompleteStat(
                          label: 'Streak',
                          value: '${homeVm.currentStreak}d',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFEA580C),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Back to Routine',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CompleteStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
