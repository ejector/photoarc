import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import 'exif_utils.dart';

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

  String get _tooltipText {
    final date = DateFormat.yMMMd().add_jm().format(photo.dateTaken);
    return '$date\n${photo.directory}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final angle = exifRotationAngle(photo.orientation);

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
