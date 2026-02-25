import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateFormatter {
  /// Formate une date en dd/MM/yyyy
  static String format(DateTime date) {
    final formatter = DateFormat(AppConstants.dateFormat, 'fr_FR');
    return formatter.format(date);
  }
  
  /// Formate une date et heure en dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat(AppConstants.dateTimeFormat, 'fr_FR');
    return formatter.format(dateTime);
  }
  
  /// Parse une chaîne en DateTime
  static DateTime? parse(String dateString) {
    try {
      final formatter = DateFormat(AppConstants.dateFormat, 'fr_FR');
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Retourne la date du jour formatée
  static String today() {
    return format(DateTime.now());
  }
  
  /// Retourne le premier jour du mois
  static DateTime firstDayOfMonth([DateTime? date]) {
    date ??= DateTime.now();
    return DateTime(date.year, date.month, 1);
  }
  
  /// Retourne le dernier jour du mois
  static DateTime lastDayOfMonth([DateTime? date]) {
    date ??= DateTime.now();
    return DateTime(date.year, date.month + 1, 0);
  }
  
  /// Vérifie si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
  
  /// Retourne le nombre de jours entre deux dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  
  /// Formate une date de manière relative (aujourd'hui, hier, etc.)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return "Aujourd'hui";
    } else if (dateDay == yesterday) {
      return 'Hier';
    } else if (dateDay.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE', 'fr_FR').format(date);
    } else {
      return format(date);
    }
  }
}