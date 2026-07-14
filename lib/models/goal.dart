import 'package:equatable/equatable.dart';

/// Roadmap hierarchy: long-term → monthly → weekly → daily → mission.
enum GoalPeriod {
  longTerm,
  monthly,
  weekly,
  daily,
  mission,
}

/// A single goal or task in the roadmap tree.
class GoalItem extends Equatable {
  const GoalItem({
    required this.id,
    required this.title,
    required this.period,
    this.description,
    this.parentId,
    this.isCompleted = false,
    this.completedAt,
    this.dueDate,
    this.estimatedHours,
    this.order = 0,
    this.children = const [],
  });

  final String id;
  final String title;
  final String? description;
  final GoalPeriod period;
  final String? parentId;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final double? estimatedHours;
  final int order;
  final List<GoalItem> children;

  GoalItem copyWith({
    String? id,
    String? title,
    String? description,
    GoalPeriod? period,
    String? parentId,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? dueDate,
    double? estimatedHours,
    int? order,
    List<GoalItem>? children,
  }) {
    return GoalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      period: period ?? this.period,
      parentId: parentId ?? this.parentId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      order: order ?? this.order,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'period': period.name,
        'parentId': parentId,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'estimatedHours': estimatedHours,
        'order': order,
        'children': children.map((c) => c.toJson()).toList(),
      };

  factory GoalItem.fromJson(Map<String, dynamic> json) => GoalItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        period: GoalPeriod.values.byName(json['period'] as String),
        parentId: json['parentId'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
        order: json['order'] as int? ?? 0,
        children: (json['children'] as List<dynamic>?)
                ?.map((c) => GoalItem.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [id, title, isCompleted];
}

/// Complete roadmap for a user's transformation goal.
class Roadmap extends Equatable {
  const Roadmap({
    required this.id,
    required this.userId,
    required this.longTermGoal,
    required this.monthlyGoals,
    required this.weeklyGoals,
    required this.dailyTasks,
    this.todaysMission,
    this.createdAt,
    this.updatedAt,
    this.version = 1,
  });

  final String id;
  final String userId;
  final GoalItem longTermGoal;
  final List<GoalItem> monthlyGoals;
  final List<GoalItem> weeklyGoals;
  final List<GoalItem> dailyTasks;
  final GoalItem? todaysMission;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;

  double get completionPercent {
    final all = [...monthlyGoals, ...weeklyGoals, ...dailyTasks];
    if (all.isEmpty) return 0;
    final completed = all.where((g) => g.isCompleted).length;
    return (completed / all.length) * 100;
  }

  Roadmap copyWith({
    String? id,
    String? userId,
    GoalItem? longTermGoal,
    List<GoalItem>? monthlyGoals,
    List<GoalItem>? weeklyGoals,
    List<GoalItem>? dailyTasks,
    GoalItem? todaysMission,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return Roadmap(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      longTermGoal: longTermGoal ?? this.longTermGoal,
      monthlyGoals: monthlyGoals ?? this.monthlyGoals,
      weeklyGoals: weeklyGoals ?? this.weeklyGoals,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      todaysMission: todaysMission ?? this.todaysMission,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'longTermGoal': longTermGoal.toJson(),
        'monthlyGoals': monthlyGoals.map((g) => g.toJson()).toList(),
        'weeklyGoals': weeklyGoals.map((g) => g.toJson()).toList(),
        'dailyTasks': dailyTasks.map((g) => g.toJson()).toList(),
        'todaysMission': todaysMission?.toJson(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'version': version,
      };

  factory Roadmap.fromJson(Map<String, dynamic> json) => Roadmap(
        id: json['id'] as String,
        userId: json['userId'] as String,
        longTermGoal:
            GoalItem.fromJson(json['longTermGoal'] as Map<String, dynamic>),
        monthlyGoals: (json['monthlyGoals'] as List<dynamic>)
            .map((g) => GoalItem.fromJson(g as Map<String, dynamic>))
            .toList(),
        weeklyGoals: (json['weeklyGoals'] as List<dynamic>)
            .map((g) => GoalItem.fromJson(g as Map<String, dynamic>))
            .toList(),
        dailyTasks: (json['dailyTasks'] as List<dynamic>)
            .map((g) => GoalItem.fromJson(g as Map<String, dynamic>))
            .toList(),
        todaysMission: json['todaysMission'] != null
            ? GoalItem.fromJson(
                json['todaysMission'] as Map<String, dynamic>,
              )
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        version: json['version'] as int? ?? 1,
      );

  @override
  List<Object?> get props => [id, userId, version];
}
