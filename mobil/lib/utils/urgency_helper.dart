import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UrgencyHelper {
  UrgencyHelper._();

  /// Get color for urgency level
  static Color getUrgencyColor(String urgencyLabel) {
    switch (urgencyLabel.toUpperCase()) {
      case 'ACIL':
        return AppColors.urgencyCritical;
      case 'ÖNCELİKLİ':
      case 'PRIORITY':
        return AppColors.urgencyHigh;
      case 'NORMAL':
        return AppColors.urgencyNormal;
      default:
        return AppColors.urgencyUnknown;
    }
  }

  /// Get icon for urgency level
  static IconData getUrgencyIcon(String urgencyLabel) {
    switch (urgencyLabel.toUpperCase()) {
      case 'ACIL':
        return Icons.warning;
      case 'ÖNCELİKLİ':
      case 'PRIORITY':
        return Icons.priority_high;
      case 'NORMAL':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  /// Get estimated wait time in minutes based on queue number
  static int getEstimatedWaitTime(int queueNumber) {
    // Simple calculation: queue number % 7 + 3 gives 3-9 minutes range
    return (queueNumber % 7) + 3;
  }
}

