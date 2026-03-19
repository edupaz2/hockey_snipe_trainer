import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Handles all permission requests for BLE functionality
class PermissionsHandler {
  PermissionsHandler._();

  /// Request all necessary permissions for BLE scanning and connection
  static Future<bool> requestBlePermissions(BuildContext context) async {
    // Check if Bluetooth is supported
    if (!await FlutterBluePlus.isSupported) {
      _showError(context, 'Bluetooth is not supported on this device');
      return false;
    }

    // Check and enable Bluetooth adapter
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
        // Wait for adapter to turn on
        await Future.delayed(const Duration(seconds: 1));
      } else {
        _showError(context, 'Please enable Bluetooth in Settings');
        return false;
      }
    }

    if (Platform.isAndroid) {
      return await _requestAndroidPermissions(context);
    } else if (Platform.isIOS) {
      return await _requestIosPermissions(context);
    }

    return true;
  }

  static Future<bool> _requestAndroidPermissions(BuildContext context) async {
    final permissions = <Permission>[];
    
    // Android 12+ (API 31+) requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT
    // Android 11 and below requires location
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ]);
    }

    final statuses = await permissions.request();
    
    // Check if critical permissions are granted
    final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final locationGranted = statuses[Permission.location]?.isGranted ?? false;
    
    // On newer Android, location might not be strictly required for BLE
    // but we still request it for broader compatibility
    final hasRequiredPermissions = scanGranted && connectGranted;
    
    if (!hasRequiredPermissions) {
      final permanentlyDenied = statuses.values.any(
        (status) => status.isPermanentlyDenied,
      );
      
      if (permanentlyDenied) {
        _showPermissionDeniedDialog(context);
      } else {
        _showError(
          context,
          'Bluetooth permissions are required to connect to targets',
        );
      }
      return false;
    }

    // Location service check (required for BLE scanning on some devices)
    if (!locationGranted) {
      final locationService = await Permission.location.serviceStatus;
      if (!locationService.isEnabled) {
        _showError(
          context,
          'Location services are required for BLE scanning. Please enable them in Settings.',
        );
        return false;
      }
    }

    return true;
  }

  static Future<bool> _requestIosPermissions(BuildContext context) async {
    // On iOS, Bluetooth permission is requested automatically by the system
    // when we start scanning. We just need to handle the response.
    final status = await Permission.bluetooth.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(context);
      return false;
    }

    return true;
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Bluetooth permissions are required to connect to Snipe targets. '
          'Please grant permissions in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Check if all required permissions are already granted
  static Future<bool> hasAllPermissions() async {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.isGranted;
      final connect = await Permission.bluetoothConnect.isGranted;
      return scan && connect;
    } else if (Platform.isIOS) {
      final bluetooth = await Permission.bluetooth.isGranted;
      return bluetooth;
    }
    return true;
  }
}
