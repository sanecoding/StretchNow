import 'package:flutter/material.dart';
import 'package:stretchnow/core/constants/app_constants.dart';
import 'package:stretchnow/core/services/notification_service.dart';
import 'package:stretchnow/core/services/storage_service.dart';

class ScheduleViewModel extends ChangeNotifier {
  final StorageService _storageService;
  final NotificationService _notificationService;

  static const Set<int> everyDay = {1, 2, 3, 4, 5, 6, 7};
  static const Set<int> weekdaysOnly = {1, 2, 3, 4, 5};
  static const Set<int> weekendsOnly = {6, 7};

  ScheduleViewModel(this._storageService, this._notificationService) {
    _storageService.addListener(_onStorageChanged);
    _initScheduleData();
  }

  int _wakeUpHour = 7;
  int get wakeUpHour => _wakeUpHour;

  int _wakeUpMinute = 0;
  int get wakeUpMinute => _wakeUpMinute;

  int _delayMinutes = 0;
  int get delayMinutes => _delayMinutes;

  bool _reminderEnabled = true;
  bool get reminderEnabled => _reminderEnabled;

  Set<int> _repeatDays = Set<int>.from(everyDay);
  Set<int> get repeatDays => Set.unmodifiable(_repeatDays);

  void _onStorageChanged() => _initScheduleData();

  void _initScheduleData() {
    _wakeUpHour = _storageService
        .getInt(AppConstants.keyWakeUpHour, defaultValue: 7)
        .clamp(0, 23);
    _wakeUpMinute = _storageService
        .getInt(AppConstants.keyWakeUpMinute, defaultValue: 0)
        .clamp(0, 59);
    _delayMinutes = _storageService
        .getInt(AppConstants.keyWakeUpDelayMinutes, defaultValue: 0)
        .clamp(0, 60);
    _reminderEnabled = _storageService.getSettingBool(
      AppConstants.keyNotificationsEnabled,
      defaultValue: true,
    );

    final rawDays = _storageService.getString(AppConstants.keyWakeUpDays);
    if (rawDays != null && rawDays.trim().isNotEmpty) {
      final parsed = rawDays
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .where((d) => d >= 1 && d <= 7)
          .toSet();
      _repeatDays = parsed.isNotEmpty ? parsed : Set<int>.from(everyDay);
    } else {
      _repeatDays = Set<int>.from(everyDay);
    }
    notifyListeners();
  }

  Future<void> updateWakeUpTime(int hour, int minute) async {
    _wakeUpHour = hour.clamp(0, 23);
    _wakeUpMinute = minute.clamp(0, 59);
    await _storageService.saveEntries({
      AppConstants.keyWakeUpHour: _wakeUpHour.toString(),
      AppConstants.keyWakeUpMinute: _wakeUpMinute.toString(),
    });
    await _rescheduleNotifications();
  }

  Future<void> updateDelayMinutes(int minutes) async {
    _delayMinutes = minutes.clamp(0, 60);
    await _storageService.saveInt(
      AppConstants.keyWakeUpDelayMinutes,
      _delayMinutes,
    );
    await _rescheduleNotifications();
  }

  Future<void> toggleReminder(bool enabled) async {
    _reminderEnabled = enabled;
    await _storageService.saveSettingBool(
      AppConstants.keyNotificationsEnabled,
      enabled,
    );
    if (enabled) {
      await _notificationService.requestPermissions();
      await _rescheduleNotifications();
    } else {
      await _notificationService.cancelAllReminders();
    }
  }

  Future<void> toggleDay(int weekday) async {
    if (weekday < 1 || weekday > 7) return;
    final updated = Set<int>.from(_repeatDays);
    if (updated.contains(weekday)) {
      if (updated.length <= 1) return; // Always keep at least one day active
      updated.remove(weekday);
    } else {
      updated.add(weekday);
    }
    await setRepeatPreset(updated);
  }

  Future<void> setRepeatPreset(Set<int> days) async {
    if (days.isEmpty) return;
    final sorted = days.toList()..sort();
    _repeatDays = sorted.toSet();
    await _storageService.saveString(
      AppConstants.keyWakeUpDays,
      sorted.join(','),
    );
    await _rescheduleNotifications();
  }

  Future<void> _rescheduleNotifications() async {
    if (!_reminderEnabled) return;

    final vibration = _storageService.getSettingBool(
      AppConstants.keyVibrationEnabled,
      defaultValue: true,
    );

    final totalMinutes = (_wakeUpHour * 60 + _wakeUpMinute + _delayMinutes) % (24 * 60);
    await _notificationService.scheduleWakeUpRoutine(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
      repeatDays: _repeatDays,
      vibrationsEnabled: vibration,
    );
  }

  String get formattedWakeUpTime => formatTime(_wakeUpHour, _wakeUpMinute);

  String get formattedStretchTime {
    final totalMinutes =
        (_wakeUpHour * 60 + _wakeUpMinute + _delayMinutes) % (24 * 60);
    return formatTime(totalMinutes ~/ 60, totalMinutes % 60);
  }

  String get repeatSummary {
    if (_repeatDays.length == 7) return 'Every day';
    if (_repeatDays.length == 5 && _repeatDays.containsAll(weekdaysOnly)) {
      return 'Weekdays';
    }
    if (_repeatDays.length == 2 && _repeatDays.containsAll(weekendsOnly)) {
      return 'Weekends';
    }
    const shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = _repeatDays.toList()..sort();
    return sorted.map((d) => shortNames[d - 1]).join(', ');
  }

  String formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minStr $period';
  }

  @override
  void dispose() {
    _storageService.removeListener(_onStorageChanged);
    super.dispose();
  }
}
