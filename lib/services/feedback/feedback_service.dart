import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../models/user_feedback.dart';
import '../firebase/firebase_service.dart';

class FeedbackService {
  FeedbackService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  bool get isAvailable =>
      FirebaseService.instance.isInitialized && _auth.currentUser != null;

  Future<void> submit({
    required FeedbackCategory category,
    required String message,
    required int rating,
  }) async {
    if (!isAvailable) {
      throw StateError('Sign in to send feedback');
    }

    final user = _auth.currentUser!;
    final feedback = UserFeedback(
      id: _uuid.v4(),
      userId: user.uid,
      category: category,
      message: message.trim(),
      rating: rating,
      userEmail: user.email,
      appVersion: AppConstants.appVersion,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('feedback').doc(feedback.id).set({
      ...feedback.toJson(),
      'submittedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.info('Feedback', 'Submitted ${category.name} feedback');
  }
}
