import 'package:equatable/equatable.dart';

/// Daily screen time goal and tracking.
class ScreenTimeGoal extends Equatable {
  const ScreenTimeGoal({
    this.dailyLimitMinutes = 180,
    this.enabled = true,
    this.reminderAt80Percent = true,
    this.blockDuringFocusTasks = true,
  });

  final int dailyLimitMinutes;
  final bool enabled;
  final bool reminderAt80Percent;
  final bool blockDuringFocusTasks;

  ScreenTimeGoal copyWith({
    int? dailyLimitMinutes,
    bool? enabled,
    bool? reminderAt80Percent,
    bool? blockDuringFocusTasks,
  }) {
    return ScreenTimeGoal(
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      enabled: enabled ?? this.enabled,
      reminderAt80Percent: reminderAt80Percent ?? this.reminderAt80Percent,
      blockDuringFocusTasks: blockDuringFocusTasks ?? this.blockDuringFocusTasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'dailyLimitMinutes': dailyLimitMinutes,
        'enabled': enabled,
        'reminderAt80Percent': reminderAt80Percent,
        'blockDuringFocusTasks': blockDuringFocusTasks,
      };

  factory ScreenTimeGoal.fromJson(Map<String, dynamic> json) => ScreenTimeGoal(
        dailyLimitMinutes: json['dailyLimitMinutes'] as int? ?? 180,
        enabled: json['enabled'] as bool? ?? true,
        reminderAt80Percent: json['reminderAt80Percent'] as bool? ?? true,
        blockDuringFocusTasks: json['blockDuringFocusTasks'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [dailyLimitMinutes, enabled];
}

class ScreenTimeLog extends Equatable {
  const ScreenTimeLog({
    required this.date,
    required this.minutesUsed,
    this.socialMinutes = 0,
    this.entertainmentMinutes = 0,
    this.isManualEntry = true,
    this.note,
  });

  final DateTime date;
  final int minutesUsed;
  final int socialMinutes;
  final int entertainmentMinutes;
  final bool isManualEntry;
  final String? note;

  double percentOfGoal(int goalMinutes) =>
      goalMinutes == 0 ? 0 : (minutesUsed / goalMinutes * 100).clamp(0, 200);

  ScreenTimeLog copyWith({
    DateTime? date,
    int? minutesUsed,
    int? socialMinutes,
    int? entertainmentMinutes,
    bool? isManualEntry,
    String? note,
  }) {
    return ScreenTimeLog(
      date: date ?? this.date,
      minutesUsed: minutesUsed ?? this.minutesUsed,
      socialMinutes: socialMinutes ?? this.socialMinutes,
      entertainmentMinutes: entertainmentMinutes ?? this.entertainmentMinutes,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minutesUsed': minutesUsed,
        'socialMinutes': socialMinutes,
        'entertainmentMinutes': entertainmentMinutes,
        'isManualEntry': isManualEntry,
        'note': note,
      };

  factory ScreenTimeLog.fromJson(Map<String, dynamic> json) => ScreenTimeLog(
        date: DateTime.parse(json['date'] as String),
        minutesUsed: json['minutesUsed'] as int? ?? 0,
        socialMinutes: json['socialMinutes'] as int? ?? 0,
        entertainmentMinutes: json['entertainmentMinutes'] as int? ?? 0,
        isManualEntry: json['isManualEntry'] as bool? ?? true,
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props => [date, minutesUsed];
}
