import 'package:equatable/equatable.dart';

enum FeedbackCategory {
  bug('Bug Report', 'Something is broken'),
  feature('Feature Request', 'I have an idea'),
  improvement('Improvement', 'Could be better'),
  praise('Praise', 'I love something');

  const FeedbackCategory(this.label, this.hint);

  final String label;
  final String hint;
}

class UserFeedback extends Equatable {
  const UserFeedback({
    required this.id,
    required this.userId,
    required this.category,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.userEmail,
    this.appVersion,
  });

  final String id;
  final String userId;
  final FeedbackCategory category;
  final String message;
  final int rating;
  final DateTime createdAt;
  final String? userEmail;
  final String? appVersion;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'category': category.name,
        'message': message,
        'rating': rating,
        'userEmail': userEmail,
        'appVersion': appVersion,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, userId, category, message, rating, createdAt, userEmail, appVersion];
}
