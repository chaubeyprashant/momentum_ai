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

  static double clampPercent(double value) => value.clamp(0.0, 100.0);
}
