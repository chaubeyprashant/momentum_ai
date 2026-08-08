/// Utility helpers used across the app.
class AppUtils {
  AppUtils._();

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  static String formatHours(double hours) {
    if (hours < 1) return '${(hours * 60).round()} min';
    return '${hours.toStringAsFixed(1)} hr';
  }

  static int xpForLevel(int level) => level * level * 100;

  static int levelFromXp(int xp) {
    var level = 1;
    while (xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  static int xpProgressInLevel(int xp, int level) {
    final currentLevelXp = xpForLevel(level);
    return xp - currentLevelXp;
  }

  static int xpNeededForNextLevel(int level) {
    return xpForLevel(level + 1) - xpForLevel(level);
  }

  static double xpProgressPercent(int xp, int level) {
    final needed = xpNeededForNextLevel(level);
    if (needed <= 0) return 1;
    return (xpProgressInLevel(xp, level) / needed).clamp(0.0, 1.0);
  }

  static String rankTitle(int level) {
    if (level >= 15) return 'Legend';
    if (level >= 10) return 'Champion';
    if (level >= 6) return 'Veteran';
    if (level >= 3) return 'Apprentice';
    return 'Rookie';
  }

  static double clampPercent(double value) => value.clamp(0.0, 100.0);
}
