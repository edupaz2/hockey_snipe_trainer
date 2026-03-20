import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/game_state.dart';
import 'neon_button.dart';

/// Overlay shown when a game ends
class GameResultOverlay extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  const GameResultOverlay({
    super.key,
    required this.gameState,
    required this.onPlayAgain,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = gameState.message?.contains('HIGH SCORE') ?? false;
    
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                if (isNewHighScore) ...[
                  Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: AppColors.warning,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 16),
                  Text(
                    'NEW HIGH SCORE!',
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .shimmer(
                        duration: const Duration(seconds: 2),
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                ] else ...[
                  Text(
                    'GAME OVER',
                    style: GoogleFonts.orbitron(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .slideY(begin: -0.5, end: 0),
                ],
                
                const SizedBox(height: 32),
                
                // Score
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: gameState.mode.color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SCORE',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gameState.score.toString(),
                        style: GoogleFonts.orbitron(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: gameState.mode.color,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 200))
                    .scale(begin: const Offset(0.8, 0.8)),
                
                const SizedBox(height: 24),
                
                // Stats grid
                _buildStatsGrid()
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 300))
                    .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 32),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    NeonButton(
                      onPressed: onBack,
                      icon: Icons.arrow_back,
                      label: 'EXIT',
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 16),
                    NeonButton(
                      onPressed: onPlayAgain,
                      icon: Icons.replay,
                      label: 'PLAY AGAIN',
                      color: AppColors.success,
                      isLarge: true,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 400)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem('Hits', gameState.hits.toString(), AppColors.success),
              _buildStatItem('Misses', gameState.misses.toString(), AppColors.error),
              _buildStatItem(
                'Accuracy',
                '${gameState.accuracy.toStringAsFixed(1)}%',
                AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                'Best Combo',
                gameState.bestCombo.toString(),
                AppColors.warning,
              ),
              _buildStatItem(
                'Avg Reaction',
                '${gameState.averageReactionTimeMs}ms',
                AppColors.primary,
              ),
              _buildStatItem(
                'Best Reaction',
                gameState.bestReactionTimeMs > 0 
                    ? '${gameState.bestReactionTimeMs}ms' 
                    : '-',
                AppColors.glowCyan,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
