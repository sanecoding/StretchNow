import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stretchnow/core/constants/app_constants.dart';

class StorageService extends ChangeNotifier {
  final Box<String>? _appDataBox;
  final Box<String>? _settingsBox;
  final Map<String, String> _memoryAppData;
  final Map<String, String> _memorySettings;
  final bool _useMemory;

  StorageService({
    Box<String>? appDataBox,
    Box<String>? settingsBox,
  })  : _appDataBox = appDataBox ?? Hive.box<String>(AppConstants.appDataBox),
        _settingsBox =
            settingsBox ?? Hive.box<String>(AppConstants.settingsBox),
        _memoryAppData = {},
        _memorySettings = {},
        _useMemory = false;

  /// Creates an in-memory storage service suitable for unit and widget tests.
  StorageService.inMemory([
    Map<String, String>? initialAppData,
    Map<String, String>? initialSettings,
  ])  : _appDataBox = null,
        _settingsBox = null,
        _memoryAppData = Map<String, String>.from(initialAppData ?? const {}),
        _memorySettings = Map<String, String>.from(initialSettings ?? const {}),
        _useMemory = true;

  // General App Data
  Future<void> saveString(String key, String value) async {
    if (_useMemory) {
      _memoryAppData[key] = value;
    } else {
      await _appDataBox!.put(key, value);
    }
    notifyListeners();
  }

  String? getString(String key) {
    if (_useMemory) return _memoryAppData[key];
    return _appDataBox!.get(key);
  }

  Future<void> saveInt(String key, int value) async {
    await saveString(key, value.toString());
  }

  int getInt(String key, {int defaultValue = 0}) {
    final val = getString(key);
    return val != null ? int.tryParse(val) ?? defaultValue : defaultValue;
  }

  // Settings
  Future<void> saveSettingBool(String key, bool value) async {
    await saveSettingString(key, value.toString());
  }

  bool getSettingBool(String key, {bool defaultValue = false}) {
    final val = getSettingString(key);
    return val != null ? val == 'true' : defaultValue;
  }

  Future<void> saveSettingString(String key, String value) async {
    if (_useMemory) {
      _memorySettings[key] = value;
    } else {
      await _settingsBox!.put(key, value);
    }
    notifyListeners();
  }

  String? getSettingString(String key) {
    if (_useMemory) return _memorySettings[key];
    return _settingsBox!.get(key);
  }

  Future<void> saveSettingInt(String key, int value) async {
    await saveSettingString(key, value.toString());
  }

  int getSettingInt(String key, {int defaultValue = 0}) {
    final val = getSettingString(key);
    return val != null ? int.tryParse(val) ?? defaultValue : defaultValue;
  }

  Future<void> clearAppData() async {
    if (_useMemory) {
      _memoryAppData.clear();
    } else {
      await _appDataBox!.clear();
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    if (_useMemory) {
      _memoryAppData.clear();
      _memorySettings.clear();
    } else {
      await _appDataBox!.clear();
      await _settingsBox!.clear();
    }
    notifyListeners();
  }
}
