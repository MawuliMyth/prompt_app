import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }
}
