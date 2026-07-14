import 'package:equatable/equatable.dart';
import 'user_profile.dart';

/// Daily accountability check-in record.
class AccountabilityRecord extends Equatable {
  const AccountabilityRecord({
    required this.id,
    required this.date,
    required this.status,
    this.skipReason,
    this.note,
    this.missionId,
  });

  final String id;
  final DateTime date;
  final MissionStatus status;
  final SkipReason? skipReason;
  final String? note;
  final String? missionId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'status': status.name,
        'skipReason': skipReason?.name,
        'note': note,
        'missionId': missionId,
      };

  factory AccountabilityRecord.fromJson(Map<String, dynamic> json) =>
      AccountabilityRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        status: MissionStatus.values.byName(json['status'] as String),
        skipReason: json['skipReason'] != null
            ? SkipReason.values.byName(json['skipReason'] as String)
            : null,
        note: json['note'] as String?,
        missionId: json['missionId'] as String?,
      );

  @override
  List<Object?> get props => [id, date, status];
}

/// Analytics snapshot for dashboard and predictions.
class AnalyticsSnapshot extends Equatable {
  const AnalyticsSnapshot({
    required this.consistencyPercent,
    required this.successProbability,
    required this.goalCompletionPercent,
    required this.averageDailyHours,
    required this.focusScore,
    required this.currentStreak,
    required this.recoveryScore,
    required this.missedDays,
    required this.weeklyTrend,
    required this.monthlyTrend,
    this.probabilityIfContinues,
    this.probabilityIfSkips,
    this.predictionExplanation,
  });

  final double consistencyPercent;
  final double successProbability;
  final double goalCompletionPercent;
  final double averageDailyHours;
  final double focusScore;
  final int currentStreak;
  final double recoveryScore;
  final int missedDays;
  final List<double> weeklyTrend;
  final List<double> monthlyTrend;
  final double? probabilityIfContinues;
  final double? probabilityIfSkips;
  final String? predictionExplanation;

  @override
  List<Object?> get props => [
        consistencyPercent,
        successProbability,
        currentStreak,
      ];
}
