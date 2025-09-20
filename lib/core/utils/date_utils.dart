import 'package:intl/intl.dart';

class AppDateUtils {
  // Date formatters
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dayFormatter = DateFormat('EEEE');
  static final DateFormat _monthFormatter = DateFormat('MMMM yyyy');
  static final DateFormat _shortDateFormatter = DateFormat('dd MMM');
  static final DateFormat _fullDateFormatter = DateFormat('EEEE, dd MMMM yyyy');
  static final DateFormat _isoFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _timestampFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  
  // Format date to string
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }
  
  // Format time to string
  static String formatTime(DateTime date) {
    return _timeFormatter.format(date);
  }
  
  // Format date and time to string
  static String formatDateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }
  
  // Format day name
  static String formatDay(DateTime date) {
    return _dayFormatter.format(date);
  }
  
  // Format month and year
  static String formatMonth(DateTime date) {
    return _monthFormatter.format(date);
  }
  
  // Format short date (e.g., "15 Jan")
  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }
  
  // Format full date (e.g., "Monday, 15 January 2024")
  static String formatFullDate(DateTime date) {
    return _fullDateFormatter.format(date);
  }
  
  // Format ISO date (e.g., "2024-01-15")
  static String formatISODate(DateTime date) {
    return _isoFormatter.format(date);
  }
  
  // Format timestamp (e.g., "2024-01-15 14:30:00")
  static String formatTimestamp(DateTime date) {
    return _timestampFormatter.format(date);
  }
  
  // Parse date from string
  static DateTime? parseDate(String dateString) {
    try {
      return _dateFormatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  // Parse date time from string
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return _dateTimeFormatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
  
  // Parse ISO date from string
  static DateTime? parseISODate(String isoDateString) {
    try {
      return _isoFormatter.parse(isoDateString);
    } catch (e) {
      return null;
    }
  }
  
  // Get relative time (e.g., "2 hours ago", "Yesterday", "Last week")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }
  
  // Get time of day greeting
  static String getTimeGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
  
  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
  
  // Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }
  
  // Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
  
  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }
  
  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToSunday)));
  }
  
  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }
  
  // Get age from birth date
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  
  // Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }
  
  // Get list of dates in range
  static List<DateTime> getDatesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = startOfDay(start);
    final endDate = startOfDay(end);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  // Get next reminder time based on frequency
  static DateTime getNextReminderTime(DateTime lastReminder, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return lastReminder.add(const Duration(days: 1));
      case 'weekly':
        return lastReminder.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
          lastReminder.year,
          lastReminder.month + 1,
          lastReminder.day,
          lastReminder.hour,
          lastReminder.minute,
        );
      case 'yearly':
        return DateTime(
          lastReminder.year + 1,
          lastReminder.month,
          lastReminder.day,
          lastReminder.hour,
          lastReminder.minute,
        );
      default:
        return lastReminder.add(const Duration(days: 1));
    }
  }
  
  // Format duration (e.g., "2h 30m", "1d 5h")
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '${days}d ${hours}h';
      } else {
        return '${days}d';
      }
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  // Check if time is within business hours (9 AM to 6 PM)
  static bool isBusinessHours(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= 9 && hour < 18;
  }
  
  // Get next business day
  static DateTime getNextBusinessDay(DateTime date) {
    var nextDay = date.add(const Duration(days: 1));
    
    // Skip weekends
    while (nextDay.weekday == DateTime.saturday || 
           nextDay.weekday == DateTime.sunday) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    
    return nextDay;
  }
}
