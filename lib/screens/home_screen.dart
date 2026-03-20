import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/permissions_handler.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../widgets/neon_button.dart';
import '../widgets/connection_status_bar.dart';
import 'device_scan_screen.dart';
import 'game_selection_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleServiceProvider);
    final connectedCount = bleState.connectedCount;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Connection status bar
              if (connectedCount > 0)
                ConnectionStatusBar(deviceCount: connectedCount)
                    .animate()
                    .fadeIn()
                    .slideY(begin: -0.5, end: 0),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Main action buttons
                      _buildMainButtons(context, connectedCount),
                      
                      const SizedBox(height: 40),
                      
                      // Quick stats preview
                      _buildQuickStats(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // App logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_hockey,
              color: AppColors.background,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOCKEY SNIPE',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'TRAINER',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButtons(BuildContext context, int connectedCount) {
    return Column(
      children: [
        // Connect targets button
        NeonButton(
          onPressed: () => _openDeviceScan(context),
          icon: Icons.bluetooth_searching,
          label: connectedCount > 0 
              ? 'MANAGE TARGETS ($connectedCount/4)'
              : 'CONNECT TARGETS',
          color: connectedCount > 0 ? AppColors.success : AppColors.primary,
          isLarge: true,
        )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 400))
            .slideX(begin: -0.2, end: 0),
        
        const SizedBox(height: 20),
        
        // Start training button
        NeonButton(
          onPressed: connectedCount > 0 
              ? () => _openGameSelection(context)
              : null,
          icon: Icons.play_arrow,
          label: 'START TRAINING',
          color: AppColors.secondary,
          isLarge: true,
          disabled: connectedCount == 0,
        )
            .animate()
            .fadeIn(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 400),
            )
            .slideX(begin: 0.2, end: 0),
        
        const SizedBox(height: 20),
        
        // Quick play with simulation
        if (connectedCount == 0)
          TextButton.icon(
            onPressed: () => _startSimulationMode(context),
            icon: const Icon(Icons.gamepad, size: 18),
            label: const Text('Try Simulation Mode'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 400),
              ),
        
        const SizedBox(height: 20),
        
        // Stats button
        Row(
          children: [
            Expanded(
              child: NeonButton(
                onPressed: () => _openStats(context),
                icon: Icons.leaderboard,
                label: 'STATS',
                color: AppColors.info,
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 400),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final stats = storage.getPlayerStats();
    
    if (stats.totalGamesPlayed == 0) {
      return _buildWelcomeCard();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Stats',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Games', stats.totalGamesPlayed.toString()),
              _buildStatItem('Shots', stats.totalHits.toString()),
              _buildStatItem('Accuracy', '${stats.accuracy.toStringAsFixed(1)}%'),
              _buildStatItem('Best Streak', stats.bestOverallStreak.toString()),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 400),
        );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.sports_hockey,
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Hockey Snipe Trainer!',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your Snipe targets via Bluetooth to start training, or try simulation mode to explore the app.',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 400),
        );
  }

  Future<void> _openDeviceScan(BuildContext context) async {
    // Request permissions first
    final hasPermissions = await PermissionsHandler.requestBlePermissions(context);
    if (!hasPermissions) return;
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DeviceScanScreen()),
      );
    }
  }

  void _openGameSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameSelectionScreen()),
    );
  }

  void _openStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _startSimulationMode(BuildContext context) {
    // Enable simulation mode
    ref.read(bleServiceProvider.notifier).addMockDevices(4);
    ref.read(simulationModeProvider.notifier).state = true;
    
    // Navigate to game selection
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameSelectionScreen()),
    );
  }
}
