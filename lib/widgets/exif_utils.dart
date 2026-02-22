import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Returns the rotation angle in radians for the given EXIF orientation value.
double exifRotationAngle(int orientation) {
  switch (orientation) {
    case 6:
    case 5:
      return math.pi / 2;
    case 3:
    case 4:
      return math.pi;
    case 8:
    case 7:
      return -math.pi / 2;
    default:
      return 0;
  }
}

/// Returns true if the EXIF orientation requires a horizontal flip (mirroring).
bool exifRequiresFlip(int orientation) {
  return orientation == 2 ||
      orientation == 4 ||
      orientation == 5 ||
      orientation == 7;
}

/// Applies the EXIF orientation transform (rotation and optional flip) to a widget.
Widget applyExifTransform(Widget child, int orientation) {
  final angle = exifRotationAngle(orientation);
  final flip = exifRequiresFlip(orientation);

  if (angle == 0 && !flip) return child;

  Widget result = child;
  if (flip) {
    result = Transform.flip(flipX: true, child: result);
  }
  if (angle != 0) {
    result = Transform.rotate(angle: angle, child: result);
  }
  return result;
}
