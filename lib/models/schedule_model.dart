import 'dart:convert';

class Schedule {
  final String id;
  final String name;
  final String? description;
  final TimeOfDayInfo enableTime;
  final TimeOfDayInfo disableTime;
  final List<bool> daysOfWeek; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastExecuted;

  Schedule({
    required this.id,
    required this.name,
    this.description,
    required this.enableTime,
    required this.disableTime,
    required this.daysOfWeek,
    this.isEnabled = true,
    required this.createdAt,
    this.lastExecuted,
  });

  // Create a copy with modified fields
  Schedule copyWith({
    String? id,
    String? name,
    String? description,
    TimeOfDayInfo? enableTime,
    TimeOfDayInfo? disableTime,
    List<bool>? daysOfWeek,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastExecuted,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      enableTime: enableTime ?? this.enableTime,
      disableTime: disableTime ?? this.disableTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastExecuted: lastExecuted ?? this.lastExecuted,
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'enableTime': jsonEncode(enableTime.toMap()),
      'disableTime': jsonEncode(disableTime.toMap()),
      'daysOfWeek': jsonEncode(daysOfWeek),
      'isEnabled': isEnabled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'lastExecuted': lastExecuted?.toIso8601String(),
    };
  }

  // Create from Map (database)
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      enableTime: TimeOfDayInfo.fromMap(
        jsonDecode(map['enableTime'] as String) as Map<String, dynamic>,
      ),
      disableTime: TimeOfDayInfo.fromMap(
        jsonDecode(map['disableTime'] as String) as Map<String, dynamic>,
      ),
      daysOfWeek: (jsonDecode(map['daysOfWeek'] as String) as List)
          .map((e) => e as bool)
          .toList(),
      isEnabled: map['isEnabled'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastExecuted: map['lastExecuted'] != null
          ? DateTime.parse(map['lastExecuted'] as String)
          : null,
    );
  }

  // Convert to JSON string
  String toJson() => jsonEncode(toMap());

  // Create from JSON string
  factory Schedule.fromJson(String json) =>
      Schedule.fromMap(jsonDecode(json) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Schedule(id: $id, name: $name, enableTime: $enableTime, disableTime: $disableTime, isEnabled: $isEnabled)';
  }
}

// Helper class for TimeOfDay serialization
class TimeOfDayInfo {
  final int hour;
  final int minute;

  const TimeOfDayInfo({
    required this.hour,
    required this.minute,
  });

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  factory TimeOfDayInfo.fromMap(Map<String, dynamic> map) {
    return TimeOfDayInfo(
      hour: map['hour'] as int,
      minute: map['minute'] as int,
    );
  }

  // Format as readable string (e.g., "9:30 AM")
  String format() {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  // Format as 24-hour string (e.g., "09:30")
  String format24() {
    final displayHour = hour.toString().padLeft(2, '0');
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute';
  }

  @override
  String toString() => format();
}

// Extension for day names
extension DayOfWeekExtension on int {
  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[this];
  }
}

// Quick Sleep Mode Preset
class QuickSleepPreset {
  final String name;
  final TimeOfDayInfo bedtime;
  final TimeOfDayInfo wakeTime;
  final List<bool> daysOfWeek;

  const QuickSleepPreset({
    required this.name,
    required this.bedtime,
    required this.wakeTime,
    required this.daysOfWeek,
  });

  static const defaultPreset = QuickSleepPreset(
    name: 'Quick Sleep Mode',
    bedtime: TimeOfDayInfo(hour: 22, minute: 0), // 10:00 PM
    wakeTime: TimeOfDayInfo(hour: 7, minute: 0), // 7:00 AM
    daysOfWeek: [true, true, true, true, true, true, true], // All days
  );
}
