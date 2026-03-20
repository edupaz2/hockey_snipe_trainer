import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);
    final volume = ref.watch(volumeProvider);
    final simulationMode = ref.watch(simulationModeProvider);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      'Audio',
                      [
                        _buildSwitchTile(
                          'Sound Effects',
                          'Play sounds during gameplay',
                          Icons.volume_up,
                          soundEnabled,
                          (value) {
                            ref.read(soundEnabledProvider.notifier).state = value;
                            ref.read(audioServiceProvider).setSoundEnabled(value);
                            storage.setSoundEnabled(value);
                          },
                        ),
                        if (soundEnabled)
                          _buildSliderTile(
                            'Volume',
                            Icons.volume_down,
                            volume,
                            (value) {
                              ref.read(volumeProvider.notifier).state = value;
                              ref.read(audioServiceProvider).setVolume(value);
                              storage.setVolume(value);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Debug',
                      [
                        _buildSwitchTile(
                          'Simulation Mode',
                          'Test without physical targets',
                          Icons.gamepad,
                          simulationMode,
                          (value) {
                            ref.read(simulationModeProvider.notifier).state = value;
                            storage.setSimulationMode(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'About',
                      [
                        _buildInfoTile(
                          'Version',
                          '1.0.0',
                          Icons.info_outline,
                        ),
                        _buildInfoTile(
                          'Developer',
                          'Hockey Snipe Trainer Team',
                          Icons.code,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildBleProtocolInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'SETTINGS',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.roboto(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withValues(alpha: 0.3),
              onChanged: onChanged,
            ),
          ),
          const Icon(Icons.volume_up, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.roboto(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBleProtocolInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth, color: AppColors.info),
              const SizedBox(width: 8),
              Text(
                'BLE Protocol Info',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'To customize the BLE protocol for your Snipe targets:\n\n'
            '1. Edit lib/core/constants/ble_constants.dart\n'
            '2. Update Service UUID and Characteristic UUIDs\n'
            '3. Modify command byte formats in buildColorCommand()\n'
            '4. Adjust hit notification parsing in ble_service.dart',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
