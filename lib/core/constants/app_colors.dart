import 'package:flutter/material.dart';

/// App color palette with hockey-themed neon colors
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B8D4);
  static const Color secondary = Color(0xFFFF1744);
  
  // Background colors
  static const Color background = Color(0xFF0A0E21);
  static const Color backgroundLight = Color(0xFF1A1F38);
  static const Color surface = Color(0xFF1D2137);
  static const Color surfaceLight = Color(0xFF252A43);
  
  // Target colors
  static const Color targetRed = Color(0xFFFF1744);
  static const Color targetGreen = Color(0xFF00E676);
  static const Color targetBlue = Color(0xFF2979FF);
  static const Color targetYellow = Color(0xFFFFEA00);
  static const Color targetOff = Color(0xFF37474F);
  
  // Status colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textDisabled = Color(0xFF546E7A);
  
  // Neon glow colors
  static const Color glowCyan = Color(0xFF00E5FF);
  static const Color glowRed = Color(0xFFFF1744);
  static const Color glowGreen = Color(0xFF00E676);
  static const Color glowBlue = Color(0xFF2979FF);
  
  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0E21), Color(0xFF1A1F38)],
  );
  
  static const LinearGradient iceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF01579B)],
  );

  /// Get target color by index (0-3)
  static Color getTargetColor(int index) {
    switch (index) {
      case 0:
        return targetRed;
      case 1:
        return targetGreen;
      case 2:
        return targetBlue;
      case 3:
        return targetYellow;
      default:
        return targetOff;
    }
  }

  /// Convert Color to RGB list for BLE commands
  static List<int> colorToRgb(Color color) {
    return [
      (color.r * 255).round().clamp(0, 255),
      (color.g * 255).round().clamp(0, 255),
      (color.b * 255).round().clamp(0, 255),
    ];
  }

  /// Create Color from RGB list
  static Color rgbToColor(List<int> rgb) {
    if (rgb.length < 3) return targetOff;
    return Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
  }
}
