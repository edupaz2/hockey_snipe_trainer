import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/ble_constants.dart';
import '../models/target_device.dart';
import '../services/ble_service.dart';
import '../widgets/device_tile.dart';

class DeviceScanScreen extends ConsumerStatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  ConsumerState<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends ConsumerState<DeviceScanScreen> {
  @override
  void initState() {
    super.initState();
    // Start scanning when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bleServiceProvider.notifier).startScan();
    });
  }

  @override
  void dispose() {
    // Stop scanning when leaving
    ref.read(bleServiceProvider.notifier).stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleServiceProvider);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, bleState),
              _buildStatusBar(bleState),
              Expanded(
                child: _buildDeviceList(bleState),
              ),
              _buildBottomBar(context, bleState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, BleServiceState bleState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONNECT TARGETS',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${bleState.connectedCount}/${BleConstants.maxTargets} connected',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Scan button
          Container(
            decoration: BoxDecoration(
              color: bleState.isScanning 
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: bleState.isScanning
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: bleState.isScanning
                  ? null
                  : () => ref.read(bleServiceProvider.notifier).startScan(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BleServiceState bleState) {
    if (!bleState.isBluetoothOn) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bluetooth_disabled, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bluetooth is turned off. Please enable Bluetooth to scan for targets.',
                style: GoogleFonts.roboto(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }
    
    if (bleState.errorMessage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bleState.errorMessage!,
                style: GoogleFonts.roboto(color: AppColors.warning),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildDeviceList(BleServiceState bleState) {
    // Combine connected and discovered devices
    final allDevices = <TargetDevice>[];
    
    // Add connected devices first
    allDevices.addAll(bleState.connectedDevices);
    
    // Add discovered devices that aren't already connected
    for (final device in bleState.discoveredDevices) {
      if (!allDevices.any((d) => d.id == device.id)) {
        allDevices.add(device);
      }
    }
    
    if (allDevices.isEmpty) {
      return _buildEmptyState(bleState);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allDevices.length,
      itemBuilder: (context, index) {
        final device = allDevices[index];
        return DeviceTile(
          device: device,
          onConnect: bleState.connectedCount < BleConstants.maxTargets
              ? () => _connectDevice(device)
              : null,
          onDisconnect: () => _disconnectDevice(device),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 100),
              duration: const Duration(milliseconds: 300),
            )
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildEmptyState(BleServiceState bleState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            bleState.isScanning 
                ? Icons.bluetooth_searching 
                : Icons.bluetooth,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          )
              .animate(
                onPlay: (controller) => bleState.isScanning 
                    ? controller.repeat() 
                    : null,
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: const Duration(milliseconds: 800),
              )
              .then()
              .scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(1, 1),
                duration: const Duration(milliseconds: 800),
              ),
          const SizedBox(height: 24),
          Text(
            bleState.isScanning 
                ? 'Scanning for Snipe targets...'
                : 'No Snipe targets found',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your targets are powered on\nand in pairing mode.',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppColors.textDisabled,
            ),
            textAlign: TextAlign.center,
          ),
          if (!bleState.isScanning) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => ref.read(bleServiceProvider.notifier).startScan(),
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BleServiceState bleState) {
    if (bleState.connectedCount == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'DONE (${bleState.connectedCount} connected)',
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn()
        .slideY(begin: 0.5, end: 0);
  }

  Future<void> _connectDevice(TargetDevice device) async {
    final success = await ref.read(bleServiceProvider.notifier).connectToDevice(device);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to ${device.name}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _disconnectDevice(TargetDevice device) async {
    await ref.read(bleServiceProvider.notifier).disconnectFromDevice(device.id);
  }
}
