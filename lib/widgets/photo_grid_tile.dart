import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';

class PhotoGridTile extends StatelessWidget {
  final Photo photo;
  final Uint8List? thumbnailBytes;
  final VoidCallback? onTap;

  const PhotoGridTile({
    super.key,
    required this.photo,
    this.thumbnailBytes,
    this.onTap,
  });

  double _rotationAngle(int orientation) {
    switch (orientation) {
      case 6:
        return math.pi / 2;
      case 3:
        return math.pi;
      case 8:
        return -math.pi / 2;
      default:
        return 0;
    }
  }

  String get _tooltipText {
    final date = DateFormat.yMMMd().add_jm().format(photo.dateTaken);
    return '$date\n${photo.directory}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final angle = _rotationAngle(photo.orientation);

    Widget imageWidget;
    if (thumbnailBytes != null) {
      imageWidget = Image.memory(
        thumbnailBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
      if (angle != 0) {
        imageWidget = Transform.rotate(angle: angle, child: imageWidget);
      }
    } else {
      imageWidget = Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.photo_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
        ),
      );
    }

    return Tooltip(
      message: _tooltipText,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: imageWidget,
        ),
      ),
    );
  }
}
