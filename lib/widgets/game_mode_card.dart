import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/game_mode.dart';

/// Card displaying a game mode in the selection grid
class GameModeCard extends StatelessWidget {
  final GameMode mode;
  final bool isAvailable;
  final int requiredTargets;
  final VoidCallback? onTap;

  const GameModeCard({
    super.key,
    required this.mode,
    required this.isAvailable,
    required this.requiredTargets,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAvailable 
              ? AppColors.surface 
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable 
                ? mode.color.withValues(alpha: 0.5)
                : AppColors.textDisabled.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: mode.color.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? mode.color.withValues(alpha: 0.2)
                        : AppColors.textDisabled.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    mode.icon,
                    color: isAvailable ? mode.color : AppColors.textDisabled,
                  ),
                ),
                const Spacer(),
                if (!isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$requiredTargets+ targets',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                if (isAvailable && mode.supportsMultiplayer)
                  Icon(
                    Icons.people,
                    size: 16,
                    color: mode.color.withValues(alpha: 0.7),
                  ),
              ],
            ),
            
            const Spacer(),
            
            // Name
            Text(
              mode.name,
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isAvailable 
                    ? AppColors.textPrimary 
                    : AppColors.textDisabled,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Description
            Expanded(
              child: Text(
                mode.description,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: isAvailable 
                      ? AppColors.textSecondary 
                      : AppColors.textDisabled,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Mode type indicator
            Row(
              children: [
                Icon(
                  _getModeTypeIcon(),
                  size: 14,
                  color: isAvailable 
                      ? mode.color.withValues(alpha: 0.7)
                      : AppColors.textDisabled,
                ),
                const SizedBox(width: 4),
                Text(
                  _getModeTypeText(),
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: isAvailable 
                        ? mode.color.withValues(alpha: 0.7)
                        : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModeTypeIcon() {
    switch (mode.type) {
      case GameModeType.timed:
        return Icons.timer;
      case GameModeType.targetBased:
        return Icons.flag;
      case GameModeType.survival:
        return Icons.favorite;
      case GameModeType.practice:
        return Icons.sports_hockey;
    }
  }

  String _getModeTypeText() {
    switch (mode.type) {
      case GameModeType.timed:
        return '${mode.durationSeconds}s';
      case GameModeType.targetBased:
        return '${mode.targetHits} hits';
      case GameModeType.survival:
        return 'Survival';
      case GameModeType.practice:
        return 'Practice';
    }
  }
}
