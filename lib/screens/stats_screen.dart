import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/game_mode.dart';
import '../models/player_stats.dart';
import '../services/storage_service.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final stats = storage.getPlayerStats();
    
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverallStats(stats),
                      const SizedBox(height: 24),
                      _buildModeStats(storage),
                      const SizedBox(height: 24),
                      _buildResetButton(context, ref),
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
            'STATISTICS',
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

  Widget _buildOverallStats(PlayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_hockey, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'Overall Performance',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(
                'Games\nPlayed',
                stats.totalGamesPlayed.toString(),
                AppColors.primary,
              ),
              _buildStatCard(
                'Total\nShots',
                stats.totalHits.toString(),
                AppColors.success,
              ),
              _buildStatCard(
                'Overall\nAccuracy',
                '${stats.accuracy.toStringAsFixed(1)}%',
                AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Best\nStreak',
                stats.bestOverallStreak.toString(),
                AppColors.secondary,
              ),
              _buildStatCard(
                'Best\nReaction',
                stats.bestReactionTimeMs > 0 
                    ? '${stats.bestReactionTimeMs}ms' 
                    : '-',
                AppColors.info,
              ),
              _buildStatCard(
                'Total\nTime',
                stats.formattedTotalPlayTime,
                AppColors.glowCyan,
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeStats(StorageService storage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'High Scores by Mode',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...GameModes.all.asMap().entries.map((entry) {
          final index = entry.key;
          final mode = entry.value;
          final modeStats = storage.getModeStats(mode.id);
          
          if (modeStats.gamesPlayed == 0) return const SizedBox.shrink();
          
          return _buildModeStatCard(mode, modeStats)
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: const Duration(milliseconds: 300),
              )
              .slideX(begin: 0.1, end: 0);
        }),
        
        // Show message if no games played
        if (GameModes.all.every((m) => storage.getModeStats(m.id).gamesPlayed == 0))
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.leaderboard,
                    size: 48,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No high scores yet',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Play some games to see your stats!',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeStatCard(GameMode mode, ModeStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mode.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Mode icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: mode.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(mode.icon, color: mode.color),
          ),
          const SizedBox(width: 16),
          
          // Mode info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.name,
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.gamesPlayed} games played',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Best score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'BEST',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: AppColors.textDisabled,
                ),
              ),
              Text(
                stats.bestScore.toString(),
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mode.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showResetDialog(context, ref),
        icon: const Icon(Icons.delete_outline, color: AppColors.error),
        label: Text(
          'Reset All Statistics',
          style: GoogleFonts.roboto(color: AppColors.error),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Reset Statistics?',
          style: GoogleFonts.orbitron(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will permanently delete all your high scores and statistics. This action cannot be undone.',
          style: GoogleFonts.roboto(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(storageServiceProvider).resetAllStats();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics reset')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
}
