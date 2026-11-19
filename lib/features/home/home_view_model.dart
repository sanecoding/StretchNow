import 'package:flutter/material.dart';
import 'package:stretchnow/core/constants/app_constants.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/services/storage_service.dart';

class HomeViewModel extends ChangeNotifier {
  final StorageService _storageService;

  HomeViewModel(this._storageService) {
    _storageService.addListener(_onStorageChanged);
    loadState();
  }

  RoutineTier _selectedTier = RoutineTier.sweatless;
  RoutineTier get selectedTier => _selectedTier;

  int _dailyGoal = 1;
  int get dailyGoal => _dailyGoal;

  int _dailyProgress = 0;
  int get dailyProgress => _dailyProgress;

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _prepSeconds = 5;
  int get prepSeconds => _prepSeconds;

  bool _soundCueEnabled = true;
  bool get soundCueEnabled => _soundCueEnabled;

  bool _vibrationEnabled = true;
  bool get vibrationEnabled => _vibrationEnabled;

  final Set<String> _completedTodayIds = {};
  Set<String> get completedTodayIds => Set.unmodifiable(_completedTodayIds);

  List<StretchExercise> get routine => StretchExercise.routine;

  int get completedExerciseCount => _completedTodayIds.length;
  int get totalExerciseCount => routine.length;

  int get totalEstimatedSeconds =>
      StretchExercise.totalRoutineSeconds(_selectedTier);

  String get formattedEstimatedDuration =>
      StretchExercise.formatDuration(totalEstimatedSeconds);

  bool isExerciseDoneToday(String id) => _completedTodayIds.contains(id);

  int get nextExerciseIndex {
    for (var i = 0; i < routine.length; i++) {
      if (!_completedTodayIds.contains(routine[i].id)) {
        return i;
      }
    }
    return 0;
  }

  StretchExercise get currentExercise => routine[nextExerciseIndex];

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get progressMessage {
    if (_completedTodayIds.isEmpty && _dailyProgress == 0) {
      return 'Pick a pace and flow through all 12 moves';
    }
    if (_dailyProgress >= _dailyGoal) {
      return 'Daily goal reached! Ready for another round?';
    }
    if (_completedTodayIds.isNotEmpty) {
      return '${_completedTodayIds.length} of ${routine.length} moves done today';
    }
    return 'Keep the momentum going!';
  }

  void _onStorageChanged() {
    loadState();
  }

  void loadState() {
    final today = todayDateStr();

    _selectedTier = RoutineTier.fromId(
      _storageService.getSettingString(AppConstants.keySelectedTier),
    );
    _dailyGoal = _storageService
        .getSettingInt(AppConstants.keyDailyGoal, defaultValue: 1)
        .clamp(1, 5);
    _prepSeconds = _storageService.getSettingInt(
      AppConstants.keyPrepSeconds,
      defaultValue: 5,
    );
    _soundCueEnabled = _storageService.getSettingBool(
      AppConstants.keySoundCueEnabled,
      defaultValue: true,
    );
    _vibrationEnabled = _storageService.getSettingBool(
      AppConstants.keyVibrationEnabled,
      defaultValue: true,
    );

    _currentStreak = _storageService.getInt(AppConstants.keyStreak);
    final lastStretchDate =
        _storageService.getString(AppConstants.keyLastStretchDate) ?? '';
    if (lastStretchDate.isNotEmpty) {
      try {
        final lastDateObj = DateTime.parse(lastStretchDate);
        final todayObj = DateTime.parse(today);
        if (todayObj.difference(lastDateObj).inDays > 1 && _currentStreak != 0) {
          _currentStreak = 0;
          _storageService.saveInt(AppConstants.keyStreak, 0);
        }
      } catch (_) {
        // Ignore malformed date
      }
    }

    _dailyProgress = _storageService.getInt(
      '${AppConstants.keyDailyProgress}$today',
    );

    final doneRaw = _storageService.getString(
          '${AppConstants.keyDailyExercisesDone}$today',
        ) ??
        '';
    _completedTodayIds
      ..clear()
      ..addAll(doneRaw.split(',').where((e) => e.trim().isNotEmpty));

    notifyListeners();
  }

  static String todayDateStr([DateTime? now]) {
    final dt = now ?? DateTime.now();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> selectTier(RoutineTier tier) async {
    if (_selectedTier == tier) return;
    _selectedTier = tier;
    await _storageService.saveSettingString(
      AppConstants.keySelectedTier,
      tier.id,
    );
  }

  /// Marks an exercise completed today, updating streak and auto-recording a
  /// completed routine when all 12 exercises are finished.
  Future<bool> markExerciseDone(String exerciseId) async {
    final today = todayDateStr();
    final wasAlreadyFull = _completedTodayIds.length >= routine.length;
    _completedTodayIds.add(exerciseId);

    await _storageService.saveString(
      '${AppConstants.keyDailyExercisesDone}$today',
      _completedTodayIds.join(','),
    );
    await _touchStreak(today);

    var completedFullRoutineNow = false;
    if (!wasAlreadyFull && _completedTodayIds.length >= routine.length) {
      await _recordRoutineCompletion(today);
      completedFullRoutineNow = true;
    }
    return completedFullRoutineNow;
  }

  Future<void> _recordRoutineCompletion(String today) async {
    final currentCount =
        _storageService.getInt('${AppConstants.keyDailyProgress}$today');
    await _storageService.saveInt(
      '${AppConstants.keyDailyProgress}$today',
      currentCount + 1,
    );
    await _storageService.saveString(
      '${AppConstants.keyDailyTierHistory}$today',
      _selectedTier.label,
    );
  }

  Future<void> _touchStreak(String today) async {
    final lastStretchDate =
        _storageService.getString(AppConstants.keyLastStretchDate) ?? '';
    if (lastStretchDate != today) {
      final newStreak = _currentStreak + 1;
      await _storageService.saveInt(AppConstants.keyStreak, newStreak);
      final longest = _storageService.getInt(AppConstants.keyLongestStreak);
      if (newStreak > longest) {
        await _storageService.saveInt(AppConstants.keyLongestStreak, newStreak);
      }
      await _storageService.saveString(AppConstants.keyLastStretchDate, today);
    }
  }

  Future<void> resetTodayChecklist() async {
    final today = todayDateStr();
    _completedTodayIds.clear();
    await _storageService.saveString(
      '${AppConstants.keyDailyExercisesDone}$today',
      '',
    );
  }

  @override
  void dispose() {
    _storageService.removeListener(_onStorageChanged);
    super.dispose();
  }
}
