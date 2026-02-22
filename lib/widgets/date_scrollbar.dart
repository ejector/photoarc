import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A scrollbar that displays a floating date label (month/year) when the user
/// drags the scrollbar thumb. The label fades out after the user stops dragging.
class DateScrollbar extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  /// Ordered list of year-month strings (e.g. "2024-06") matching the current
  /// sort order displayed in the feed.
  final List<String> yearMonths;

  /// Map of yearMonth -> photo count, used to estimate scroll position mapping.
  final Map<String, int> photoCounts;

  const DateScrollbar({
    super.key,
    required this.controller,
    required this.child,
    required this.yearMonths,
    required this.photoCounts,
  });

  @override
  State<DateScrollbar> createState() => DateScrollbarState();
}

@visibleForTesting
class DateScrollbarState extends State<DateScrollbar> {
  bool _showLabel = false;
  String _currentYearMonth = '';
  Timer? _hideTimer;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          Scrollbar(
            controller: widget.controller,
            thumbVisibility: true,
            interactive: true,
            child: widget.child,
          ),
          Positioned(
            right: 24,
            top: 0,
            bottom: 0,
            child: Center(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: (_showLabel && _currentYearMonth.isNotEmpty)
                      ? 1.0
                      : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _DateLabel(yearMonth: _currentYearMonth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      _hideTimer?.cancel();
      final yearMonth = _resolveYearMonth(notification.metrics);
      if (yearMonth != null) {
        setState(() {
          _showLabel = true;
          _currentYearMonth = yearMonth;
        });
      }
    } else if (notification is ScrollEndNotification) {
      _scheduleHide();
    }
    // Don't consume the notification so the scrollbar still works.
    return false;
  }

  /// Maps the current scroll fraction to the corresponding year-month group.
  String? _resolveYearMonth(ScrollMetrics metrics) {
    if (widget.yearMonths.isEmpty) return null;
    if (metrics.maxScrollExtent <= 0) return widget.yearMonths.first;

    final fraction =
        (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0);

    // Build a cumulative weight list from photo counts so that groups with
    // more photos occupy proportionally more of the scrollbar range.
    final totalPhotos = widget.photoCounts.values.fold<int>(0, (a, b) => a + b);
    if (totalPhotos == 0) return widget.yearMonths.first;

    double cumulative = 0;
    for (final ym in widget.yearMonths) {
      final count = widget.photoCounts[ym] ?? 0;
      cumulative += count / totalPhotos;
      if (fraction <= cumulative) return ym;
    }

    return widget.yearMonths.last;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showLabel = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}

class _DateLabel extends StatelessWidget {
  final String yearMonth;

  const _DateLabel({required this.yearMonth});

  String get _formatted {
    try {
      final parts = yearMonth.split('-');
      if (parts.length != 2) return yearMonth;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return DateFormat.yMMM().format(DateTime(year, month));
    } catch (_) {
      return yearMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.inverseSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          _formatted,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onInverseSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
