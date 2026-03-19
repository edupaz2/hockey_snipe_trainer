import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../services/ble_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

/// Controller for managing game sessions
class GameController extends StateNotifier<GameState> {
  final BleService bleService;
  final AudioService audioService;
  final StorageService storageService;
  final Random _random = Random();
  
  Timer? _gameTimer;
  Timer? _targetTimer;
  DateTime? _targetActivatedAt;
  int _countdownValue = 3;

  GameController({
    required this.bleService,
    required this.audioService,
    required this.storageService,
    required GameMode initialMode,
    required int targetCount,
    GameDifficulty difficulty = GameDifficulty.medium,
  }) : super(GameState.initial(initialMode, targetCount, difficulty)) {
    // Listen for hits from BLE
    bleService.onHitReceived = _onHitReceived;
  }

  // ============================================================
  // GAME LIFECYCLE
  // ============================================================

  /// Start countdown before game
  void startCountdown() {
    _countdownValue = 3;
    state = state.copyWith(
      status: GameStatus.countdown,
      message: '$_countdownValue',
    );
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownValue--;
      
      if (_countdownValue > 0) {
        audioService.play(GameSound.countdown);
        state = state.copyWith(message: '$_countdownValue');
      } else {
        timer.cancel();
        audioService.play(GameSound.gameStart);
        _startGame();
      }
    });
  }

  void _startGame() {
    state = state.copyWith(
      status: GameStatus.playing,
      message: null,
    );
    
    // Start game timer
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), _onTimerTick);
    
    // Activate first target
    _activateNextTarget();
  }

  void _onTimerTick(Timer timer) {
    if (state.status != GameStatus.playing) return;
    
    final mode = state.mode;
    
    if (mode.type == GameModeType.timed) {
      // Count down
      final remaining = state.remainingMs - 100;
      if (remaining <= 0) {
        _endGame();
        return;
      }
      state = state.copyWith(
        remainingMs: remaining,
        elapsedMs: state.elapsedMs + 100,
      );
    } else {
      // Count up
      state = state.copyWith(elapsedMs: state.elapsedMs + 100);
    }
    
    // Check for survival mode timeout
    if (mode.type == GameModeType.survival) {
      _checkMissTimeout();
    }
  }

  void _checkMissTimeout() {
    if (_targetActivatedAt == null || state.activeTargetIndex == null) return;
    
    final elapsed = DateTime.now().difference(_targetActivatedAt!).inMilliseconds;
    final currentInterval = _getCurrentInterval();
    
    if (elapsed > currentInterval + 500) { // 500ms grace period
      _onMiss();
    }
  }

  /// Pause the game
  void pauseGame() {
    if (state.status != GameStatus.playing) return;
    
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    
    // Turn off all targets
    bleService.allTargetsOff();
    
    state = state.copyWith(status: GameStatus.paused);
  }

  /// Resume the game
  void resumeGame() {
    if (state.status != GameStatus.paused) return;
    
    state = state.copyWith(status: GameStatus.playing);
    
    // Restart timers
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), _onTimerTick);
    _activateNextTarget();
  }

  /// End the game
  void _endGame() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    
    audioService.play(GameSound.gameEnd);
    bleService.allTargetsOff();
    
    state = state.copyWith(status: GameStatus.finished);
    
    // Save result
    _saveGameResult();
  }

  /// Reset game state
  void resetGame() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    
    bleService.allTargetsOff();
    
    state = GameState.initial(
      state.mode, 
      state.targets.length, 
      state.difficulty,
    );
  }

  // ============================================================
  // TARGET MANAGEMENT
  // ============================================================

  void _activateNextTarget() {
    if (state.status != GameStatus.playing) return;
    
    final mode = state.mode;
    int targetIndex;
    Color targetColor;
    
    // Determine which target to activate based on game mode
    if (mode.customConfig['singleTarget'] == true) {
      // Marksman mode: same target
      targetIndex = state.activeTargetIndex ?? 0;
      targetColor = AppColors.targetRed;
    } else if (mode.customConfig['sequencePattern'] == true) {
      // Four Corners: sequential pattern
      targetIndex = state.hits % state.targets.length;
      targetColor = AppColors.getTargetColor(targetIndex);
    } else {
      // Random target
      targetIndex = _getRandomTargetIndex();
      targetColor = _getTargetColor(mode);
    }
    
    // For color hunt mode, set required color
    if (mode.id == 'color_hunt') {
      final colors = [
        AppColors.targetRed,
        AppColors.targetGreen,
        AppColors.targetBlue,
        AppColors.targetYellow,
      ];
      targetColor = colors[_random.nextInt(colors.length)];
      state = state.copyWith(requiredColor: targetColor);
      
      // Activate multiple targets with different colors
      _activateMultipleTargetsForColorHunt(targetColor);
      return;
    }
    
    // Activate single target
    _activateSingleTarget(targetIndex, targetColor);
  }

  void _activateSingleTarget(int targetIndex, Color color) {
    // Update target state
    final updatedTargets = state.targets.map((t) {
      if (t.index == targetIndex) {
        return t.copyWith(
          isActive: true,
          color: color,
          activatedAt: DateTime.now(),
        );
      }
      return t.copyWith(isActive: false);
    }).toList();
    
    state = state.copyWith(
      targets: updatedTargets,
      activeTargetIndex: targetIndex,
    );
    
    // Send BLE command
    bleService.activateTarget(targetIndex, color);
    audioService.play(GameSound.targetActivate);
    
    _targetActivatedAt = DateTime.now();
    
    // Set timeout for survival mode
    if (state.mode.type == GameModeType.survival) {
      _startTargetTimeout();
    }
  }

  void _activateMultipleTargetsForColorHunt(Color requiredColor) {
    final colors = [
      AppColors.targetRed,
      AppColors.targetGreen,
      AppColors.targetBlue,
      AppColors.targetYellow,
    ]..shuffle(_random);
    
    // Ensure required color is included
    if (!colors.take(state.targets.length).contains(requiredColor)) {
      colors[0] = requiredColor;
      colors.shuffle(_random);
    }
    
    final updatedTargets = state.targets.asMap().entries.map((entry) {
      final index = entry.key;
      final color = colors[index % colors.length];
      return entry.value.copyWith(
        isActive: true,
        color: color,
        activatedAt: DateTime.now(),
      );
    }).toList();
    
    state = state.copyWith(
      targets: updatedTargets,
      activeTargetIndex: null, // Multiple active
    );
    
    // Activate all targets with their colors
    for (var i = 0; i < updatedTargets.length; i++) {
      bleService.activateTarget(i, updatedTargets[i].color);
    }
    
    audioService.play(GameSound.targetActivate);
    _targetActivatedAt = DateTime.now();
  }

  int _getRandomTargetIndex() {
    if (state.targets.length <= 1) return 0;
    
    int newIndex;
    do {
      newIndex = _random.nextInt(state.targets.length);
    } while (newIndex == state.activeTargetIndex);
    
    return newIndex;
  }

  Color _getTargetColor(GameMode mode) {
    if (mode.customConfig['colors'] != null) {
      final colorNames = mode.customConfig['colors'] as List;
      final colorName = colorNames[_random.nextInt(colorNames.length)];
      return _colorFromName(colorName);
    }
    return AppColors.primary;
  }

  Color _colorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return AppColors.targetRed;
      case 'green':
        return AppColors.targetGreen;
      case 'blue':
        return AppColors.targetBlue;
      case 'yellow':
        return AppColors.targetYellow;
      default:
        return AppColors.primary;
    }
  }

  void _startTargetTimeout() {
    _targetTimer?.cancel();
    
    final interval = _getCurrentInterval();
    _targetTimer = Timer(Duration(milliseconds: interval + 500), () {
      if (state.status == GameStatus.playing) {
        _onMiss();
      }
    });
  }

  int _getCurrentInterval() {
    final mode = state.mode;
    var interval = mode.getTargetIntervalMs(state.difficulty);
    
    // For rapid fire, decrease interval over time
    if (mode.id == 'rapid_fire') {
      final speedRate = mode.customConfig['speedIncreaseRate'] as double? ?? 0.95;
      final minInterval = mode.customConfig['minIntervalMs'] as int? ?? 500;
      
      for (var i = 0; i < state.hits; i++) {
        interval = (interval * speedRate).round();
      }
      interval = interval.clamp(minInterval, 5000);
    }
    
    return interval;
  }

  // ============================================================
  // HIT HANDLING
  // ============================================================

  void _onHitReceived(String deviceId, int targetIndex) {
    if (state.status != GameStatus.playing) return;
    
    final target = state.targets.firstWhere(
      (t) => t.index == targetIndex,
      orElse: () => state.targets.first,
    );
    
    // For color hunt, check if correct color
    if (state.mode.id == 'color_hunt' && state.requiredColor != null) {
      if (target.color != state.requiredColor) {
        _onWrongColorHit(targetIndex);
        return;
      }
    }
    
    // Check if this was the active target (or any active in multi-target modes)
    if (!target.isActive) {
      _onMiss();
      return;
    }
    
    _registerHit(targetIndex);
  }

  /// Manually trigger a hit (for simulation/testing)
  void simulateHit(int targetIndex) {
    _onHitReceived('simulation', targetIndex);
  }

  void _registerHit(int targetIndex) {
    final reactionTime = _targetActivatedAt != null
        ? DateTime.now().difference(_targetActivatedAt!).inMilliseconds
        : 0;
    
    // Calculate points
    var points = 1;
    
    // Combo bonus
    if (state.mode.customConfig['streakMultiplier'] == true) {
      points += (state.combo ~/ 5);
    }
    
    final newCombo = state.combo + 1;
    final newBestCombo = newCombo > state.bestCombo ? newCombo : state.bestCombo;
    
    // Create hit event
    final hitEvent = HitEvent(
      targetIndex: targetIndex,
      timestamp: DateTime.now(),
      reactionTimeMs: reactionTime,
      pointsEarned: points,
    );
    
    state = state.copyWith(
      score: state.score + points,
      hits: state.hits + 1,
      combo: newCombo,
      bestCombo: newBestCombo,
      hitHistory: [...state.hitHistory, hitEvent],
    );
    
    audioService.play(GameSound.hit);
    
    // Play streak sound every 5 hits
    if (newCombo > 0 && newCombo % 5 == 0) {
      audioService.play(GameSound.streak);
    }
    
    // Deactivate target
    _deactivateTarget(targetIndex);
    
    // Check win conditions
    if (_checkGameComplete()) {
      _endGame();
      return;
    }
    
    // Schedule next target
    _scheduleNextTarget();
  }

  void _onWrongColorHit(int targetIndex) {
    final penalty = state.mode.customConfig['wrongHitPenalty'] as int? ?? -1;
    
    state = state.copyWith(
      score: state.score + penalty,
      misses: state.misses + 1,
      combo: 0,
    );
    
    audioService.play(GameSound.miss);
    
    // Flash the target red to indicate wrong
    bleService.flashTarget(
      bleService.state.connectedDevices[targetIndex].id,
      AppColors.colorToRgb(Colors.red),
    );
    
    _scheduleNextTarget();
  }

  void _onMiss() {
    state = state.copyWith(
      misses: state.misses + 1,
      combo: 0,
    );
    
    audioService.play(GameSound.miss);
    
    // Check game over for survival mode
    if (state.mode.type == GameModeType.survival) {
      final maxMisses = state.mode.customConfig['maxMisses'] as int? ?? 3;
      if (state.misses >= maxMisses) {
        _endGame();
        return;
      }
    }
    
    // Deactivate all and get new target
    _deactivateAllTargets();
    _scheduleNextTarget();
  }

  void _deactivateTarget(int targetIndex) {
    final updatedTargets = state.targets.map((t) {
      if (t.index == targetIndex) {
        return t.copyWith(isActive: false, color: AppColors.targetOff);
      }
      return t;
    }).toList();
    
    state = state.copyWith(
      targets: updatedTargets,
      activeTargetIndex: null,
    );
    
    bleService.deactivateTarget(targetIndex);
  }

  void _deactivateAllTargets() {
    final updatedTargets = state.targets.map((t) {
      return t.copyWith(isActive: false, color: AppColors.targetOff);
    }).toList();
    
    state = state.copyWith(
      targets: updatedTargets,
      activeTargetIndex: null,
    );
    
    bleService.allTargetsOff();
  }

  void _scheduleNextTarget() {
    _targetTimer?.cancel();
    
    // Small delay before next target
    final delay = state.mode.type == GameModeType.survival
        ? _getCurrentInterval() ~/ 4
        : 200;
    
    _targetTimer = Timer(Duration(milliseconds: delay), () {
      if (state.status == GameStatus.playing) {
        _activateNextTarget();
      }
    });
  }

  bool _checkGameComplete() {
    final mode = state.mode;
    
    switch (mode.type) {
      case GameModeType.targetBased:
        return state.hits >= mode.targetHits;
      case GameModeType.timed:
        return state.remainingMs <= 0;
      case GameModeType.survival:
        final maxMisses = mode.customConfig['maxMisses'] as int? ?? 3;
        return state.misses >= maxMisses;
      case GameModeType.practice:
        return false; // Never ends automatically
    }
  }

  // ============================================================
  // STATS & PERSISTENCE
  // ============================================================

  void _saveGameResult() {
    final result = GameResult.fromGameState(state);
    
    // Check for new high score
    final isHighScore = storageService.isNewHighScore(state.mode.id, state.score);
    if (isHighScore && state.score > 0) {
      audioService.play(GameSound.newHighScore);
      state = state.copyWith(message: 'NEW HIGH SCORE!');
    }
    
    storageService.saveHighScore(result);
    storageService.updatePlayerStats(result);
  }

  // ============================================================
  // PRACTICE MODE
  // ============================================================

  /// Manually activate a target in practice mode
  void manualActivateTarget(int targetIndex, Color color) {
    if (state.mode.id != 'practice') return;
    
    _activateSingleTarget(targetIndex, color);
  }

  /// Toggle target in practice mode
  void toggleTarget(int targetIndex) {
    if (state.mode.id != 'practice') return;
    
    final target = state.targets[targetIndex];
    if (target.isActive) {
      _deactivateTarget(targetIndex);
    } else {
      _activateSingleTarget(targetIndex, AppColors.getTargetColor(targetIndex));
    }
  }

  // ============================================================
  // DIFFICULTY
  // ============================================================

  /// Change difficulty
  void setDifficulty(GameDifficulty difficulty) {
    if (state.status == GameStatus.playing) return;
    
    state = state.copyWith(difficulty: difficulty);
    storageService.setLastDifficulty(difficulty);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _targetTimer?.cancel();
    bleService.onHitReceived = null;
    super.dispose();
  }
}

/// Provider for game controller
final gameControllerProvider = StateNotifierProvider.autoDispose
    .family<GameController, GameState, GameMode>((ref, mode) {
  final bleService = ref.watch(bleServiceProvider.notifier);
  final audioService = ref.watch(audioServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final targetCount = ref.watch(connectedDeviceCountProvider);
  final lastDifficulty = storageService.lastDifficulty;
  
  return GameController(
    bleService: bleService,
    audioService: audioService,
    storageService: storageService,
    initialMode: mode,
    targetCount: targetCount > 0 ? targetCount : 4, // Use 4 for simulation
    difficulty: lastDifficulty,
  );
});

/// Provider for current game status
final gameStatusProvider = Provider.family<GameStatus, GameMode>((ref, mode) {
  return ref.watch(gameControllerProvider(mode)).status;
});
