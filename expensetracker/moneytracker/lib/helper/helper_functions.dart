/*
 These are helper functions to be used in the app
*/
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

// convert string to double
double convertStringToDouble(String str) {
  double? amount = double.tryParse(str);
  return amount ?? 0.0;
}

// format double amount into rupees and paisa
String formatAsRupees(double amount) {
  final format =
      NumberFormat.currency(locale: "en_IN", symbol: "\₹", decimalDigits: 2);
  return format.format(amount);
}

// calculate the number of months since the first month
int calculateMonthCount(int startYear, startMonth, currentYear, currentMonth) {
  int monthCount =
      (currentYear - startYear) * 12 + currentMonth - startMonth + 1;
  return monthCount;
}
