import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE-related constants for Snipe targets
class BleConstants {
  BleConstants._();

  // Device identification
  // CUSTOMIZE: Update these to match your actual Snipe target device
  static const String targetDeviceNamePrefix = 'SNIPE';
  static const String targetDeviceNameAlt = 'SnipeLight';
  
  // Service UUIDs (CUSTOMIZE: Replace with actual Snipe target UUIDs)
  static final Guid primaryServiceUuid = Guid('00001800-0000-1000-8000-00805f9b34fb');
  static final Guid targetServiceUuid = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
  
  // Characteristic UUIDs (CUSTOMIZE: Replace with actual UUIDs)
  static final Guid colorCharacteristicUuid = Guid('0000ffe1-0000-1000-8000-00805f9b34fb');
  static final Guid powerCharacteristicUuid = Guid('0000ffe2-0000-1000-8000-00805f9b34fb');
  static final Guid hitNotificationUuid = Guid('0000ffe3-0000-1000-8000-00805f9b34fb');
  static final Guid batteryCharacteristicUuid = Guid('0000ffe4-0000-1000-8000-00805f9b34fb');
  static final Guid configCharacteristicUuid = Guid('0000ffe5-0000-1000-8000-00805f9b34fb');
  
  // Connection settings
  static const Duration scanTimeout = Duration(seconds: 15);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration writeTimeout = Duration(seconds: 5);
  static const int maxTargets = 4;
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectDelay = Duration(seconds: 2);
  
  // Command bytes
  static const int cmdPowerOn = 0x01;
  static const int cmdPowerOff = 0x00;
  static const int cmdFlash = 0x02;
  static const int cmdPulse = 0x03;
  static const int cmdRainbow = 0x04;
  static const int cmdReset = 0xFF;
  
  // Hit detection
  static const int hitEventByte = 0x01;
  static const int missEventByte = 0x00;
  
  // Battery thresholds
  static const int batteryLow = 20;
  static const int batteryMedium = 50;
  
  // Signal strength thresholds (RSSI in dBm)
  static const int rssiExcellent = -50;
  static const int rssiGood = -65;
  static const int rssiFair = -80;
  static const int rssiPoor = -90;

  /// Check if device name matches Snipe target pattern
  static bool isSnipeTarget(String? deviceName) {
    if (deviceName == null || deviceName.isEmpty) return false;
    final upperName = deviceName.toUpperCase();
    return upperName.contains(targetDeviceNamePrefix.toUpperCase()) ||
           upperName.contains(targetDeviceNameAlt.toUpperCase());
  }

  /// Get signal quality description from RSSI
  static String getSignalQuality(int rssi) {
    if (rssi >= rssiExcellent) return 'Excellent';
    if (rssi >= rssiGood) return 'Good';
    if (rssi >= rssiFair) return 'Fair';
    return 'Weak';
  }

  /// Get signal quality percentage (0-100)
  static int getSignalPercentage(int rssi) {
    // Clamp RSSI between -100 and -30
    final clamped = rssi.clamp(-100, -30);
    // Map to 0-100 percentage
    return ((clamped + 100) * 100 / 70).round().clamp(0, 100);
  }

  /// Build color command bytes [mode, R, G, B]
  static List<int> buildColorCommand(int r, int g, int b, {int mode = cmdPowerOn}) {
    return [mode, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255)];
  }

  /// Build power command
  static List<int> buildPowerCommand(bool on) {
    return [on ? cmdPowerOn : cmdPowerOff];
  }

  /// Build flash command with color
  static List<int> buildFlashCommand(int r, int g, int b, {int durationMs = 500}) {
    return [cmdFlash, r, g, b, (durationMs ~/ 10).clamp(0, 255)];
  }
}
