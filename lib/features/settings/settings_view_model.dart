import 'package:flutter/material.dart';
import 'package:stretchnow/core/constants/app_constants.dart';
import 'package:stretchnow/core/models/stretch_model.dart';
import 'package:stretchnow/core/services/notification_service.dart';
import 'package:stretchnow/core/services/storage_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final StorageService _storageService;
  final NotificationService _notificationService;

  SettingsViewModel(this._storageService, this._notificationService) {
    _storageService.addListener(_onStorageChanged);
    _loadSettings();
  }

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _vibrationEnabled = true;
  bool get vibrationEnabled => _vibrationEnabled;

  bool _soundCueEnabled = true;
  bool get soundCueEnabled => _soundCueEnabled;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  int _dailyGoal = 1;
  int get dailyGoal => _dailyGoal;

  int _prepSeconds = 5;
  int get prepSeconds => _prepSeconds;

  RoutineTier _selectedTier = RoutineTier.sweatless;
  RoutineTier get selectedTier => _selectedTier;

  void _onStorageChanged() => _loadSettings();

  void _loadSettings() {
    _dailyGoal = _storageService
        .getSettingInt(AppConstants.keyDailyGoal, defaultValue: 1)
        .clamp(1, 5);
    _prepSeconds = _storageService.getSettingInt(
      AppConstants.keyPrepSeconds,
      defaultValue: 5,
    );
    _selectedTier = RoutineTier.fromId(
      _storageService.getSettingString(AppConstants.keySelectedTier),
    );
    _soundCueEnabled = _storageService.getSettingBool(
      AppConstants.keySoundCueEnabled,
      defaultValue: true,
    );
    _notificationsEnabled = _storageService.getSettingBool(
      AppConstants.keyNotificationsEnabled,
      defaultValue: true,
    );
    _vibrationEnabled = _storageService.getSettingBool(
      AppConstants.keyVibrationEnabled,
      defaultValue: true,
    );

    final tmStr =
        _storageService.getSettingString(AppConstants.keyThemeMode) ?? 'system';
    if (tmStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (tmStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setSelectedTier(RoutineTier tier) async {
    _selectedTier = tier;
    await _storageService.saveSettingString(
      AppConstants.keySelectedTier,
      tier.id,
    );
  }

  Future<void> setPrepSeconds(int seconds) async {
    _prepSeconds = seconds;
    await _storageService.saveSettingInt(AppConstants.keyPrepSeconds, seconds);
  }

  Future<void> toggleSoundCue(bool value) async {
    _soundCueEnabled = value;
    await _storageService.saveSettingBool(
      AppConstants.keySoundCueEnabled,
      value,
    );
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _storageService.saveSettingBool(
      AppConstants.keyNotificationsEnabled,
      value,
    );

    if (value) {
      await _notificationService.requestPermissions();
      await _rescheduleWakeUp();
    } else {
      await _notificationService.cancelAllReminders();
    }
  }

  Future<void> toggleVibration(bool value) async {
    _vibrationEnabled = value;
    await _storageService.saveSettingBool(
      AppConstants.keyVibrationEnabled,
      value,
    );

    if (_notificationsEnabled) {
      await _rescheduleWakeUp();
    }
  }

  Future<void> _rescheduleWakeUp() async {
    final baseHour = _storageService.getInt(
      AppConstants.keyWakeUpHour,
      defaultValue: 7,
    );
    final baseMinute = _storageService.getInt(
      AppConstants.keyWakeUpMinute,
      defaultValue: 0,
    );
    final delay = _storageService.getInt(
      AppConstants.keyWakeUpDelayMinutes,
      defaultValue: 0,
    );
    final rawDays = _storageService.getString(AppConstants.keyWakeUpDays) ?? '';
    final days = rawDays
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toSet();
    final totalMinutes = (baseHour * 60 + baseMinute + delay) % (24 * 60);

    await _notificationService.scheduleWakeUpRoutine(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
      repeatDays: days.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : days,
      vibrationsEnabled: _vibrationEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : (mode == ThemeMode.dark ? 'dark' : 'system');
    await _storageService.saveSettingString(AppConstants.keyThemeMode, modeStr);
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal.clamp(1, 5);
    await _storageService.saveSettingInt(AppConstants.keyDailyGoal, _dailyGoal);
  }

  Future<void> resetData() async {
    final favs = _storageService.getString(AppConstants.keyFavoriteStretches);
    await _storageService.clearAppData();
    if (favs != null && favs.isNotEmpty) {
      await _storageService.saveString(AppConstants.keyFavoriteStretches, favs);
    }
  }

  @override
  void dispose() {
    _storageService.removeListener(_onStorageChanged);
    super.dispose();
  }
}
