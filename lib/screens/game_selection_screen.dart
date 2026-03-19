import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/game_mode.dart';
import '../services/ble_service.dart';
import '../widgets/game_mode_card.dart';
import 'game_screen.dart';

class GameSelectionScreen extends ConsumerWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleServiceProvider);
    final connectedCount = bleState.connectedCount;
    final availableModes = GameModes.getAvailableModes(connectedCount);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, connectedCount),
              Expanded(
                child: _buildModeGrid(context, availableModes, connectedCount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int connectedCount) {
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
                  'SELECT GAME MODE',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$connectedCount target${connectedCount != 1 ? 's' : ''} connected',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeGrid(BuildContext context, List<GameMode> modes, int connectedCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: GameModes.all.length,
      itemBuilder: (context, index) {
        final mode = GameModes.all[index];
        final isAvailable = mode.minTargets <= connectedCount;
        
        return GameModeCard(
          mode: mode,
          isAvailable: isAvailable,
          requiredTargets: mode.minTargets,
          onTap: isAvailable ? () => _startGame(context, mode) : null,
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 50),
              duration: const Duration(milliseconds: 300),
            )
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              delay: Duration(milliseconds: index * 50),
              duration: const Duration(milliseconds: 300),
            );
      },
    );
  }

  void _startGame(BuildContext context, GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(mode: mode),
      ),
    );
  }
}
