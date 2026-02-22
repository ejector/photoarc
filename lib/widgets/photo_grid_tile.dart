import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../services/thumbnail_service.dart';
import 'exif_utils.dart';

class PhotoGridTile extends StatefulWidget {
  final Photo photo;
  final ThumbnailService thumbnailService;
  final VoidCallback? onTap;

  const PhotoGridTile({
    super.key,
    required this.photo,
    required this.thumbnailService,
    this.onTap,
  });

  @override
  State<PhotoGridTile> createState() => _PhotoGridTileState();
}

class _PhotoGridTileState extends State<PhotoGridTile> {
  Uint8List? _thumbnailBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(PhotoGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.path != widget.photo.path) {
      _loadThumbnail();
    }
  }

  void _loadThumbnail() {
    // Try memory cache first (synchronous, no jank)
    final cached = widget.thumbnailService.getFromMemory(widget.photo.path);
    if (cached != null) {
      _thumbnailBytes = cached;
      return;
    }

    // Load from disk asynchronously
    _loading = true;
    widget.thumbnailService
        .loadThumbnail(
          photoPath: widget.photo.path,
          thumbnailPath: widget.photo.thumbnailPath,
        )
        .then((bytes) {
      if (mounted) {
        setState(() {
          _thumbnailBytes = bytes;
          _loading = false;
        });
      }
    });
  }

  String get _tooltipText {
    final date = DateFormat.yMMMd().add_jm().format(widget.photo.dateTaken);
    return '$date\n${widget.photo.directory}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget imageWidget;
    if (_thumbnailBytes != null) {
      imageWidget = Image.memory(
        _thumbnailBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
      imageWidget =
          applyExifTransform(imageWidget, widget.photo.orientation);
    } else {
      imageWidget = Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Icon(
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
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: imageWidget,
        ),
      ),
    );
  }
}
