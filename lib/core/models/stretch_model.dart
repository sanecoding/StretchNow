import 'package:flutter/material.dart';

/// User-selectable difficulty / effort tier for the routine.
enum RoutineTier {
  halfway(
    id: 'halfway',
    label: 'Halfway',
    badge: '½',
    optionNote: '½ of Sweatless',
    subtitle: 'Ultra-lazy warm-up · half of level 1',
    accentColor: Color(0xFF14B8A6),
  ),
  sweatless(
    id: 'sweatless',
    label: 'Sweatless',
    badge: '1',
    optionNote: 'Option 1',
    subtitle: 'Gentle full-body stretch & activation',
    accentColor: Color(0xFF8B5CF6),
  ),
  sweaty(
    id: 'sweaty',
    label: 'Sweaty',
    badge: '2',
    optionNote: 'Option 2',
    subtitle: 'Moderate burn & deeper mobility',
    accentColor: Color(0xFFF59E0B),
  ),
  intense(
    id: 'intense',
    label: 'Intense',
    badge: '3',
    optionNote: 'Option 3',
    subtitle: 'High reps, long holds & advanced push-ups',
    accentColor: Color(0xFFEF4444),
  );

  final String id;
  final String label;
  final String badge;
  final String optionNote;
  final String subtitle;
  final Color accentColor;

  const RoutineTier({
    required this.id,
    required this.label,
    required this.badge,
    required this.optionNote,
    required this.subtitle,
    required this.accentColor,
  });

  static RoutineTier fromId(String? id) {
    for (final tier in RoutineTier.values) {
      if (tier.id == id) return tier;
    }
    return RoutineTier.sweatless;
  }
}

/// Flow blocks matching the routine's physical transitions (floor -> plank/flow -> standing).
enum RoutineBlock {
  floorBlock(
    title: 'Floor Block',
    rangeLabel: '#1–5 · Lying & Push',
    flowNote:
        'Rotation → anterior core → posterior chain → upper back/rear delts → pushing',
    icon: Icons.layers_rounded,
    accentColor: Color(0xFF8B5CF6),
  ),
  plankMobility(
    title: 'Plank & Spine',
    rangeLabel: '#6–7 · Core & Flow',
    flowNote: 'Forearm plank stability into kneeling Child\'s Pose to Cobra',
    icon: Icons.accessibility_new_rounded,
    accentColor: Color(0xFF14B8A6),
  ),
  standingFinisher(
    title: 'Standing & Finisher',
    rangeLabel: '#8–12 · Upright & Cardio',
    flowNote: 'Neck mobility → toe touches → IT band → skipping scissors → squats',
    icon: Icons.directions_run_rounded,
    accentColor: Color(0xFF6366F1),
  );

  final String title;
  final String rangeLabel;
  final String flowNote;
  final IconData icon;
  final Color accentColor;

  const RoutineBlock({
    required this.title,
    required this.rangeLabel,
    required this.flowNote,
    required this.icon,
    required this.accentColor,
  });
}

/// Identifies which exercise animation choreography to play.
enum ExerciseMotionId {
  spinalTwist,
  hollowBodyHold,
  hamstringBridge,
  proneYtw,
  pushUps,
  standardPlank,
  childsPoseToCobra,
  neckRotations,
  crossoverToeTouch,
  itBandStretch,
  skippingScissors,
  squats,
}

/// Sub-phase motion cue used by both the preview player and guided workout player.
enum MotionCue {
  twistCycle,
  twistLeft,
  twistRight,
  hollowHold,
  restFlat,
  bridge,
  proneYtwCycle,
  proneY,
  proneT,
  proneW,
  pushupKnees,
  pushupStandard,
  pushupElevated,
  plankHold,
  childsPoseToCobra,
  neckCycle,
  neckTurnRight,
  neckTurnLeft,
  neckTiltRight,
  neckTiltLeft,
  neckRoll,
  toeTouchAlternating,
  itBandAlternating,
  itBandLeft,
  itBandRight,
  skippingScissors,
  squats,
}

/// Single step in an exercise's execution timeline.
class ExercisePhaseStep {
  final String title;
  final String instruction;
  final MotionCue motionCue;
  final bool isRepBased;
  final bool isRest;
  final int durationSeconds;
  final int targetReps;
  final double secondsPerRep;

  const ExercisePhaseStep({
    required this.title,
    required this.instruction,
    required this.motionCue,
    this.isRepBased = false,
    this.isRest = false,
    this.durationSeconds = 0,
    this.targetReps = 0,
    this.secondsPerRep = 2.5,
  });

  int get estimatedSeconds =>
      isRepBased ? (targetReps * secondsPerRep).round() : durationSeconds;
}

/// Target and phase breakdown for one exercise at a specific [RoutineTier].
class TierPrescription {
  final String targetSummary;
  final String detailText;
  final String? variantTag;
  final List<ExercisePhaseStep> steps;

  const TierPrescription({
    required this.targetSummary,
    required this.detailText,
    this.variantTag,
    required this.steps,
  });

  int get totalEstimatedSeconds =>
      steps.fold(0, (sum, step) => sum + step.estimatedSeconds);
}

/// Interactive motion preview option displayed in the exercise detail sheet.
class MotionPreviewOption {
  final String label;
  final MotionCue cue;

  const MotionPreviewOption(this.label, this.cue);
}

class StretchExercise {
  final int number;
  final String id;
  final String name;
  final String shortCue;
  final String description;
  final String focusArea;
  final RoutineBlock block;
  final ExerciseMotionId motionId;
  final double previewCycleSeconds;
  final List<MotionPreviewOption> previewOptions;
  final Map<RoutineTier, TierPrescription> prescriptions;

  const StretchExercise({
    required this.number,
    required this.id,
    required this.name,
    required this.shortCue,
    required this.description,
    required this.focusArea,
    required this.block,
    required this.motionId,
    required this.previewCycleSeconds,
    required this.previewOptions,
    required this.prescriptions,
  });

  TierPrescription forTier(RoutineTier tier) => prescriptions[tier]!;

  /// Best showcase motion cue for preview cards at [tier] (reflects tier-specific
  /// variants such as Push-Ups while keeping full showcase loops for multi-step moves).
  MotionCue previewCueFor(RoutineTier tier) {
    if (motionId == ExerciseMotionId.pushUps) {
      return forTier(tier).steps.first.motionCue;
    }
    return previewOptions.first.cue;
  }

  /// Convenience getter for default/first tier duration when needed.
  int durationSecondsForTier(RoutineTier tier) =>
      forTier(tier).totalEstimatedSeconds;

  static List<ExercisePhaseStep> _hollowSets(int holdSeconds, int restSeconds) {
    final steps = <ExercisePhaseStep>[];
    for (var i = 1; i <= 3; i++) {
      steps.add(
        ExercisePhaseStep(
          title: 'Hold $i of 3',
          instruction:
              'Lift shoulders & straight legs; press lower back firmly into the floor.',
          motionCue: MotionCue.hollowHold,
          durationSeconds: holdSeconds,
        ),
      );
      if (i < 3) {
        steps.add(
          ExercisePhaseStep(
            title: 'Brief Rest ($i/3 done)',
            instruction: 'Relax flat on the mat and catch your breath.',
            motionCue: MotionCue.restFlat,
            isRest: true,
            durationSeconds: restSeconds,
          ),
        );
      }
    }
    return steps;
  }

  static List<ExercisePhaseStep> _proneYtwSteps(int repsPerShape) {
    return [
      ExercisePhaseStep(
        title: 'Y Raises',
        instruction:
            'Lie face down, raise arms overhead into a Y with thumbs pointing up.',
        motionCue: MotionCue.proneY,
        isRepBased: true,
        targetReps: repsPerShape,
        secondsPerRep: 2.3,
      ),
      ExercisePhaseStep(
        title: 'T Raises',
        instruction:
            'Extend arms straight out to the sides in a T and squeeze shoulder blades.',
        motionCue: MotionCue.proneT,
        isRepBased: true,
        targetReps: repsPerShape,
        secondsPerRep: 2.3,
      ),
      ExercisePhaseStep(
        title: 'W Raises',
        instruction:
            'Bend elbows back into a W beside your ribs and pinch your shoulder blades.',
        motionCue: MotionCue.proneW,
        isRepBased: true,
        targetReps: repsPerShape,
        secondsPerRep: 2.3,
      ),
    ];
  }

  static List<ExercisePhaseStep> _neckRoundSteps({
    required int rounds,
    required int holdSeconds,
    required int rollSeconds,
  }) {
    final steps = <ExercisePhaseStep>[];
    for (var r = 1; r <= rounds; r++) {
      final prefix = rounds > 1 ? 'Round $r/$rounds · ' : '';
      steps.addAll([
        ExercisePhaseStep(
          title: '${prefix}Turn Head Right',
          instruction: 'Gently turn your chin toward your right shoulder and hold.',
          motionCue: MotionCue.neckTurnRight,
          durationSeconds: holdSeconds,
        ),
        ExercisePhaseStep(
          title: '${prefix}Turn Head Left',
          instruction: 'Gently turn your chin toward your left shoulder and hold.',
          motionCue: MotionCue.neckTurnLeft,
          durationSeconds: holdSeconds,
        ),
        ExercisePhaseStep(
          title: '${prefix}Ear to Right Shoulder',
          instruction: 'Tilt right ear toward right shoulder while keeping shoulders down.',
          motionCue: MotionCue.neckTiltRight,
          durationSeconds: holdSeconds,
        ),
        ExercisePhaseStep(
          title: '${prefix}Ear to Left Shoulder',
          instruction: 'Tilt left ear toward left shoulder and breathe softly.',
          motionCue: MotionCue.neckTiltLeft,
          durationSeconds: holdSeconds,
        ),
        ExercisePhaseStep(
          title: '${prefix}Slow Neck Roll',
          instruction: 'Roll smoothly front → right → back → left with relaxed shoulders.',
          motionCue: MotionCue.neckRoll,
          durationSeconds: rollSeconds,
        ),
      ]);
    }
    return steps;
  }

  static List<ExercisePhaseStep> _itBandSteps(int repsPerSide) {
    return [
      ExercisePhaseStep(
        title: 'Left Side IT Band',
        instruction:
            'Cross left leg behind right, reach left arm up and lean right, hold.',
        motionCue: MotionCue.itBandLeft,
        isRepBased: true,
        targetReps: repsPerSide,
        secondsPerRep: 3.2,
      ),
      ExercisePhaseStep(
        title: 'Right Side IT Band',
        instruction:
            'Cross right leg behind left, reach right arm up and lean left, hold.',
        motionCue: MotionCue.itBandRight,
        isRepBased: true,
        targetReps: repsPerSide,
        secondsPerRep: 3.2,
      ),
    ];
  }

  static final List<StretchExercise> routine = [
    // 1. Spinal twist
    StretchExercise(
      number: 1,
      id: 'spinal_twist',
      name: 'Spinal Twist',
      shortCue: 'Lying down, drop knees to one side → other side',
      description:
          'Lie flat on your back with arms opened wide in a T. Bend both knees together and gently drop them to one side while keeping both shoulders anchored to the floor, then switch sides.',
      focusArea: 'Rotation',
      block: RoutineBlock.floorBlock,
      motionId: ExerciseMotionId.spinalTwist,
      previewCycleSeconds: 5.5,
      previewOptions: const [
        MotionPreviewOption('Both Sides', MotionCue.twistCycle),
        MotionPreviewOption('Left Side', MotionCue.twistLeft),
        MotionPreviewOption('Right Side', MotionCue.twistRight),
      ],
      prescriptions: {
        RoutineTier.halfway: const TierPrescription(
          targetSummary: '10s / side',
          detailText: '10s Left + 10s Right',
          steps: [
            ExercisePhaseStep(
              title: 'Left Side Twist',
              instruction: 'Drop both knees to the left, keep shoulders flat.',
              motionCue: MotionCue.twistLeft,
              durationSeconds: 10,
            ),
            ExercisePhaseStep(
              title: 'Right Side Twist',
              instruction: 'Sweep knees across and drop to the right side.',
              motionCue: MotionCue.twistRight,
              durationSeconds: 10,
            ),
          ],
        ),
        RoutineTier.sweatless: const TierPrescription(
          targetSummary: '20s / side',
          detailText: '20s Left + 20s Right',
          steps: [
            ExercisePhaseStep(
              title: 'Left Side Twist',
              instruction: 'Drop both knees to the left, breathe into your ribcage.',
              motionCue: MotionCue.twistLeft,
              durationSeconds: 20,
            ),
            ExercisePhaseStep(
              title: 'Right Side Twist',
              instruction: 'Sweep knees across and drop to the right side.',
              motionCue: MotionCue.twistRight,
              durationSeconds: 20,
            ),
          ],
        ),
        RoutineTier.sweaty: const TierPrescription(
          targetSummary: '30s / side',
          detailText: '30s Left + 30s Right',
          steps: [
            ExercisePhaseStep(
              title: 'Left Side Twist',
              instruction: 'Drop both knees to the left, keep opposite shoulder heavy.',
              motionCue: MotionCue.twistLeft,
              durationSeconds: 30,
            ),
            ExercisePhaseStep(
              title: 'Right Side Twist',
              instruction: 'Sweep knees smoothly across to the right side.',
              motionCue: MotionCue.twistRight,
              durationSeconds: 30,
            ),
          ],
        ),
        RoutineTier.intense: const TierPrescription(
          targetSummary: '45s / side',
          detailText: '45s Left + 45s Right',
          steps: [
            ExercisePhaseStep(
              title: 'Left Side Twist',
              instruction: 'Deep spinal twist to the left, relax breath on every exhale.',
              motionCue: MotionCue.twistLeft,
              durationSeconds: 45,
            ),
            ExercisePhaseStep(
              title: 'Right Side Twist',
              instruction: 'Deep spinal twist to the right, soften hips and shoulders.',
              motionCue: MotionCue.twistRight,
              durationSeconds: 45,
            ),
          ],
        ),
      },
    ),

    // 2. Hollow body hold
    StretchExercise(
      number: 2,
      id: 'hollow_body_hold',
      name: 'Hollow Body Hold',
      shortCue: 'Lying on back, lift shoulders and legs, lower back pressed down',
      description:
          'Lie on your back, tuck your ribs down, and press your lower back firmly into the floor. Lift your shoulder blades, arms, and straight legs slightly off the mat to hold a tight hollow dish shape.',
      focusArea: 'Anterior Core',
      block: RoutineBlock.floorBlock,
      motionId: ExerciseMotionId.hollowBodyHold,
      previewCycleSeconds: 4.5,
      previewOptions: const [
        MotionPreviewOption('Active Hold', MotionCue.hollowHold),
        MotionPreviewOption('Rest Pose', MotionCue.restFlat),
      ],
      prescriptions: {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '5s ×3',
          detailText: '3 holds × 5s (5s rest)',
          steps: _hollowSets(5, 5),
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '10s ×3',
          detailText: '3 holds × 10s (6s rest)',
          steps: _hollowSets(10, 6),
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '20s ×3',
          detailText: '3 holds × 20s (8s rest)',
          steps: _hollowSets(20, 8),
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '30s ×3',
          detailText: '3 holds × 30s (10s rest)',
          steps: _hollowSets(30, 10),
        ),
      },
    ),

    // 3. Hamstring bridge
    StretchExercise(
      number: 3,
      id: 'hamstring_bridge',
      name: 'Hamstring Bridge',
      shortCue: 'Lying on back, knees bent, feet flat, lift hips using hamstrings & lower back',
      description:
          'Lie on your back with knees bent and feet planted flat hip-width apart. Drive through your heels to lift your hips using your hamstrings, glutes, and lower back until thighs and torso align, then lower with control.',
      focusArea: 'Posterior Chain',
      block: RoutineBlock.floorBlock,
      motionId: ExerciseMotionId.hamstringBridge,
      previewCycleSeconds: 2.6,
      previewOptions: const [
        MotionPreviewOption('Bridge Flow', MotionCue.bridge),
      ],
      prescriptions: const {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '5 reps',
          detailText: '5 controlled bridges',
          steps: [
            ExercisePhaseStep(
              title: 'Hamstring Bridges',
              instruction: 'Drive through heels, squeeze hamstrings at the top.',
              motionCue: MotionCue.bridge,
              isRepBased: true,
              targetReps: 5,
              secondsPerRep: 2.6,
            ),
          ],
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '10 reps',
          detailText: '10 controlled bridges',
          steps: [
            ExercisePhaseStep(
              title: 'Hamstring Bridges',
              instruction: 'Drive through heels, squeeze hamstrings at the top.',
              motionCue: MotionCue.bridge,
              isRepBased: true,
              targetReps: 10,
              secondsPerRep: 2.6,
            ),
          ],
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '20 reps',
          detailText: '20 controlled bridges',
          steps: [
            ExercisePhaseStep(
              title: 'Hamstring Bridges',
              instruction: 'Steady tempo, pause briefly at the top of each lift.',
              motionCue: MotionCue.bridge,
              isRepBased: true,
              targetReps: 20,
              secondsPerRep: 2.6,
            ),
          ],
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '30 reps',
          detailText: '30 controlled bridges',
          steps: [
            ExercisePhaseStep(
              title: 'Hamstring Bridges',
              instruction: 'Full hip extension every rep, keep ribs tucked.',
              motionCue: MotionCue.bridge,
              isRepBased: true,
              targetReps: 30,
              secondsPerRep: 2.5,
            ),
          ],
        ),
      },
    ),

    // 4. Prone Y-T-W raises
    StretchExercise(
      number: 4,
      id: 'prone_ytw_raises',
      name: 'Prone Y-T-W Raises',
      shortCue: 'Lying face down, lift arms in Y, then T, then W shapes, squeeze shoulder blades',
      description:
          'Lie face down with forehead hovering lightly off the mat. Lift straight arms overhead in a Y shape, then straight out to the sides in a T, then bend elbows back into a W while squeezing your shoulder blades together.',
      focusArea: 'Upper Back & Rear Delts',
      block: RoutineBlock.floorBlock,
      motionId: ExerciseMotionId.proneYtw,
      previewCycleSeconds: 6.6,
      previewOptions: const [
        MotionPreviewOption('Y-T-W Sequence', MotionCue.proneYtwCycle),
        MotionPreviewOption('Y Shape', MotionCue.proneY),
        MotionPreviewOption('T Shape', MotionCue.proneT),
        MotionPreviewOption('W Shape', MotionCue.proneW),
      ],
      prescriptions: {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '3 / shape',
          detailText: '3 Y + 3 T + 3 W (9 total)',
          variantTag: '½ of 5–10 range',
          steps: _proneYtwSteps(3),
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '5 / shape',
          detailText: '5 Y + 5 T + 5 W (15 total)',
          variantTag: '5–10 per shape',
          steps: _proneYtwSteps(5),
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '8 / shape',
          detailText: '8 Y + 8 T + 8 W (24 total)',
          variantTag: '5–10 per shape',
          steps: _proneYtwSteps(8),
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '10 / shape',
          detailText: '10 Y + 10 T + 10 W (30 total)',
          variantTag: '5–10 per shape',
          steps: _proneYtwSteps(10),
        ),
      },
    ),

    // 5. Push-ups
    StretchExercise(
      number: 5,
      id: 'push_ups',
      name: 'Push-Ups',
      shortCue: 'Knees down → standard → feet elevated for advanced',
      description:
          'Place hands slightly wider than shoulder width and brace your core. Lower your chest smoothly toward the floor with elbows angled ~45° back, then press back up. Progress from knees down to standard to feet elevated.',
      focusArea: 'Pushing',
      block: RoutineBlock.floorBlock,
      motionId: ExerciseMotionId.pushUps,
      previewCycleSeconds: 2.2,
      previewOptions: const [
        MotionPreviewOption('Knees Down', MotionCue.pushupKnees),
        MotionPreviewOption('Standard', MotionCue.pushupStandard),
        MotionPreviewOption('Feet Elevated', MotionCue.pushupElevated),
      ],
      prescriptions: const {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '5 reps',
          detailText: '5 reps · Knees down',
          variantTag: 'Knees down',
          steps: [
            ExercisePhaseStep(
              title: 'Knees-Down Push-Ups',
              instruction: 'Keep body straight from knees to head, lower chest cleanly.',
              motionCue: MotionCue.pushupKnees,
              isRepBased: true,
              targetReps: 5,
              secondsPerRep: 2.2,
            ),
          ],
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '10 reps',
          detailText: '10 reps · Knees down',
          variantTag: 'Knees down',
          steps: [
            ExercisePhaseStep(
              title: 'Knees-Down Push-Ups',
              instruction: 'Brace core and press evenly through both palms.',
              motionCue: MotionCue.pushupKnees,
              isRepBased: true,
              targetReps: 10,
              secondsPerRep: 2.2,
            ),
          ],
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '20 reps',
          detailText: '20 reps · Standard',
          variantTag: 'Standard',
          steps: [
            ExercisePhaseStep(
              title: 'Standard Push-Ups',
              instruction: 'Rigid plank line from toes to shoulders on every rep.',
              motionCue: MotionCue.pushupStandard,
              isRepBased: true,
              targetReps: 20,
              secondsPerRep: 2.2,
            ),
          ],
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '30 reps',
          detailText: '30 reps · Feet elevated',
          variantTag: 'Feet elevated',
          steps: [
            ExercisePhaseStep(
              title: 'Feet-Elevated Push-Ups',
              instruction: 'Elevate feet on a step or couch, keep core locked tight.',
              motionCue: MotionCue.pushupElevated,
              isRepBased: true,
              targetReps: 30,
              secondsPerRep: 2.2,
            ),
          ],
        ),
      },
    ),

    // 6. Standard plank
    StretchExercise(
      number: 6,
      id: 'standard_plank',
      name: 'Standard Plank',
      shortCue: 'Forearms and toes, body in straight line',
      description:
          'Set forearms parallel on the mat with elbows stacked directly under your shoulders. Step onto your toes, squeeze glutes and abs, and hold one straight line from head to heels without letting hips sag.',
      focusArea: 'Core Stability',
      block: RoutineBlock.plankMobility,
      motionId: ExerciseMotionId.standardPlank,
      previewCycleSeconds: 4.0,
      previewOptions: const [
        MotionPreviewOption('Forearm Hold', MotionCue.plankHold),
      ],
      prescriptions: const {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '15s',
          detailText: '15s straight-line hold',
          steps: [
            ExercisePhaseStep(
              title: 'Forearm Plank Hold',
              instruction: 'Elbows under shoulders, glutes & core braced.',
              motionCue: MotionCue.plankHold,
              durationSeconds: 15,
            ),
          ],
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '30s',
          detailText: '30s straight-line hold',
          steps: [
            ExercisePhaseStep(
              title: 'Forearm Plank Hold',
              instruction: 'Push the floor away with your forearms and breathe steadily.',
              motionCue: MotionCue.plankHold,
              durationSeconds: 30,
            ),
          ],
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '45s',
          detailText: '45s straight-line hold',
          steps: [
            ExercisePhaseStep(
              title: 'Forearm Plank Hold',
              instruction: 'Keep hips level with shoulders; steady nasal breathing.',
              motionCue: MotionCue.plankHold,
              durationSeconds: 45,
            ),
          ],
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '60s',
          detailText: '60s straight-line hold',
          steps: [
            ExercisePhaseStep(
              title: 'Forearm Plank Hold',
              instruction: 'Full 60-second tension from heels through crown of head.',
              motionCue: MotionCue.plankHold,
              durationSeconds: 60,
            ),
          ],
        ),
      },
    ),

    // 7. Kneeling Child's Pose to Cobra
    StretchExercise(
      number: 7,
      id: 'childs_pose_to_cobra',
      name: 'Kneeling Child\'s Pose to Cobra',
      shortCue: 'Hips back to heels, arms forward → slide forward, lift chest, arms straight',
      description:
          'Sit your hips back toward your heels with arms stretched long overhead in Child\'s Pose. Smoothly slide forward along the mat, drop your hips down, straighten your arms, and lift your chest into Cobra before gliding back.',
      focusArea: 'Spine Flow',
      block: RoutineBlock.plankMobility,
      motionId: ExerciseMotionId.childsPoseToCobra,
      previewCycleSeconds: 5.8,
      previewOptions: const [
        MotionPreviewOption('Flow Cycle', MotionCue.childsPoseToCobra),
      ],
      prescriptions: const {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '10s',
          detailText: '10s smooth spine flow',
          steps: [
            ExercisePhaseStep(
              title: 'Child\'s Pose ↔ Cobra Flow',
              instruction: 'Sit hips to heels, slide forward, lift chest with straight arms.',
              motionCue: MotionCue.childsPoseToCobra,
              durationSeconds: 10,
            ),
          ],
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '20s',
          detailText: '20s smooth spine flow',
          steps: [
            ExercisePhaseStep(
              title: 'Child\'s Pose ↔ Cobra Flow',
              instruction: 'Flow smoothly between deep hip-back reach and open Cobra chest.',
              motionCue: MotionCue.childsPoseToCobra,
              durationSeconds: 20,
            ),
          ],
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '30s',
          detailText: '30s smooth spine flow',
          steps: [
            ExercisePhaseStep(
              title: 'Child\'s Pose ↔ Cobra Flow',
              instruction: 'Exhale back into Child\'s Pose, inhale forward into Cobra.',
              motionCue: MotionCue.childsPoseToCobra,
              durationSeconds: 30,
            ),
          ],
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '45s',
          detailText: '45s smooth spine flow',
          steps: [
            ExercisePhaseStep(
              title: 'Child\'s Pose ↔ Cobra Flow',
              instruction: 'Pause 1–2s at each end range to decompress the spine.',
              motionCue: MotionCue.childsPoseToCobra,
              durationSeconds: 45,
            ),
          ],
        ),
      },
    ),

    // 8. Neck rotations
    StretchExercise(
      number: 8,
      id: 'neck_rotations',
      name: 'Neck Rotations',
      shortCue: 'Right 5s → left 5s → ear right 5s → ear left 5s → slow roll',
      description:
          'Stand tall with relaxed shoulders. Turn head right (hold 5s), left (hold 5s), tilt ear to right shoulder (5s), left shoulder (5s), then perform a slow circular roll front-right-back-left.',
      focusArea: 'Neck Mobility',
      block: RoutineBlock.standingFinisher,
      motionId: ExerciseMotionId.neckRotations,
      previewCycleSeconds: 10.0,
      previewOptions: const [
        MotionPreviewOption('Full Sequence', MotionCue.neckCycle),
        MotionPreviewOption('Turn Right', MotionCue.neckTurnRight),
        MotionPreviewOption('Turn Left', MotionCue.neckTurnLeft),
        MotionPreviewOption('Ear Right', MotionCue.neckTiltRight),
        MotionPreviewOption('Ear Left', MotionCue.neckTiltLeft),
        MotionPreviewOption('Slow Roll', MotionCue.neckRoll),
      ],
      prescriptions: {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '½ round',
          detailText: '1 quick round (3s holds + 4s roll)',
          variantTag: '3s holds',
          steps: _neckRoundSteps(rounds: 1, holdSeconds: 3, rollSeconds: 4),
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '1 round',
          detailText: '1 round (5s holds + 8s roll)',
          variantTag: '1 round',
          steps: _neckRoundSteps(rounds: 1, holdSeconds: 5, rollSeconds: 8),
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '2 rounds',
          detailText: '2 rounds (5s holds + 8s roll each)',
          variantTag: '2 rounds',
          steps: _neckRoundSteps(rounds: 2, holdSeconds: 5, rollSeconds: 8),
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '3 rounds',
          detailText: '3 rounds (5s holds + 8s roll each)',
          variantTag: '3 rounds',
          steps: _neckRoundSteps(rounds: 3, holdSeconds: 5, rollSeconds: 8),
        ),
      },
    ),

    // 9. Standing crossover toe touch
    StretchExercise(
      number: 9,
      id: 'crossover_toe_touch',
      name: 'Standing Crossover Toe Touch',
      shortCue: 'Cross one foot over the other, bend and touch toes, alternate',
      description:
          'Stand upright, cross one foot cleanly in front of the other, and hinge gently at the hips to reach down toward your toes. Rise back up, switch which foot crosses in front, and alternate each rep.',
      focusArea: 'Hamstrings & Back',
      block: RoutineBlock.standingFinisher,
      motionId: ExerciseMotionId.crossoverToeTouch,
      previewCycleSeconds: 5.2,
      previewOptions: const [
        MotionPreviewOption('Alternating Reach', MotionCue.toeTouchAlternating),
      ],
      prescriptions: const {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '5 reps',
          detailText: '5 alternating crossover touches',
          steps: [
            ExercisePhaseStep(
              title: 'Crossover Toe Touches',
              instruction: 'Cross foot over, fold at hips to toes, alternate sides.',
              motionCue: MotionCue.toeTouchAlternating,
              isRepBased: true,
              targetReps: 5,
              secondsPerRep: 2.8,
            ),
          ],
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '10 reps',
          detailText: '10 alternating crossover touches',
          steps: [
            ExercisePhaseStep(
              title: 'Crossover Toe Touches',
              instruction: 'Keep back leg straight and exhale as you fold down.',
              motionCue: MotionCue.toeTouchAlternating,
              isRepBased: true,
              targetReps: 10,
              secondsPerRep: 2.8,
            ),
          ],
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '20 reps',
          detailText: '20 alternating crossover touches',
          steps: [
            ExercisePhaseStep(
              title: 'Crossover Toe Touches',
              instruction: 'Alternate crossed foot every rep with smooth hip hinge.',
              motionCue: MotionCue.toeTouchAlternating,
              isRepBased: true,
              targetReps: 20,
              secondsPerRep: 2.6,
            ),
          ],
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '30 reps',
          detailText: '30 alternating crossover touches',
          steps: [
            ExercisePhaseStep(
              title: 'Crossover Toe Touches',
              instruction: 'Reach deeper toward toes each round while keeping rhythm.',
              motionCue: MotionCue.toeTouchAlternating,
              isRepBased: true,
              targetReps: 30,
              secondsPerRep: 2.5,
            ),
          ],
        ),
      },
    ),

    // 10. Left & right IT band stretch
    StretchExercise(
      number: 10,
      id: 'it_band_stretch',
      name: 'Left & Right IT Band Stretch',
      shortCue: 'Standing, cross one leg behind, lean to opposite side, hold',
      description:
          'Stand tall, step one leg behind the other, raise that same arm overhead, and gently lean your torso toward the opposite side until you feel a clean stretch along your outer hip and IT band.',
      focusArea: 'Outer Hip / IT Band',
      block: RoutineBlock.standingFinisher,
      motionId: ExerciseMotionId.itBandStretch,
      previewCycleSeconds: 5.6,
      previewOptions: const [
        MotionPreviewOption('Both Sides', MotionCue.itBandAlternating),
        MotionPreviewOption('Left IT Band', MotionCue.itBandLeft),
        MotionPreviewOption('Right IT Band', MotionCue.itBandRight),
      ],
      prescriptions: {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '3 / side',
          detailText: '3 Left + 3 Right side leans',
          steps: _itBandSteps(3),
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '5 / side',
          detailText: '5 Left + 5 Right side leans',
          steps: _itBandSteps(5),
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '10 / side',
          detailText: '10 Left + 10 Right side leans',
          steps: _itBandSteps(10),
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '15 / side',
          detailText: '15 Left + 15 Right side leans',
          steps: _itBandSteps(15),
        ),
      },
    ),

    // 11. Skipping scissors
    StretchExercise(
      number: 11,
      id: 'skipping_scissors',
      name: 'Skipping Scissors',
      shortCue: 'Jump and alternate legs front-to-back or side-to-side, steady rhythm',
      description:
          'Stay light on the balls of your feet and jump softly while alternating your legs front-to-back (or side-to-side) in crisp scissor switches. Keep your arms relaxed and maintain a steady breathing rhythm.',
      focusArea: 'Cardio Rhythm',
      block: RoutineBlock.standingFinisher,
      motionId: ExerciseMotionId.skippingScissors,
      previewCycleSeconds: 0.9,
      previewOptions: const [
        MotionPreviewOption('Steady Rhythm', MotionCue.skippingScissors),
      ],
      prescriptions: const {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '15s',
          detailText: '15s light scissor hops',
          steps: [
            ExercisePhaseStep(
              title: 'Skipping Scissors',
              instruction: 'Light bounces on balls of feet, alternate legs smoothly.',
              motionCue: MotionCue.skippingScissors,
              durationSeconds: 15,
            ),
          ],
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '30s',
          detailText: '30s steady scissor hops',
          steps: [
            ExercisePhaseStep(
              title: 'Skipping Scissors',
              instruction: 'Keep a steady, playful rhythm; soft knees on every landing.',
              motionCue: MotionCue.skippingScissors,
              durationSeconds: 30,
            ),
          ],
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '45s',
          detailText: '45s steady scissor hops',
          steps: [
            ExercisePhaseStep(
              title: 'Skipping Scissors',
              instruction: 'Crisp front-to-back switches, relaxed shoulders.',
              motionCue: MotionCue.skippingScissors,
              durationSeconds: 45,
            ),
          ],
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '60s',
          detailText: '60s energetic scissor hops',
          steps: [
            ExercisePhaseStep(
              title: 'Skipping Scissors',
              instruction: 'Maintain fast, bouncy cadence for the full minute.',
              motionCue: MotionCue.skippingScissors,
              durationSeconds: 60,
            ),
          ],
        ),
      },
    ),

    // 12. Squats
    StretchExercise(
      number: 12,
      id: 'squats',
      name: 'Squats',
      shortCue: 'Feet shoulder-width, sit back and down, chest up, knees track over toes',
      description:
          'Set your feet shoulder-width apart with toes slightly turned out. Sit your hips back and down while keeping your chest lifted and knees tracking over your toes, then drive through full feet to stand.',
      focusArea: 'Lower Body',
      block: RoutineBlock.standingFinisher,
      motionId: ExerciseMotionId.squats,
      previewCycleSeconds: 2.4,
      previewOptions: const [
        MotionPreviewOption('Bodyweight Squat', MotionCue.squats),
      ],
      prescriptions: const {
        RoutineTier.halfway: TierPrescription(
          targetSummary: '5 reps',
          detailText: '5 controlled squats',
          steps: [
            ExercisePhaseStep(
              title: 'Bodyweight Squats',
              instruction: 'Sit back and down, keep chest tall and knees tracking toes.',
              motionCue: MotionCue.squats,
              isRepBased: true,
              targetReps: 5,
              secondsPerRep: 2.4,
            ),
          ],
        ),
        RoutineTier.sweatless: TierPrescription(
          targetSummary: '10 reps',
          detailText: '10 controlled squats',
          steps: [
            ExercisePhaseStep(
              title: 'Bodyweight Squats',
              instruction: 'Smooth descent, drive evenly through heels to stand.',
              motionCue: MotionCue.squats,
              isRepBased: true,
              targetReps: 10,
              secondsPerRep: 2.4,
            ),
          ],
        ),
        RoutineTier.sweaty: TierPrescription(
          targetSummary: '20 reps',
          detailText: '20 controlled squats',
          steps: [
            ExercisePhaseStep(
              title: 'Bodyweight Squats',
              instruction: 'Hit parallel depth with proud chest on every rep.',
              motionCue: MotionCue.squats,
              isRepBased: true,
              targetReps: 20,
              secondsPerRep: 2.4,
            ),
          ],
        ),
        RoutineTier.intense: TierPrescription(
          targetSummary: '30 reps',
          detailText: '30 controlled squats',
          steps: [
            ExercisePhaseStep(
              title: 'Bodyweight Squats',
              instruction: 'Consistent rhythm all the way to 30 — strong finish!',
              motionCue: MotionCue.squats,
              isRepBased: true,
              targetReps: 30,
              secondsPerRep: 2.3,
            ),
          ],
        ),
      },
    ),
  ];

  static StretchExercise? findById(String id) {
    for (final exercise in routine) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  static List<StretchExercise> byBlock(RoutineBlock block) =>
      routine.where((e) => e.block == block).toList();

  static int totalRoutineSeconds(RoutineTier tier) =>
      routine.fold(0, (sum, e) => sum + e.forTier(tier).totalEstimatedSeconds);

  static String formatDuration(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    if (mins == 0) return '${secs}s';
    if (secs == 0) return '${mins}m';
    return '${mins}m ${secs}s';
  }
}
