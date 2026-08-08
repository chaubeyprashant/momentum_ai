import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_logger.dart';
import '../../models/accountability.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/scheduled_task.dart';
import '../../models/screen_time.dart';
import '../../models/user_profile.dart';
import 'firebase_service.dart';

/// Firestore persistence for authenticated user data.
class FirestoreService {
  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  bool get isAvailable =>
      FirebaseService.instance.isInitialized && _auth.currentUser != null;

  String? get userId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _sub(
    String uid,
    String collection,
  ) =>
      _userDoc(uid).collection(collection);

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<void> saveUserProfile(UserProfile profile) async {
    if (!isAvailable) return;
    final uid = userId!;
    await _userDoc(uid).set(
      _withTimestamps(profile.toJson()),
      SetOptions(merge: true),
    );
  }

  Future<UserProfile?> getUserProfile() async {
    if (!isAvailable) return null;
    final snap = await _userDoc(userId!).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromJson(_fromFirestore(snap.data()!));
  }

  // ── Roadmap ──────────────────────────────────────────────────────────────

  Future<void> saveRoadmap(Roadmap roadmap) async {
    if (!isAvailable) return;
    await _sub(userId!, 'roadmaps').doc('current').set(
      _withTimestamps(roadmap.toJson()),
      SetOptions(merge: true),
    );
  }

  Future<Roadmap?> getRoadmap() async {
    if (!isAvailable) return null;
    final snap = await _sub(userId!, 'roadmaps').doc('current').get();
    if (!snap.exists || snap.data() == null) return null;
    return Roadmap.fromJson(_fromFirestore(snap.data()!));
  }

  // ── Scheduled tasks ──────────────────────────────────────────────────────

  Future<void> saveTasks(List<ScheduledTask> tasks) async {
    if (!isAvailable) return;
    final uid = userId!;
    final batch = _firestore.batch();
    final col = _sub(uid, 'tasks');

    for (final task in tasks) {
      final data = _withTimestamps(task.toJson())
        ..remove('photoPath'); // local-only path
      batch.set(col.doc(task.id), data, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> saveTask(ScheduledTask task) async {
    await saveTasks([task]);
  }

  Future<List<ScheduledTask>> getTasks() async {
    if (!isAvailable) return [];
    final snap = await _sub(userId!, 'tasks').get();
    return snap.docs
        .map((d) => ScheduledTask.fromJson(_fromFirestore(d.data())))
        .toList();
  }

  Future<void> deleteTask(String taskId) async {
    if (!isAvailable) return;
    await _sub(userId!, 'tasks').doc(taskId).delete();
  }

  // ── Habits ───────────────────────────────────────────────────────────────

  Future<void> saveHabits(List<Habit> habits) async {
    if (!isAvailable) return;
    final uid = userId!;
    final batch = _firestore.batch();
    final col = _sub(uid, 'habits');
    for (final habit in habits) {
      batch.set(
        col.doc(habit.id),
        _withTimestamps(habit.toJson()),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<List<Habit>> getHabits() async {
    if (!isAvailable) return [];
    final snap = await _sub(userId!, 'habits').get();
    return snap.docs
        .map((d) => Habit.fromJson(_fromFirestore(d.data())))
        .toList();
  }

  // ── Accountability ───────────────────────────────────────────────────────

  Future<void> saveAccountabilityRecords(
    List<AccountabilityRecord> records,
  ) async {
    if (!isAvailable) return;
    final uid = userId!;
    final batch = _firestore.batch();
    final col = _sub(uid, 'accountability');
    for (final record in records) {
      batch.set(
        col.doc(record.id),
        _withTimestamps(record.toJson()),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<List<AccountabilityRecord>> getAccountabilityRecords() async {
    if (!isAvailable) return [];
    final snap = await _sub(userId!, 'accountability').get();
    return snap.docs
        .map((d) => AccountabilityRecord.fromJson(_fromFirestore(d.data())))
        .toList();
  }

  // ── Journal ──────────────────────────────────────────────────────────────

  Future<void> saveJournalEntries(List<JournalEntry> entries) async {
    if (!isAvailable) return;
    final uid = userId!;
    final batch = _firestore.batch();
    final col = _sub(uid, 'journal');
    for (final entry in entries) {
      batch.set(
        col.doc(entry.id),
        _withTimestamps(entry.toJson()),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<List<JournalEntry>> getJournalEntries() async {
    if (!isAvailable) return [];
    final snap = await _sub(userId!, 'journal').get();
    return snap.docs
        .map((d) => JournalEntry.fromJson(_fromFirestore(d.data())))
        .toList();
  }

  // ── Focus sessions ───────────────────────────────────────────────────────

  Future<void> saveFocusSessions(List<FocusSession> sessions) async {
    if (!isAvailable) return;
    final uid = userId!;
    final batch = _firestore.batch();
    final col = _sub(uid, 'focus_sessions');
    for (final session in sessions) {
      batch.set(
        col.doc(session.id),
        _withTimestamps(session.toJson()),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<List<FocusSession>> getFocusSessions() async {
    if (!isAvailable) return [];
    final snap = await _sub(userId!, 'focus_sessions').get();
    return snap.docs
        .map((d) => FocusSession.fromJson(_fromFirestore(d.data())))
        .toList();
  }

  // ── Screen time ──────────────────────────────────────────────────────────

  Future<void> saveScreenTime({
    required ScreenTimeGoal goal,
    required List<ScreenTimeLog> logs,
  }) async {
    if (!isAvailable) return;
    await _userDoc(userId!).set(
      {
        'screenTimeGoal': goal.toJson(),
        'screenTimeLogs': logs.map((l) => l.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<({ScreenTimeGoal? goal, List<ScreenTimeLog> logs})> getScreenTime() async {
    if (!isAvailable) return (goal: null, logs: <ScreenTimeLog>[]);
    final snap = await _userDoc(userId!).get();
    final data = snap.data();
    if (data == null) return (goal: null, logs: <ScreenTimeLog>[]);

    final goalData = data['screenTimeGoal'] as Map<String, dynamic>?;
    final logsData = data['screenTimeLogs'] as List<dynamic>?;

    return (
      goal: goalData != null
          ? ScreenTimeGoal.fromJson(_fromFirestore(goalData))
          : null,
      logs: logsData
              ?.map((l) =>
                  ScreenTimeLog.fromJson(_fromFirestore(l as Map<String, dynamic>)))
              .toList() ??
          [],
    );
  }

  // ── Delete all user data ─────────────────────────────────────────────────

  Future<void> deleteAllUserData() async {
    if (!isAvailable) return;
    final uid = userId!;
    final collections = [
      'roadmaps',
      'tasks',
      'habits',
      'accountability',
      'journal',
      'focus_sessions',
    ];
    for (final name in collections) {
      await _deleteCollection(_sub(uid, name));
    }
    await _userDoc(uid).delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    final snap = await ref.limit(100).get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    if (snap.docs.length == 100) await _deleteCollection(ref);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _withTimestamps(Map<String, dynamic> data) {
    return {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _fromFirestore(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    for (final entry in result.entries.toList()) {
      final value = entry.value;
      if (value is Timestamp) {
        result[entry.key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        result[entry.key] = _fromFirestore(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[entry.key] = value.map((item) {
          if (item is Timestamp) return item.toDate().toIso8601String();
          if (item is Map) return _fromFirestore(Map<String, dynamic>.from(item));
          return item;
        }).toList();
      }
    }
    result.remove('updatedAt');
    return result;
  }

  void logError(String action, Object error, [StackTrace? stack]) {
    AppLogger.error('Firestore', '$action failed', error, stack);
  }
}
