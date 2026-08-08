import 'package:equatable/equatable.dart';

enum TaskStatus {
  pending('Pending'),
  inProgress('In Progress'),
  verified('Verified'),
  rejected('Rejected'),
  missed('Missed'),
  skipped('Skipped');

  const TaskStatus(this.label);
  final String label;
}

enum TaskCategory {
  health('Health & Fitness'),
  study('Study & Learning'),
  work('Work & Productivity'),
  chores('Home & Chores'),
  creative('Creative'),
  social('Social & Family'),
  screenBreak('Screen Break'),
  other('Other');

  const TaskCategory(this.label);
  final String label;

  bool get skipsPhotoVerification => this == TaskCategory.screenBreak;
}

/// A scheduled item in the user's daily timetable.
class ScheduledTask extends Equatable {
  const ScheduledTask({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.durationMinutes,
    this.description,
    this.category = TaskCategory.other,
    this.requiresPhotoVerification = true,
    this.verificationHint,
    this.status = TaskStatus.pending,
    this.reminderEnabled = true,
    this.photoPath,
    this.verificationFeedback,
    this.verificationConfidence,
    this.verifiedAt,
    this.notificationId,
    this.missedCallNotificationId,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final int durationMinutes;
  final TaskCategory category;
  final bool requiresPhotoVerification;
  final String? verificationHint;
  final TaskStatus status;
  final bool reminderEnabled;
  final String? photoPath;
  final String? verificationFeedback;
  final double? verificationConfidence;
  final DateTime? verifiedAt;
  final int? notificationId;
  final int? missedCallNotificationId;

  DateTime get deadlineAt =>
      scheduledAt.add(Duration(minutes: durationMinutes));

  /// Whether the task window has started (user can complete or snap).
  bool get hasStarted => !DateTime.now().isBefore(scheduledAt);

  bool get canMarkComplete =>
      hasStarted &&
      status != TaskStatus.verified &&
      status != TaskStatus.skipped;

  bool get canSnapNow => hasStarted && canSnapForBonus && photoPath == null;

  String get availabilityMessage {
    final hour = scheduledAt.hour.toString().padLeft(2, '0');
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    return 'Available at $hour:$minute';
  }

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  bool get isOverdue =>
      status == TaskStatus.pending && DateTime.now().isAfter(deadlineAt);

  /// Whether snapping a photo can earn bonus XP for this task.
  bool get canSnapForBonus =>
      requiresPhotoVerification &&
      !category.skipsPhotoVerification &&
      !titleSuggestsNoPhoto(title);

  static bool titleSuggestsNoPhoto(String title) {
    final lower = title.toLowerCase();
    const keywords = [
      'phone',
      'mobile',
      'screen time',
      'screen-time',
      'social media',
      'instagram',
      'tiktok',
      'scroll',
      'digital detox',
      'offline',
      'no phone',
      'less phone',
      'put phone',
      'unplug',
      'device-free',
      'phone-free',
      'away from phone',
    ];
    return keywords.any(lower.contains);
  }

  static bool shouldRequirePhoto({
    required TaskCategory category,
    required String title,
  }) {
    if (category.skipsPhotoVerification) return false;
    if (titleSuggestsNoPhoto(title)) return false;
    return true;
  }

  String get verificationPrompt =>
      verificationHint ?? 'User should be doing: $title. ${description ?? ''}';

  ScheduledTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledAt,
    int? durationMinutes,
    TaskCategory? category,
    bool? requiresPhotoVerification,
    String? verificationHint,
    TaskStatus? status,
    bool? reminderEnabled,
    String? photoPath,
    String? verificationFeedback,
    double? verificationConfidence,
    DateTime? verifiedAt,
    int? notificationId,
    int? missedCallNotificationId,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      requiresPhotoVerification:
          requiresPhotoVerification ?? this.requiresPhotoVerification,
      verificationHint: verificationHint ?? this.verificationHint,
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      photoPath: photoPath ?? this.photoPath,
      verificationFeedback: verificationFeedback ?? this.verificationFeedback,
      verificationConfidence:
          verificationConfidence ?? this.verificationConfidence,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      notificationId: notificationId ?? this.notificationId,
      missedCallNotificationId:
          missedCallNotificationId ?? this.missedCallNotificationId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'category': category.name,
        'requiresPhotoVerification': requiresPhotoVerification,
        'verificationHint': verificationHint,
        'status': status.name,
        'reminderEnabled': reminderEnabled,
        'photoPath': photoPath,
        'verificationFeedback': verificationFeedback,
        'verificationConfidence': verificationConfidence,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'notificationId': notificationId,
        'missedCallNotificationId': missedCallNotificationId,
      };

  factory ScheduledTask.fromJson(Map<String, dynamic> json) => ScheduledTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        durationMinutes: json['durationMinutes'] as int? ?? 30,
        category: TaskCategory.values
            .byName(json['category'] as String? ?? 'other'),
        requiresPhotoVerification:
            json['requiresPhotoVerification'] as bool? ?? true,
        verificationHint: json['verificationHint'] as String?,
        status: TaskStatus.values.byName(json['status'] as String? ?? 'pending'),
        reminderEnabled: json['reminderEnabled'] as bool? ?? true,
        photoPath: json['photoPath'] as String?,
        verificationFeedback: json['verificationFeedback'] as String?,
        verificationConfidence:
            (json['verificationConfidence'] as num?)?.toDouble(),
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.parse(json['verifiedAt'] as String)
            : null,
        notificationId: json['notificationId'] as int?,
        missedCallNotificationId: json['missedCallNotificationId'] as int?,
      );

  @override
  List<Object?> get props => [id, title, scheduledAt, status];
}

class TaskVerificationResult extends Equatable {
  const TaskVerificationResult({
    required this.verified,
    required this.feedback,
    required this.confidence,
  });

  final bool verified;
  final String feedback;
  final double confidence;

  @override
  List<Object?> get props => [verified, feedback, confidence];
}
