import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthHeader extends StatelessWidget {
  final String yearMonth;

  const MonthHeader({super.key, required this.yearMonth});

  String get _formattedLabel {
    try {
      final parts = yearMonth.split('-');
      if (parts.length != 2) return yearMonth;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat.yMMMM().format(date);
    } catch (_) {
      return yearMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        _formattedLabel,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
