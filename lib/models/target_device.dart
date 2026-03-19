import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/ble_constants.dart';

/// Represents the connection state of a target device
enum TargetConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Represents a Snipe target device with all its properties
class TargetDevice {
  final String id;
  final String name;
  final BluetoothDevice? bleDevice;
  final int rssi;
  final TargetConnectionState connectionState;
  final int? batteryLevel;
  final Color currentColor;
  final bool isOn;
  final int targetIndex; // Position in the goal (0-3)
  final DateTime? lastHitTime;
  final int hitCount;
  final String? errorMessage;

  const TargetDevice({
    required this.id,
    required this.name,
    this.bleDevice,
    this.rssi = -100,
    this.connectionState = TargetConnectionState.disconnected,
    this.batteryLevel,
    this.currentColor = AppColors.targetOff,
    this.isOn = false,
    this.targetIndex = 0,
    this.lastHitTime,
    this.hitCount = 0,
    this.errorMessage,
  });

  /// Create from BLE scan result
  factory TargetDevice.fromScanResult(ScanResult result, int index) {
    return TargetDevice(
      id: result.device.remoteId.str,
      name: result.device.platformName.isNotEmpty 
          ? result.device.platformName 
          : 'Snipe Target ${index + 1}',
      bleDevice: result.device,
      rssi: result.rssi,
      targetIndex: index,
    );
  }

  /// Create a mock device for testing/simulation
  factory TargetDevice.mock(int index) {
    return TargetDevice(
      id: 'mock-target-$index',
      name: 'Snipe Target ${index + 1}',
      rssi: -50 - (index * 5),
      connectionState: TargetConnectionState.connected,
      batteryLevel: 75 + (index * 5),
      currentColor: AppColors.getTargetColor(index),
      isOn: true,
      targetIndex: index,
    );
  }

  /// Check if this is a simulated/mock device
  bool get isMock => id.startsWith('mock-');

  /// Get connection state text
  String get connectionStateText {
    switch (connectionState) {
      case TargetConnectionState.disconnected:
        return 'Disconnected';
      case TargetConnectionState.connecting:
        return 'Connecting...';
      case TargetConnectionState.connected:
        return 'Connected';
      case TargetConnectionState.disconnecting:
        return 'Disconnecting...';
      case TargetConnectionState.error:
        return errorMessage ?? 'Error';
    }
  }

  /// Get signal quality
  String get signalQuality => BleConstants.getSignalQuality(rssi);
  int get signalPercentage => BleConstants.getSignalPercentage(rssi);

  /// Check if device can accept commands
  bool get canSendCommands => 
      connectionState == TargetConnectionState.connected;

  /// Create copy with updated properties
  TargetDevice copyWith({
    String? id,
    String? name,
    BluetoothDevice? bleDevice,
    int? rssi,
    TargetConnectionState? connectionState,
    int? batteryLevel,
    Color? currentColor,
    bool? isOn,
    int? targetIndex,
    DateTime? lastHitTime,
    int? hitCount,
    String? errorMessage,
  }) {
    return TargetDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      bleDevice: bleDevice ?? this.bleDevice,
      rssi: rssi ?? this.rssi,
      connectionState: connectionState ?? this.connectionState,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      currentColor: currentColor ?? this.currentColor,
      isOn: isOn ?? this.isOn,
      targetIndex: targetIndex ?? this.targetIndex,
      lastHitTime: lastHitTime ?? this.lastHitTime,
      hitCount: hitCount ?? this.hitCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TargetDevice(id: $id, name: $name, state: $connectionState, '
        'rssi: $rssi, battery: $batteryLevel%, index: $targetIndex)';
  }
}
