import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../controllers/game_controller.dart';
import '../services/storage_service.dart';
import '../widgets/target_grid.dart';
import '../widgets/score_display.dart';
import '../widgets/timer_display.dart';
import '../widgets/game_result_overlay.dart';
import '../widgets/neon_button.dart';

class GameScreen extends ConsumerStatefulWidget {
  final GameMode mode;
  
  const GameScreen({super.key, required this.mode});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait for game
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Restore orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider(widget.mode));
    final controller = ref.read(gameControllerProvider(widget.mode).notifier);
    final isSimulation = ref.watch(simulationModeProvider);
    
    // Show results when game finishes
    if (gameState.isFinished && !_showResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showResults = true);
      });
    }
    
    return PopScope(
      canPop: !gameState.isPlaying,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !gameState.isPlaying) {
          return;
        }

        controller.pauseGame();
        final shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          controller.resumeGame();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
            ),
            
            // Game content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, gameState, controller),
                  _buildGameInfo(gameState),
                  Expanded(
                    child: _buildGameArea(gameState, controller, isSimulation),
                  ),
                  _buildControls(gameState, controller),
                ],
              ),
            ),
            
            // Countdown overlay
            if (gameState.status == GameStatus.countdown)
              _buildCountdownOverlay(gameState),
            
            // Results overlay
            if (_showResults)
              GameResultOverlay(
                gameState: gameState,
                onPlayAgain: () {
                  setState(() => _showResults = false);
                  controller.resetGame();
                },
                onBack: () {
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    GameState gameState,
    GameController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () async {
              if (gameState.isPlaying) {
                controller.pauseGame();
                final shouldExit = await _showExitDialog(context);
                if (!context.mounted) {
                  return;
                }
                if (shouldExit) {
                  Navigator.of(context).pop();
                } else {
                  controller.resumeGame();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mode.name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _getDifficultyText(gameState.difficulty),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: widget.mode.color,
                  ),
                ),
              ],
            ),
          ),
          if (gameState.status == GameStatus.idle)
            _buildDifficultySelector(gameState, controller),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector(GameState gameState, GameController controller) {
    return PopupMenuButton<GameDifficulty>(
      icon: const Icon(Icons.tune, color: AppColors.textSecondary),
      onSelected: (difficulty) => controller.setDifficulty(difficulty),
      itemBuilder: (context) => GameDifficulty.values.map((d) {
        return PopupMenuItem(
          value: d,
          child: Row(
            children: [
              if (d == gameState.difficulty)
                const Icon(Icons.check, color: AppColors.primary, size: 18),
              if (d != gameState.difficulty)
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(_getDifficultyText(d)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getDifficultyText(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
      case GameDifficulty.expert:
        return 'Expert';
    }
  }

  Widget _buildGameInfo(GameState gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Score
          ScoreDisplay(
            score: gameState.score,
            label: 'SCORE',
          ),
          
          // Timer
          if (widget.mode.type == GameModeType.timed ||
              widget.mode.type == GameModeType.targetBased)
            TimerDisplay(
              timeText: gameState.formattedTime,
              isCountdown: widget.mode.type == GameModeType.timed,
              color: gameState.remainingMs < 5000 && widget.mode.type == GameModeType.timed
                  ? AppColors.error
                  : AppColors.primary,
            ),
          
          // Combo
          ScoreDisplay(
            score: gameState.combo,
            label: 'COMBO',
            color: gameState.combo > 5 ? AppColors.warning : AppColors.textSecondary,
          ),
          
          // Hits or Progress
          if (widget.mode.type == GameModeType.targetBased)
            ScoreDisplay(
              score: gameState.hits,
              label: '/ ${widget.mode.targetHits}',
              color: AppColors.success,
            )
          else
            ScoreDisplay(
              score: gameState.hits,
              label: 'HITS',
            ),
        ],
      ),
    );
  }

  Widget _buildGameArea(
    GameState gameState,
    GameController controller,
    bool isSimulation,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Color hint for color hunt mode
          if (widget.mode.id == 'color_hunt' && 
              gameState.requiredColor != null &&
              gameState.isPlaying)
            _buildColorHint(gameState.requiredColor!),
          
          const SizedBox(height: 20),
          
          // Target grid
          Expanded(
            child: TargetGrid(
              targets: gameState.targets,
              onTargetTap: isSimulation && gameState.isPlaying
                  ? (index) => controller.simulateHit(index)
                  : widget.mode.id == 'practice'
                      ? (index) => controller.toggleTarget(index)
                      : null,
            ),
          ),
          
          // Simulation hint
          if (isSimulation && gameState.isPlaying)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Tap targets to simulate hits',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorHint(Color requiredColor) {
    String colorName = 'Unknown';
    if (requiredColor == AppColors.targetRed) {
      colorName = 'RED';
    } else if (requiredColor == AppColors.targetGreen) {
      colorName = 'GREEN';
    } else if (requiredColor == AppColors.targetBlue) {
      colorName = 'BLUE';
    } else if (requiredColor == AppColors.targetYellow) {
      colorName = 'YELLOW';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: requiredColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: requiredColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: requiredColor.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HIT: ',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            colorName,
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: requiredColor,
            ),
          ),
        ],
      ),
    )
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: const Duration(milliseconds: 500),
        );
  }

  Widget _buildControls(GameState gameState, GameController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (gameState.status == GameStatus.idle)
            Expanded(
              child: NeonButton(
                onPressed: () => controller.startCountdown(),
                icon: Icons.play_arrow,
                label: 'START',
                color: AppColors.success,
                isLarge: true,
              ),
            ),
          
          if (gameState.status == GameStatus.playing) ...[
            Expanded(
              child: NeonButton(
                onPressed: () => controller.pauseGame(),
                icon: Icons.pause,
                label: 'PAUSE',
                color: AppColors.warning,
              ),
            ),
          ],
          
          if (gameState.status == GameStatus.paused) ...[
            Expanded(
              child: NeonButton(
                onPressed: () => controller.resumeGame(),
                icon: Icons.play_arrow,
                label: 'RESUME',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeonButton(
                onPressed: () => controller.resetGame(),
                icon: Icons.refresh,
                label: 'RESTART',
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay(GameState gameState) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Text(
          gameState.message ?? '',
          style: GoogleFonts.orbitron(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            shadows: [
              Shadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 30,
              ),
            ],
          ),
        )
            .animate(
              onPlay: (c) => c.forward(),
              key: ValueKey(gameState.message),
            )
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: const Duration(milliseconds: 200)),
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Exit Game?',
          style: GoogleFonts.orbitron(color: AppColors.textPrimary),
        ),
        content: Text(
          'Your progress will be lost.',
          style: GoogleFonts.roboto(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('EXIT'),
          ),
        ],
      ),
    ) ?? false;
  }
}
