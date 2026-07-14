import 'package:equatable/equatable.dart';

/// Habit tracking model.
class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.isCompletedToday = false,
    this.streak = 0,
    this.completedDates = const [],
    this.isCustom = false,
    this.reminderTime,
  });

  final String id;
  final String name;
  final String icon;
  final bool isCompletedToday;
  final int streak;
  final List<DateTime> completedDates;
  final bool isCustom;
  final String? reminderTime;

  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isCompletedToday,
    int? streak,
    List<DateTime>? completedDates,
    bool? isCustom,
    String? reminderTime,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      streak: streak ?? this.streak,
      completedDates: completedDates ?? this.completedDates,
      isCustom: isCustom ?? this.isCustom,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'isCompletedToday': isCompletedToday,
        'streak': streak,
        'completedDates':
            completedDates.map((d) => d.toIso8601String()).toList(),
        'isCustom': isCustom,
        'reminderTime': reminderTime,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        isCompletedToday: json['isCompletedToday'] as bool? ?? false,
        streak: json['streak'] as int? ?? 0,
        completedDates: (json['completedDates'] as List<dynamic>?)
                ?.map((d) => DateTime.parse(d as String))
                .toList() ??
            [],
        isCustom: json['isCustom'] as bool? ?? false,
        reminderTime: json['reminderTime'] as String?,
      );

  @override
  List<Object?> get props => [id, name, isCompletedToday];
}

/// Focus / deep work session.
class FocusSession extends Equatable {
  const FocusSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 25,
    this.completed = false,
    this.goalTitle,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final bool completed;
  final String? goalTitle;

  Duration get elapsed => (endedAt ?? DateTime.now()).difference(startedAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'completed': completed,
        'goalTitle': goalTitle,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        durationMinutes: json['durationMinutes'] as int? ?? 25,
        completed: json['completed'] as bool? ?? false,
        goalTitle: json['goalTitle'] as String?,
      );

  @override
  List<Object?> get props => [id, completed];
}

/// Journal entry with mood and energy tracking.
class JournalEntry extends Equatable {
  const JournalEntry({
    required this.id,
    required this.date,
    required this.success,
    required this.problems,
    this.mood = 3,
    this.energy = 3,
    this.aiSummary,
  });

  final String id;
  final DateTime date;
  final String success;
  final String problems;
  final int mood;
  final int energy;
  final String? aiSummary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'success': success,
        'problems': problems,
        'mood': mood,
        'energy': energy,
        'aiSummary': aiSummary,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        success: json['success'] as String,
        problems: json['problems'] as String,
        mood: json['mood'] as int? ?? 3,
        energy: json['energy'] as int? ?? 3,
        aiSummary: json['aiSummary'] as String?,
      );

  @override
  List<Object?> get props => [id, date];
}

/// Achievement badge.
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
    this.xpReward = 100,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime? unlockedAt;
  final int xpReward;

  bool get isUnlocked => unlockedAt != null;

  @override
  List<Object?> get props => [id, unlockedAt];
}

/// Vision board image item.
class VisionItem extends Equatable {
  const VisionItem({
    required this.id,
    required this.title,
    required this.imagePath,
    this.category,
  });

  final String id;
  final String title;
  final String imagePath;
  final String? category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imagePath': imagePath,
        'category': category,
      };

  factory VisionItem.fromJson(Map<String, dynamic> json) => VisionItem(
        id: json['id'] as String,
        title: json['title'] as String,
        imagePath: json['imagePath'] as String,
        category: json['category'] as String?,
      );

  @override
  List<Object?> get props => [id, title];
}

/// AI chat message.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });

  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  @override
  List<Object?> get props => [id, content, isUser];
}

/// Coach message displayed on home screen.
class CoachMessage extends Equatable {
  const CoachMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String message;
  final CoachMessageType type;
  final DateTime timestamp;
  final bool isRead;

  @override
  List<Object?> get props => [id, message];
}

enum CoachMessageType {
  motivation,
  warning,
  celebration,
  reminder,
  adaptation,
}

/// Streak calendar day status.
class StreakDay extends Equatable {
  const StreakDay({
    required this.date,
    required this.completed,
    this.intensity = 0,
  });

  final DateTime date;
  final bool completed;
  final int intensity;

  @override
  List<Object?> get props => [date, completed];
}
