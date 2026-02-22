import 'dart:math' as math;

/// Returns the rotation angle in radians for the given EXIF orientation value.
double exifRotationAngle(int orientation) {
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
