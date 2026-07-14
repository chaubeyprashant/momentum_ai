import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/accountability.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/user_profile.dart';

/// Hive-backed local storage service.
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(AppConstants.userBox),
      Hive.openBox(AppConstants.goalsBox),
      Hive.openBox(AppConstants.habitsBox),
      Hive.openBox(AppConstants.journalBox),
      Hive.openBox(AppConstants.settingsBox),
    ]);
    _initialized = true;
  }

  Box get _userBox => Hive.box(AppConstants.userBox);
  Box get _goalsBox => Hive.box(AppConstants.goalsBox);
  Box get _habitsBox => Hive.box(AppConstants.habitsBox);
  Box get _journalBox => Hive.box(AppConstants.journalBox);
  Box get _settingsBox => Hive.box(AppConstants.settingsBox);

  // User Profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await _userBox.put('profile', jsonEncode(profile.toJson()));
  }

  UserProfile? getUserProfile() {
    final data = _userBox.get('profile') as String?;
    if (data == null) return null;
    return UserProfile.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  // Roadmap
  Future<void> saveRoadmap(Roadmap roadmap) async {
    await _goalsBox.put('roadmap', jsonEncode(roadmap.toJson()));
  }

  Roadmap? getRoadmap() {
    final data = _goalsBox.get('roadmap') as String?;
    if (data == null) return null;
    return Roadmap.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  // Accountability
  Future<void> saveAccountabilityRecords(
    List<AccountabilityRecord> records,
  ) async {
    await _settingsBox.put(
      'accountability',
      records.map((r) => r.toJson()).toList(),
    );
  }

  List<AccountabilityRecord> getAccountabilityRecords() {
    final data = _settingsBox.get('accountability') as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((r) => AccountabilityRecord.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // Habits
  Future<void> saveHabits(List<Habit> habits) async {
    await _habitsBox.put(
      'habits',
      habits.map((h) => h.toJson()).toList(),
    );
  }

  List<Habit> getHabits() {
    final data = _habitsBox.get('habits') as List<dynamic>?;
    if (data == null) return _defaultHabits();
    return data.map((h) => Habit.fromJson(h as Map<String, dynamic>)).toList();
  }

  // Journal
  Future<void> saveJournalEntries(List<JournalEntry> entries) async {
    await _journalBox.put(
      'entries',
      entries.map((e) => e.toJson()).toList(),
    );
  }

  List<JournalEntry> getJournalEntries() {
    final data = _journalBox.get('entries') as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Focus sessions
  Future<void> saveFocusSessions(List<FocusSession> sessions) async {
    await _settingsBox.put(
      'focus_sessions',
      sessions.map((s) => s.toJson()).toList(),
    );
  }

  List<FocusSession> getFocusSessions() {
    final data = _settingsBox.get('focus_sessions') as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((s) => FocusSession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  // Coach messages
  Future<void> saveCoachMessage(String message) async {
    await _settingsBox.put('last_coach_message', message);
  }

  String? getLastCoachMessage() =>
      _settingsBox.get('last_coach_message') as String?;

  Future<void> clearAll() async {
    await Future.wait([
      _userBox.clear(),
      _goalsBox.clear(),
      _habitsBox.clear(),
      _journalBox.clear(),
      _settingsBox.clear(),
    ]);
  }

  List<Habit> _defaultHabits() => [
        const Habit(id: '1', name: 'Morning Routine', icon: '🌅'),
        const Habit(id: '2', name: 'Workout', icon: '💪'),
        const Habit(id: '3', name: 'Meditation', icon: '🧘'),
        const Habit(id: '4', name: 'Reading', icon: '📚'),
        const Habit(id: '5', name: 'Water Intake', icon: '💧'),
      ];
}

/// Firebase initialization wrapper — enable when config files are added.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // await Firebase.initializeApp();
      // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      _initialized = false; // Set true after Firebase config
    } catch (e) {
      throw StorageException('Firebase init failed: $e');
    }
  }
}
