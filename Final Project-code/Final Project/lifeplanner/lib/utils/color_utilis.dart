import 'package:flutter/material.dart';

class ColorUtils {
  /// Converts a [Color] to a hex string, like #aabbcc
  static String toHex(Color color) {
    // Flutter 3.14+: .r, .g, .b, .a return normalized doubles (0.0–1.0)
    // Multiply by 255 and round to get integer channel values
    final int red = (color.r * 255).round();
    final int green = (color.g * 255).round();
    final int blue = (color.b * 255).round();
    // Convert each channel to a two-digit hex string
    return '#'
        '${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
  }

  /// Parses a hex string and returns a [Color].
  /// Accepts formats like "#aabbcc" or "ffaabbcc".
  static Color fromHex(String hexString) {
    try {
      hexString = hexString.replaceFirst('#', '');
      if (hexString.length == 6) hexString = 'ff$hexString';
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      // Fallback to a default color if parsing fails
      return Colors.blue;
    }
  }
}
