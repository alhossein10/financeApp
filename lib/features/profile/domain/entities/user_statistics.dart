/// User statistics entity
class UserStatistics {
  final double totalExpenses;
  final double totalTransfers;
  final int totalTransactions;
  final int accountAgeDays;
  final DateTime? lastActivity;

  const UserStatistics({
    required this.totalExpenses,
    required this.totalTransfers,
    required this.totalTransactions,
    required this.accountAgeDays,
    this.lastActivity,
  });

  /// Get account age in a human-readable format
  String get accountAgeFormatted {
    if (accountAgeDays < 30) {
      return '$accountAgeDays days';
    } else if (accountAgeDays < 365) {
      final months = (accountAgeDays / 30).floor();
      return '$months months';
    } else {
      final years = (accountAgeDays / 365).floor();
      final remainingMonths = ((accountAgeDays % 365) / 30).floor();
      if (remainingMonths > 0) {
        return '$years years, $remainingMonths months';
      }
      return '$years years';
    }
  }
}