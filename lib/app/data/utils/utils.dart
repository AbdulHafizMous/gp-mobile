import 'package:timeago/timeago.dart' as timeago;

String convertToDate(DateTime date) {
  return timeago.format(date);
}
