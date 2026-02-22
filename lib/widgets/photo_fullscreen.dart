import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../services/platform_service.dart';

class PhotoFullscreen extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final PlatformService platformService;

  const PhotoFullscreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.platformService,
  });

  /// Shows the fullscreen overlay as a dialog.
  static Future<void> show({
    required BuildContext context,
    required List<Photo> photos,
    required int initialIndex,
    required PlatformService platformService,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => PhotoFullscreen(
        photos: photos,
        initialIndex: initialIndex,
        platformService: platformService,
      ),
    );
  }

  @override
  State<PhotoFullscreen> createState() => _PhotoFullscreenState();
}

class _PhotoFullscreenState extends State<PhotoFullscreen> {
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  Photo get _currentPhoto => widget.photos[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.photos.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goToPrevious();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goToNext();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

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

  Widget _buildImage() {
    final photo = _currentPhoto;
    final file = File(photo.path);
    final angle = _rotationAngle(photo.orientation);

    Widget image = Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, color: Colors.white54, size: 64),
            SizedBox(height: 8),
            Text(
              'Unable to load image',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        );
      },
    );

    if (angle != 0) {
      image = Transform.rotate(angle: angle, child: image);
    }

    return image;
  }

  Widget _buildBottomBar() {
    final photo = _currentPhoto;
    final dateStr = DateFormat.yMMMd().add_jm().format(photo.dateTaken);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    photo.path,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () =>
                  widget.platformService.openFileManager(photo.path),
              icon: const Icon(Icons.folder_open, color: Colors.white70),
              label: const Text(
                'Open Folder',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white70, size: 28),
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildNavigationCounter() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image area - stop tap propagation so clicking image doesn't close
              GestureDetector(
                onTap: () {},
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 64,
                    ),
                    child: _buildImage(),
                  ),
                ),
              ),
              _buildBottomBar(),
              _buildCloseButton(),
              _buildNavigationCounter(),
              // Left arrow
              if (_currentIndex > 0)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white54,
                        size: 40,
                      ),
                      onPressed: _goToPrevious,
                    ),
                  ),
                ),
              // Right arrow
              if (_currentIndex < widget.photos.length - 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                        size: 40,
                      ),
                      onPressed: _goToNext,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
