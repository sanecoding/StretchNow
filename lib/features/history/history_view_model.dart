import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stretchnow/core/constants/app_constants.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/services/storage_service.dart';
import 'package:stretchnow/features/home/home_view_model.dart';

class HistoryEntry {
  final String date;
  final int completed;
  final int goal;
  final int exercisesDone;
  final String? tierLabel;

  HistoryEntry({
    required this.date,
    required this.completed,
    required this.goal,
    this.exercisesDone = 0,
    this.tierLabel,
  });
}

class HistoryViewModel extends ChangeNotifier {
  final StorageService _storageService;

  HistoryViewModel(this._storageService) {
    _storageService.addListener(_onStorageChanged);
    loadHistoryData();
  }

  int _currentStreak = 0;
  int get currentStreak => _currentStreak;

  int _longestStreak = 0;
  int get longestStreak => _longestStreak;

  int _totalRoutines = 0;
  int get totalRoutines => _totalRoutines;

  final List<HistoryEntry> _historyEntries = [];
  List<HistoryEntry> get historyEntries => _historyEntries;

  void _onStorageChanged() => loadHistoryData();

  List<HistoryEntry> get lastSevenDays {
    final now = DateTime.now();
    final entries = <HistoryEntry>[];
    final goal = _storageService
        .getSettingInt(AppConstants.keyDailyGoal, defaultValue: 1)
        .clamp(1, 5);

    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = HomeViewModel.todayDateStr(date);
      final progress =
          _storageService.getInt('${AppConstants.keyDailyProgress}$dateStr');
      final exercisesDone = _exercisesCountForDate(dateStr);
      final tierLabel =
          _storageService.getString('${AppConstants.keyDailyTierHistory}$dateStr');
      entries.add(
        HistoryEntry(
          date: dateStr,
          completed: progress,
          goal: goal,
          exercisesDone: exercisesDone,
          tierLabel: tierLabel,
        ),
      );
    }
    return entries;
  }

  int _exercisesCountForDate(String dateStr) {
    final raw =
        _storageService.getString('${AppConstants.keyDailyExercisesDone}$dateStr') ??
            '';
    if (raw.trim().isEmpty) return 0;
    return raw.split(',').where((e) => e.trim().isNotEmpty).length;
  }

  void loadHistoryData() {
    final goal = _storageService
        .getSettingInt(AppConstants.keyDailyGoal, defaultValue: 1)
        .clamp(1, 5);

    _currentStreak = _storageService.getInt(AppConstants.keyStreak);
    _longestStreak = _storageService.getInt(AppConstants.keyLongestStreak);

    _historyEntries.clear();
    _totalRoutines = 0;

    final now = DateTime.now();
    for (var i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = HomeViewModel.todayDateStr(date);
      final progress =
          _storageService.getInt('${AppConstants.keyDailyProgress}$dateStr');
      final exercisesDone = _exercisesCountForDate(dateStr);
      final tierLabel =
          _storageService.getString('${AppConstants.keyDailyTierHistory}$dateStr');

      _totalRoutines += progress;

      if (progress > 0 || exercisesDone > 0 || i == 0) {
        _historyEntries.add(
          HistoryEntry(
            date: dateStr,
            completed: progress,
            goal: goal,
            exercisesDone: exercisesDone > 0
                ? exercisesDone
                : (progress > 0 ? StretchExercise.routine.length : 0),
            tierLabel: tierLabel,
          ),
        );
      }
    }

    notifyListeners();
  }

  String formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return 'Today';
      }

      final yesterday = now.subtract(const Duration(days: 1));
      if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return 'Yesterday';
      }

      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String formatShortDay(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('E').format(date).substring(0, 2);
    } catch (_) {
      return '?';
    }
  }

  @override
  void dispose() {
    _storageService.removeListener(_onStorageChanged);
    super.dispose();
  }
}
