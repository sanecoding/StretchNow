class NotificationService {
  Future<void> init() async {
    // Disabled functionality
  }

  Future<void> requestPermissions() async {
    // Disabled functionality
  }

  Future<void> scheduleWakeUpRoutine({
    required int hour,
    required int minute,
    required Set<int> repeatDays,
    required bool vibrationsEnabled,
  }) async {
    // Disabled functionality
  }

  Future<void> scheduleReminders({
    required int startHour,
    required int endHour,
    required int intervalHours,
    required bool vibrationsEnabled,
  }) async {
    // Disabled functionality
  }

  Future<void> cancelAllReminders() async {
    // Disabled functionality
  }
}
