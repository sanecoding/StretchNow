import 'package:flutter/material.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/widgets/motion_painters.dart';

/// Plays the animated motion demonstration for any [StretchExercise].
class ExerciseMotionPlayer extends StatefulWidget {
  final StretchExercise exercise;
  final MotionCue? cueOverride;
  final bool isPlaying;
  final bool isPreview;
  final bool compact;
  final double? cycleDurationSeconds;
  final double? externalProgress;
  final double speedMultiplier;
  final Color? primaryColor;
  final Color? accentColor;
  final String? phaseBadgeText;
  final double height;
  final BorderRadius? borderRadius;

  const ExerciseMotionPlayer({
    super.key,
    required this.exercise,
    this.cueOverride,
    this.isPlaying = true,
    this.isPreview = true,
    this.compact = false,
    this.cycleDurationSeconds,
    this.externalProgress,
    this.speedMultiplier = 1.0,
    this.primaryColor,
    this.accentColor,
    this.phaseBadgeText,
    this.height = 220,
    this.borderRadius,
  });

  @override
  State<ExerciseMotionPlayer> createState() => _ExerciseMotionPlayerState();
}

class _ExerciseMotionPlayerState extends State<ExerciseMotionPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration _effectiveDuration() {
    final baseSec =
        widget.cycleDurationSeconds ?? widget.exercise.previewCycleSeconds;
    final adjustedMs =
        ((baseSec / widget.speedMultiplier.clamp(0.4, 2.5)) * 1000).round();
    return Duration(milliseconds: adjustedMs.clamp(350, 30000));
  }

  MotionCue get _activeCue =>
      widget.cueOverride ?? widget.exercise.previewOptions.first.cue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _effectiveDuration(),
    );
    if (widget.externalProgress == null && widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseMotionPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newDuration = _effectiveDuration();
    if (_controller.duration != newDuration) {
      final currentVal = _controller.value;
      _controller.duration = newDuration;
      if (widget.externalProgress == null && widget.isPlaying) {
        _controller.forward(from: currentVal);
        _controller.repeat();
      }
    }

    if (widget.externalProgress != null) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.primaryColor ?? colorScheme.primary;
    final accent = widget.accentColor ?? const Color(0xFF14B8A6);
    final radius =
        widget.borderRadius ?? BorderRadius.circular(widget.compact ? 14 : 24);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: isDark ? 0.16 : 0.10),
              accent.withValues(alpha: isDark ? 0.10 : 0.06),
            ],
          ),
          borderRadius: radius,
          border: Border.all(
            color: primary.withValues(alpha: isDark ? 0.24 : 0.16),
          ),
        ),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress =
                  (widget.externalProgress ?? _controller.value).clamp(0.0, 1.0);
              final liveLabel = widget.phaseBadgeText ??
                  _livePhaseBadge(_activeCue, progress);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: EdgeInsets.all(widget.compact ? 4 : 12),
                    child: CustomPaint(
                      painter: ExerciseMotionPainter(
                        motionId: widget.exercise.motionId,
                        cue: _activeCue,
                        progress: progress,
                        primaryColor: primary,
                        accentColor: accent,
                        isDark: isDark,
                        compact: widget.compact,
                        isPreview: widget.isPreview,
                      ),
                    ),
                  ),
                  if (!widget.compact && liveLabel != null)
                    Positioned(
                      top: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.isPlaying
                                    ? accent
                                    : colorScheme.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              liveLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String? _livePhaseBadge(MotionCue cue, double t) {
    switch (cue) {
      case MotionCue.twistCycle:
        return t < 0.5 ? 'LEFT SIDE' : 'RIGHT SIDE';
      case MotionCue.twistLeft:
        return 'DROP KNEES LEFT';
      case MotionCue.twistRight:
        return 'DROP KNEES RIGHT';
      case MotionCue.hollowHold:
        return 'LOWER BACK DOWN';
      case MotionCue.restFlat:
        return 'REST FLAT';
      case MotionCue.bridge:
        return t < 0.5 ? 'LIFT HIPS' : 'CONTROLLED LOWER';
      case MotionCue.proneYtwCycle:
        if (t < 1 / 3) return 'Y SHAPE';
        if (t < 2 / 3) return 'T SHAPE';
        return 'W SHAPE';
      case MotionCue.proneY:
        return 'Y SHAPE';
      case MotionCue.proneT:
        return 'T SHAPE';
      case MotionCue.proneW:
        return 'W SHAPE';
      case MotionCue.pushupKnees:
        return 'KNEES DOWN';
      case MotionCue.pushupStandard:
        return 'STANDARD';
      case MotionCue.pushupElevated:
        return 'FEET ELEVATED';
      case MotionCue.plankHold:
        return 'STRAIGHT LINE';
      case MotionCue.childsPoseToCobra:
        return (t < 0.25 || t > 0.75) ? 'CHILD\'S POSE' : 'COBRA LIFT';
      case MotionCue.neckCycle:
        if (t < 0.16) return 'TURN RIGHT';
        if (t < 0.32) return 'TURN LEFT';
        if (t < 0.48) return 'EAR TO RIGHT';
        if (t < 0.64) return 'EAR TO LEFT';
        return 'SLOW ROLL (F-R-B-L)';
      case MotionCue.neckTurnRight:
        return 'TURN RIGHT';
      case MotionCue.neckTurnLeft:
        return 'TURN LEFT';
      case MotionCue.neckTiltRight:
        return 'EAR TO RIGHT';
      case MotionCue.neckTiltLeft:
        return 'EAR TO LEFT';
      case MotionCue.neckRoll:
        return 'SLOW ROLL (F-R-B-L)';
      case MotionCue.toeTouchAlternating:
        return (t < 0.25 || t >= 0.75)
            ? 'RIGHT HAND → LEFT TOE'
            : 'LEFT HAND → RIGHT TOE';
      case MotionCue.itBandAlternating:
        return t < 0.5 ? 'LEFT IT BAND' : 'RIGHT IT BAND';
      case MotionCue.itBandLeft:
        return 'LEFT IT BAND';
      case MotionCue.itBandRight:
        return 'RIGHT IT BAND';
      case MotionCue.skippingScissors:
        return 'STEADY RHYTHM';
      case MotionCue.squats:
        return t < 0.5 ? 'SIT BACK & DOWN' : 'DRIVE UP';
    }
  }
}
