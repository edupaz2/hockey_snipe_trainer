import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/ble_constants.dart';
import '../core/constants/app_colors.dart';
import '../models/target_device.dart';

/// BLE Service state
class BleServiceState {
  final bool isScanning;
  final bool isBluetoothOn;
  final List<TargetDevice> discoveredDevices;
  final List<TargetDevice> connectedDevices;
  final String? errorMessage;
  
  const BleServiceState({
    this.isScanning = false,
    this.isBluetoothOn = false,
    this.discoveredDevices = const [],
    this.connectedDevices = const [],
    this.errorMessage,
  });
  
  BleServiceState copyWith({
    bool? isScanning,
    bool? isBluetoothOn,
    List<TargetDevice>? discoveredDevices,
    List<TargetDevice>? connectedDevices,
    String? errorMessage,
  }) {
    return BleServiceState(
      isScanning: isScanning ?? this.isScanning,
      isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      errorMessage: errorMessage,
    );
  }
  
  int get connectedCount => connectedDevices.length;
  bool get hasConnectedDevices => connectedDevices.isNotEmpty;
  bool get canStartGame => connectedDevices.isNotEmpty;
}

/// BLE Service for managing Snipe target connections
class BleService extends StateNotifier<BleServiceState> {
  BleService() : super(const BleServiceState()) {
    _initialize();
  }

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connectionSubscriptions = {};
  final Map<String, StreamSubscription<List<int>>> _notificationSubscriptions = {};
  final Map<String, BluetoothCharacteristic> _colorCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _powerCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _hitCharacteristics = {};

  /// Callback for hit notifications
  void Function(String deviceId, int targetIndex)? onHitReceived;

  Future<void> _initialize() async {
    // Listen to Bluetooth adapter state
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((s) {
      state = state.copyWith(isBluetoothOn: s == BluetoothAdapterState.on);
    });
    
    // Check initial state
    final adapterState = await FlutterBluePlus.adapterState.first;
    state = state.copyWith(isBluetoothOn: adapterState == BluetoothAdapterState.on);
  }

  /// Start scanning for Snipe targets
  Future<void> startScan() async {
    if (state.isScanning) return;
    
    try {
      // Clear previous discoveries
      state = state.copyWith(
        isScanning: true,
        discoveredDevices: [],
        errorMessage: null,
      );
      
      // Listen to scan results
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final devices = <TargetDevice>[];
        var index = 0;
        
        for (final result in results) {
          // Filter for Snipe targets
          if (BleConstants.isSnipeTarget(result.device.platformName) ||
              _isAlreadyConnected(result.device.remoteId.str)) {
            devices.add(TargetDevice.fromScanResult(result, index));
            index++;
          }
        }
        
        state = state.copyWith(discoveredDevices: devices);
      });
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: BleConstants.scanTimeout,
        androidUsesFineLocation: true,
      );
      
      // Update state when scan completes
      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Scan failed: ${e.toString()}',
      );
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    state = state.copyWith(isScanning: false);
  }

  bool _isAlreadyConnected(String deviceId) {
    return state.connectedDevices.any((d) => d.id == deviceId);
  }

  /// Connect to a target device
  Future<bool> connectToDevice(TargetDevice device) async {
    if (state.connectedDevices.length >= BleConstants.maxTargets) {
      state = state.copyWith(errorMessage: 'Maximum targets already connected');
      return false;
    }
    
    if (device.bleDevice == null) {
      state = state.copyWith(errorMessage: 'Invalid device');
      return false;
    }
    
    try {
      // Update device state to connecting
      _updateDeviceState(device.id, TargetConnectionState.connecting);
      
      // Connect
      await device.bleDevice!.connect(
        timeout: BleConstants.connectionTimeout,
        autoConnect: false,
      );
      
      // Listen for disconnection
      _connectionSubscriptions[device.id]?.cancel();
      _connectionSubscriptions[device.id] = device.bleDevice!.connectionState.listen(
        (connectionState) {
          if (connectionState == BluetoothConnectionState.disconnected) {
            _handleDisconnection(device.id);
          }
        },
      );
      
      // Discover services
      final services = await device.bleDevice!.discoverServices();
      await _setupCharacteristics(device.id, services);
      
      // Update state
      final targetIndex = state.connectedDevices.length;
      final connectedDevice = device.copyWith(
        connectionState: TargetConnectionState.connected,
        targetIndex: targetIndex,
        currentColor: AppColors.getTargetColor(targetIndex),
      );
      
      state = state.copyWith(
        connectedDevices: [...state.connectedDevices, connectedDevice],
      );
      
      return true;
    } catch (e) {
      _updateDeviceState(device.id, TargetConnectionState.error, 
          errorMessage: e.toString());
      return false;
    }
  }

  Future<void> _setupCharacteristics(String deviceId, List<BluetoothService> services) async {
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        // Color characteristic
        if (characteristic.uuid == BleConstants.colorCharacteristicUuid) {
          _colorCharacteristics[deviceId] = characteristic;
        }
        // Power characteristic
        else if (characteristic.uuid == BleConstants.powerCharacteristicUuid) {
          _powerCharacteristics[deviceId] = characteristic;
        }
        // Hit notification characteristic
        else if (characteristic.uuid == BleConstants.hitNotificationUuid) {
          _hitCharacteristics[deviceId] = characteristic;
          
          // Enable notifications for hit detection
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            _notificationSubscriptions[deviceId]?.cancel();
            _notificationSubscriptions[deviceId] = characteristic.onValueReceived.listen(
              (value) => _handleHitNotification(deviceId, value),
            );
          }
        }
      }
    }
  }

  void _handleHitNotification(String deviceId, List<int> value) {
    if (value.isEmpty) return;
    
    // Check if this is a hit event
    if (value[0] == BleConstants.hitEventByte) {
      final device = state.connectedDevices.firstWhere(
        (d) => d.id == deviceId,
        orElse: () => throw StateError('Device not found'),
      );
      
      // Update hit count
      final updatedDevices = state.connectedDevices.map((d) {
        if (d.id == deviceId) {
          return d.copyWith(
            hitCount: d.hitCount + 1,
            lastHitTime: DateTime.now(),
          );
        }
        return d;
      }).toList();
      
      state = state.copyWith(connectedDevices: updatedDevices);
      
      // Notify callback
      onHitReceived?.call(deviceId, device.targetIndex);
    }
  }

  void _handleDisconnection(String deviceId) {
    _cleanup(deviceId);
    
    final updatedDevices = state.connectedDevices
        .where((d) => d.id != deviceId)
        .toList();
    
    // Re-index remaining devices
    for (var i = 0; i < updatedDevices.length; i++) {
      updatedDevices[i] = updatedDevices[i].copyWith(targetIndex: i);
    }
    
    state = state.copyWith(connectedDevices: updatedDevices);
  }

  void _cleanup(String deviceId) {
    _connectionSubscriptions[deviceId]?.cancel();
    _connectionSubscriptions.remove(deviceId);
    _notificationSubscriptions[deviceId]?.cancel();
    _notificationSubscriptions.remove(deviceId);
    _colorCharacteristics.remove(deviceId);
    _powerCharacteristics.remove(deviceId);
    _hitCharacteristics.remove(deviceId);
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    final device = state.connectedDevices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw StateError('Device not found'),
    );
    
    _updateDeviceState(deviceId, TargetConnectionState.disconnecting);
    
    try {
      await device.bleDevice?.disconnect();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
    
    _handleDisconnection(deviceId);
  }

  /// Disconnect from all devices
  Future<void> disconnectAll() async {
    final devices = List<TargetDevice>.from(state.connectedDevices);
    for (final device in devices) {
      await disconnectFromDevice(device.id);
    }
  }

  void _updateDeviceState(
    String deviceId, 
    TargetConnectionState connectionState, {
    String? errorMessage,
  }) {
    // Update in discovered devices
    final discoveredDevices = state.discoveredDevices.map((d) {
      if (d.id == deviceId) {
        return d.copyWith(
          connectionState: connectionState,
          errorMessage: errorMessage,
        );
      }
      return d;
    }).toList();
    
    // Update in connected devices
    final connectedDevices = state.connectedDevices.map((d) {
      if (d.id == deviceId) {
        return d.copyWith(
          connectionState: connectionState,
          errorMessage: errorMessage,
        );
      }
      return d;
    }).toList();
    
    state = state.copyWith(
      discoveredDevices: discoveredDevices,
      connectedDevices: connectedDevices,
    );
  }

  // ============================================================
  // TARGET CONTROL METHODS
  // ============================================================

  /// Set target color by RGB values
  /// CUSTOMIZE: Modify the byte format to match your Snipe target protocol
  Future<bool> writeColor(String deviceId, List<int> rgb) async {
    final characteristic = _colorCharacteristics[deviceId];
    if (characteristic == null) {
      debugPrint('Color characteristic not found for $deviceId');
      return false;
    }
    
    try {
      final command = BleConstants.buildColorCommand(rgb[0], rgb[1], rgb[2]);
      await characteristic.write(command, withoutResponse: true);
      
      // Update device color state
      final color = AppColors.rgbToColor(rgb);
      _updateDeviceColor(deviceId, color);
      
      return true;
    } catch (e) {
      debugPrint('Write color error: $e');
      return false;
    }
  }

  /// Turn target on/off
  Future<bool> writePower(String deviceId, bool on) async {
    final characteristic = _powerCharacteristics[deviceId];
    if (characteristic == null) {
      // Fall back to color characteristic with power command
      final colorChar = _colorCharacteristics[deviceId];
      if (colorChar == null) return false;
      
      try {
        await colorChar.write([on ? 0x01 : 0x00], withoutResponse: true);
        _updateDevicePower(deviceId, on);
        return true;
      } catch (e) {
        debugPrint('Write power error: $e');
        return false;
      }
    }
    
    try {
      await characteristic.write(
        BleConstants.buildPowerCommand(on),
        withoutResponse: true,
      );
      _updateDevicePower(deviceId, on);
      return true;
    } catch (e) {
      debugPrint('Write power error: $e');
      return false;
    }
  }

  /// Flash target with color
  Future<bool> flashTarget(String deviceId, List<int> rgb, {int durationMs = 500}) async {
    final characteristic = _colorCharacteristics[deviceId];
    if (characteristic == null) return false;
    
    try {
      final command = BleConstants.buildFlashCommand(rgb[0], rgb[1], rgb[2], durationMs: durationMs);
      await characteristic.write(command, withoutResponse: true);
      return true;
    } catch (e) {
      debugPrint('Flash error: $e');
      return false;
    }
  }

  /// Turn all targets off
  Future<void> allTargetsOff() async {
    for (final device in state.connectedDevices) {
      await writePower(device.id, false);
    }
  }

  /// Set all targets to same color
  Future<void> setAllTargetsColor(Color color) async {
    final rgb = AppColors.colorToRgb(color);
    for (final device in state.connectedDevices) {
      await writeColor(device.id, rgb);
    }
  }

  /// Activate a specific target by index
  Future<void> activateTarget(int targetIndex, Color color) async {
    if (targetIndex >= state.connectedDevices.length) return;
    
    final device = state.connectedDevices[targetIndex];
    await writeColor(device.id, AppColors.colorToRgb(color));
    await writePower(device.id, true);
  }

  /// Deactivate a specific target
  Future<void> deactivateTarget(int targetIndex) async {
    if (targetIndex >= state.connectedDevices.length) return;
    
    final device = state.connectedDevices[targetIndex];
    await writePower(device.id, false);
  }

  void _updateDeviceColor(String deviceId, Color color) {
    final updatedDevices = state.connectedDevices.map((d) {
      if (d.id == deviceId) {
        return d.copyWith(currentColor: color);
      }
      return d;
    }).toList();
    
    state = state.copyWith(connectedDevices: updatedDevices);
  }

  void _updateDevicePower(String deviceId, bool isOn) {
    final updatedDevices = state.connectedDevices.map((d) {
      if (d.id == deviceId) {
        return d.copyWith(isOn: isOn);
      }
      return d;
    }).toList();
    
    state = state.copyWith(connectedDevices: updatedDevices);
  }

  // ============================================================
  // SIMULATION MODE (for testing without physical targets)
  // ============================================================

  /// Add mock devices for testing
  void addMockDevices(int count) {
    final mockDevices = List.generate(
      count.clamp(1, 4),
      (i) => TargetDevice.mock(i),
    );
    
    state = state.copyWith(
      connectedDevices: mockDevices,
      isBluetoothOn: true,
    );
  }

  /// Simulate a hit on a target (for testing)
  void simulateHit(int targetIndex) {
    if (targetIndex >= state.connectedDevices.length) return;
    
    final device = state.connectedDevices[targetIndex];
    _handleHitNotification(device.id, [BleConstants.hitEventByte]);
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    for (final sub in _connectionSubscriptions.values) {
      sub.cancel();
    }
    for (final sub in _notificationSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// Provider for BLE service
final bleServiceProvider = StateNotifierProvider<BleService, BleServiceState>((ref) {
  return BleService();
});

/// Provider for connected device count
final connectedDeviceCountProvider = Provider<int>((ref) {
  return ref.watch(bleServiceProvider).connectedCount;
});

/// Provider for checking if we can start a game
final canStartGameProvider = Provider<bool>((ref) {
  return ref.watch(bleServiceProvider).canStartGame;
});
