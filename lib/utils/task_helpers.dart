// STEP 2.2: TASK HELPERS
// File: lib/modules/task_management/utils/task_helpers.dart

import 'package:intl/intl.dart';

class TaskHelpers {
  // ==================== DATE FORMATTING ====================

  /// Format date with smart logic (Today, Yesterday, etc.)
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE h:mm a').format(date);
    } else {
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    }
  }

  /// Format deadline with smart messaging
  static String formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      final daysOverdue = difference.inDays.abs();
      return 'Overdue by $daysOverdue day${daysOverdue == 1 ? '' : 's'}';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays} days';
    } else {
      return 'Due on ${DateFormat('MMM d, yyyy').format(deadline)}';
    }
  }

  // ==================== TIME CALCULATIONS ====================

  /// Calculate work hours between two timestamps
  static double calculateWorkHours(DateTime start, DateTime end) {
    final duration = end.difference(start);
    return duration.inMinutes / 60.0;
  }

  /// Format hours to readable string (e.g., "2h 30m")
  static String formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Get time ago string (e.g., "2h ago")
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years yr ago';
    }
  }

  /// Get countdown string (e.g., "2d left")
  static String getCountdown(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h left';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d left';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks wk left';
    }
  }

  // ==================== FILE HANDLING ====================

  /// Validate file size (max 10MB by default)
  static bool isFileSizeValid(int bytes, {int maxSizeMB = 10}) {
    final maxSize = maxSizeMB * 1024 * 1024;
    return bytes <= maxSize;
  }

  /// Get file extension from filename
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  /// Check if file is an image
  static bool isImageFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext);
  }

  /// Check if file is a PDF
  static bool isPdfFile(String fileName) {
    return getFileExtension(fileName) == 'pdf';
  }

  /// Check if file is a ZIP archive
  static bool isZipFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ['zip', 'rar', '7z'].contains(ext);
  }

  // ==================== ID GENERATION ====================

  /// Generate unique task ID
  static String generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate unique project ID
  static String generateProjectId() {
    return 'proj_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ==================== UI HELPERS ====================

  /// Get progress color based on percentage
  static String getProgressColor(double progress) {
    if (progress < 30) return '#EF4444'; // Red
    if (progress < 70) return '#F59E0B'; // Orange
    return '#10B981'; // Green
  }

  /// Format currency (Indian Rupees)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  /// Truncate text to max length
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get initials from name (e.g., "John Doe" -> "JD")
  static String getInitials(String name) {
    final names = name.trim().split(' ');
    if (names.isEmpty) return '';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  // ==================== VALIDATION ====================

  /// Validate email address
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate phone number (Indian format)
  static bool isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  // ==================== COLOR HELPERS ====================

  /// Get color from hex string
  static int getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }

  // ==================== SORTING ====================

  /// Sort tasks by priority (urgent -> low)
  static int sortByPriority(String priority1, String priority2) {
    final weight1 = _getPriorityWeight(priority1);
    final weight2 = _getPriorityWeight(priority2);
    return weight2.compareTo(weight1); // Descending
  }

  static int _getPriorityWeight(String priority) {
    switch (priority) {
      case 'urgent':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  // ==================== TEXT FORMATTING ====================

  /// Capitalize first letter of each word
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Convert snake_case to Title Case
  static String snakeToTitle(String text) {
    return text
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
