class TaskProgressUnits {
  const TaskProgressUnits._();

  static double timer({
    required Duration? currentDuration,
    required Iterable<Duration?> loggedDurations,
  }) {
    final currentSeconds = currentDuration?.inSeconds ?? 0;
    if (currentSeconds > 0) return currentSeconds.toDouble();
    return loggedDurations.fold<double>(
      0,
      (total, duration) => total + (duration?.inSeconds ?? 0),
    );
  }

  static double counter({
    required int? currentCount,
    required Iterable<int?> loggedCounts,
  }) {
    final current = currentCount ?? 0;
    if (current > 0) return current.toDouble();
    return loggedCounts.fold<double>(
      0,
      (total, count) => total + (count ?? 0),
    );
  }
}
