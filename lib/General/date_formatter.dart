/// Date formatting utility for consistent date display across the app
class DateFormatter {
  /// Format date as "11 April" for current year, "11 April 2025" for other years
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    final monthName = monthNames[date.month - 1];

    if (date.year == now.year) {
      return "${date.day} $monthName";
    } else {
      return "${date.day} $monthName ${date.year}";
    }
  }

  /// Format date with relative time for recent dates
  /// Returns time for today, "Yesterday" for yesterday, days ago for last 7 days,
  /// otherwise uses standard date format
  static String formatDateRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }
}
