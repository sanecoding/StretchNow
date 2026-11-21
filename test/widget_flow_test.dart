import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/services/notification_service.dart';
import 'package:stretchnow/core/services/storage_service.dart';
import 'package:stretchnow/core/widgets/exercise_motion_player.dart';
import 'package:stretchnow/features/home/home_view_model.dart';
import 'package:stretchnow/features/routine/routine_player_screen.dart';
import 'package:stretchnow/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('All 12 ExerciseMotionPlayer widgets render and animate cleanly', (
    tester,
  ) async {
    for (final ex in StretchExercise.routine) {
      for (final opt in ex.previewOptions) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExerciseMotionPlayer(
                exercise: ex,
                cueOverride: opt.cue,
                isPlaying: true,
                height: 180,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(ExerciseMotionPlayer), findsOneWidget);
      }
    }
  });

  testWidgets(
    'App navigates all 5 tabs on compact phone viewport without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = StorageService.inMemory();
      await tester.pumpWidget(
        StretchNowRoot(
          storageService: storage,
          notificationService: NotificationService(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));

      // Tier switching on Home
      expect(find.text('20s / side'), findsWidgets);
      await tester.tap(find.text('Halfway'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('10s / side'), findsWidgets);

      await tester.tap(find.text('Sweaty'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('30s / side'), findsWidgets);

      await tester.tap(find.text('Intense'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('45s / side'), findsWidgets);

      // Navigate across Motions, Schedule, History, Settings
      await tester.tap(find.text('Motions'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Exercise Motions'), findsOneWidget);

      // Open Prone Y-T-W detail sheet and tap shapes
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('Prone Y-T-W Raises'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Y Shape'), findsOneWidget);
      await tester.drag(find.text('Y-T-W Sequence'), const Offset(-340, 0));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('W Shape'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('W SHAPE'), findsOneWidget);

      // Scroll down to CTA inside sheet and launch from #4
      final sheetScrollable = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Start From #4'),
        150,
        scrollable: sheetScrollable,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Start From #4'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('Prone Y-T-W Raises'), findsWidgets);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // Navigate remaining tabs
      await tester.tap(find.text('Schedule'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Wake-Up Routine'), findsOneWidget);
      expect(find.text('7:00 AM'), findsOneWidget);

      await tester.ensureVisible(find.text('Weekdays'));
      await tester.pump();
      await tester.tap(find.text('Weekdays'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.ensureVisible(find.text('5 minutes after wake-up'));
      await tester.pump();
      await tester.tap(find.text('5 minutes after wake-up'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Stretch at 7:05 AM · Weekdays'), findsOneWidget);

      await tester.tap(find.text('History'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Recent Activity'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Default Exercise Option'), findsOneWidget);
    },
  );

  testWidgets(
    'Guided RoutinePlayerScreen supports prep skip, manual tap reps, and completion',
    (tester) async {
      final storage = StorageService.inMemory({}, {'routine_prep_seconds': '3'});
      final homeVm = HomeViewModel(storage);
      final bridge = StretchExercise.findById('hamstring_bridge')!;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: homeVm,
          child: MaterialApp(
            home: RoutinePlayerScreen(
              exercises: [bridge],
              initialIndex: 0,
              tier: RoutineTier.halfway, // 5 reps
              sessionTitle: 'Quick Bridge Test',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Start Now'), findsOneWidget);

      await tester.tap(find.text('Start Now'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('0/5'), findsOneWidget);

      // Switch to manual tap mode and increment reps
      await tester.tap(find.text('Auto-Paced'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Rep Done'), findsOneWidget);

      await tester.tap(find.text('Rep Done'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('1/5'), findsOneWidget);

      await tester.tap(find.text('Finish'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Routine Complete!'), findsOneWidget);
      expect(homeVm.completedExerciseCount, 1);

      homeVm.dispose();
    },
  );
}
