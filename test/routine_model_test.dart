import 'package:flutter_test/flutter_test.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/services/notification_service.dart';
import 'package:stretchnow/core/services/storage_service.dart';
import 'package:stretchnow/features/history/history_view_model.dart';
import 'package:stretchnow/features/home/home_view_model.dart';
import 'package:stretchnow/features/settings/settings_view_model.dart';

void main() {
  group('StretchExercise routine specification', () {
    test('contains all 12 exercises in exact flow order and blocks', () {
      final routine = StretchExercise.routine;
      expect(routine.length, 12);

      final expectedNames = [
        'Spinal Twist',
        'Hollow Body Hold',
        'Hamstring Bridge',
        'Prone Y-T-W Raises',
        'Push-Ups',
        'Standard Plank',
        'Kneeling Child\'s Pose to Cobra',
        'Neck Rotations',
        'Standing Crossover Toe Touch',
        'Left & Right IT Band Stretch',
        'Skipping Scissors',
        'Squats',
      ];

      for (var i = 0; i < 12; i++) {
        expect(routine[i].number, i + 1);
        expect(routine[i].name, expectedNames[i]);
      }

      // Flow note: #1-5 are all on the floor
      expect(
        StretchExercise.byBlock(RoutineBlock.floorBlock)
            .map((e) => e.number)
            .toList(),
        [1, 2, 3, 4, 5],
      );
      expect(
        StretchExercise.byBlock(RoutineBlock.plankMobility)
            .map((e) => e.number)
            .toList(),
        [6, 7],
      );
      expect(
        StretchExercise.byBlock(RoutineBlock.standingFinisher)
            .map((e) => e.number)
            .toList(),
        [8, 9, 10, 11, 12],
      );
    });

    test('every exercise defines prescriptions for all 4 tiers accurately', () {
      for (final ex in StretchExercise.routine) {
        for (final tier in RoutineTier.values) {
          final p = ex.forTier(tier);
          expect(p.steps, isNotEmpty, reason: '${ex.name} ${tier.label}');
          expect(p.totalEstimatedSeconds, greaterThan(0));
        }
      }

      // Verify key tier mappings
      final twist = StretchExercise.findById('spinal_twist')!;
      expect(twist.forTier(RoutineTier.halfway).targetSummary, '10s / side');
      expect(twist.forTier(RoutineTier.sweatless).targetSummary, '20s / side');
      expect(twist.forTier(RoutineTier.sweaty).targetSummary, '30s / side');
      expect(twist.forTier(RoutineTier.intense).targetSummary, '45s / side');

      final hollow = StretchExercise.findById('hollow_body_hold')!;
      expect(hollow.forTier(RoutineTier.halfway).targetSummary, '5s ×3');
      expect(hollow.forTier(RoutineTier.sweatless).targetSummary, '10s ×3');
      expect(hollow.forTier(RoutineTier.sweaty).targetSummary, '20s ×3');
      expect(hollow.forTier(RoutineTier.intense).targetSummary, '30s ×3');

      final ytw = StretchExercise.findById('prone_ytw_raises')!;
      expect(ytw.forTier(RoutineTier.halfway).steps.length, 3);
      expect(ytw.forTier(RoutineTier.sweatless).targetSummary, '5 / shape');
      expect(ytw.forTier(RoutineTier.sweaty).targetSummary, '8 / shape');
      expect(ytw.forTier(RoutineTier.intense).targetSummary, '10 / shape');

      final pushups = StretchExercise.findById('push_ups')!;
      expect(
        pushups.forTier(RoutineTier.halfway).steps.first.motionCue,
        MotionCue.pushupKnees,
      );
      expect(
        pushups.forTier(RoutineTier.sweatless).steps.first.motionCue,
        MotionCue.pushupKnees,
      );
      expect(
        pushups.forTier(RoutineTier.sweaty).steps.first.motionCue,
        MotionCue.pushupStandard,
      );
      expect(
        pushups.forTier(RoutineTier.intense).steps.first.motionCue,
        MotionCue.pushupElevated,
      );

      final neck = StretchExercise.findById('neck_rotations')!;
      expect(neck.forTier(RoutineTier.halfway).steps.length, 5);
      expect(neck.forTier(RoutineTier.sweatless).steps.length, 5);
      expect(neck.forTier(RoutineTier.sweaty).steps.length, 10);
      expect(neck.forTier(RoutineTier.intense).steps.length, 15);
    });
  });

  group('ViewModels state & synchronization', () {
    test('completing all 12 exercises updates routine progress, streak, and history', () async {
      final storage = StorageService.inMemory();
      final homeVm = HomeViewModel(storage);
      final historyVm = HistoryViewModel(storage);
      final settingsVm = SettingsViewModel(storage, NotificationService());

      await homeVm.selectTier(RoutineTier.halfway);
      expect(homeVm.selectedTier, RoutineTier.halfway);
      expect(settingsVm.selectedTier, RoutineTier.halfway);

      for (var i = 0; i < StretchExercise.routine.length - 1; i++) {
        final full = await homeVm.markExerciseDone(StretchExercise.routine[i].id);
        expect(full, isFalse);
      }

      expect(homeVm.completedExerciseCount, 11);
      expect(homeVm.dailyProgress, 0);
      expect(homeVm.currentStreak, 1);

      final fullNow =
          await homeVm.markExerciseDone(StretchExercise.routine.last.id);
      expect(fullNow, isTrue);
      expect(homeVm.completedExerciseCount, 12);
      expect(homeVm.dailyProgress, 1);
      expect(historyVm.totalRoutines, 1);
      expect(historyVm.currentStreak, 1);

      await settingsVm.resetData();
      expect(homeVm.completedExerciseCount, 0);
      expect(homeVm.dailyProgress, 0);
      expect(homeVm.currentStreak, 0);
      expect(historyVm.totalRoutines, 0);

      homeVm.dispose();
      historyVm.dispose();
      settingsVm.dispose();
    });
  });
}
