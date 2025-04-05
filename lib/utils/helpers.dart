import 'package:flutter/material.dart';

class Helpers {

  // Route Navigation
  static PageRouteBuilder routeNavigation(BuildContext context, Widget routeDestination, {Object? arguments}) {
    return PageRouteBuilder(
        settings: MaterialPage(child: routeDestination, arguments: arguments),
        pageBuilder: (context, animation, secondaryAnimation) =>
            routeDestination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500));
  }

// Format date
  static String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

// Parse date
  static DateTime parseDate(String dateStr) {
    var parts = dateStr.split('/');
    if (parts.length != 3) {
      throw FormatException('Invalid date format');
    }
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }
}
