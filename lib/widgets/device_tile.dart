import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/target_device.dart';

/// Displays a BLE device in the scan list
class DeviceTile extends StatelessWidget {
  final TargetDevice device;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const DeviceTile({
    super.key,
    required this.device,
    this.onConnect,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = device.connectionState == TargetConnectionState.connected;
    final isConnecting = device.connectionState == TargetConnectionState.connecting;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected 
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.2),
          width: isConnected ? 2 : 1,
        ),
        boxShadow: isConnected
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isConnecting
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _getStatusColor(),
                      ),
                    ),
                  )
                : Icon(
                    isConnected 
                        ? Icons.bluetooth_connected 
                        : Icons.bluetooth,
                    color: _getStatusColor(),
                  ),
          ),
          const SizedBox(width: 16),
          
          // Device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (device.isMock)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SIM',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Signal strength
                    _buildSignalIndicator(),
                    const SizedBox(width: 8),
                    Text(
                      device.signalQuality,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (device.batteryLevel != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        _getBatteryIcon(),
                        size: 16,
                        color: _getBatteryColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${device.batteryLevel}%',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Action button
          if (isConnected)
            TextButton(
              onPressed: onDisconnect,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('DISCONNECT'),
            )
          else if (isConnecting)
            const TextButton(
              onPressed: null,
              child: Text(
                'CONNECTING...',
                style: TextStyle(color: AppColors.textDisabled),
              ),
            )
          else
            TextButton(
              onPressed: onConnect,
              child: const Text('CONNECT'),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (device.connectionState) {
      case TargetConnectionState.connected:
        return AppColors.success;
      case TargetConnectionState.connecting:
      case TargetConnectionState.disconnecting:
        return AppColors.warning;
      case TargetConnectionState.error:
        return AppColors.error;
      case TargetConnectionState.disconnected:
        return AppColors.primary;
    }
  }

  Widget _buildSignalIndicator() {
    final percentage = device.signalPercentage;
    final bars = (percentage / 25).ceil().clamp(1, 4);
    
    return Row(
      children: List.generate(4, (i) {
        return Container(
          width: 3,
          height: 6.0 + (i * 2),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: i < bars 
                ? AppColors.success
                : AppColors.textDisabled.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  IconData _getBatteryIcon() {
    final level = device.batteryLevel ?? 0;
    if (level > 80) return Icons.battery_full;
    if (level > 60) return Icons.battery_5_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor() {
    final level = device.batteryLevel ?? 0;
    if (level > 50) return AppColors.success;
    if (level > 20) return AppColors.warning;
    return AppColors.error;
  }
}
