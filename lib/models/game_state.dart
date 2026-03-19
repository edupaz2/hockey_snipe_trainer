import 'package:flutter/material.dart';
import 'game_mode.dart';

/// Current state of a game session
enum GameStatus {
  idle,
  countdown,
  playing,
  paused,
  finished,
}

/// Represents a target's state during gameplay
class TargetState {
  final int index;
  final bool isActive;
  final Color color;
  final DateTime? activatedAt;
  
  const TargetState({
    required this.index,
    this.isActive = false,
    this.color = Colors.grey,
    this.activatedAt,
  });
  
  TargetState copyWith({
    int? index,
    bool? isActive,
    Color? color,
    DateTime? activatedAt,
  }) {
    return TargetState(
      index: index ?? this.index,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      activatedAt: activatedAt ?? this.activatedAt,
    );
  }
}

/// Represents a single hit event
class HitEvent {
  final int targetIndex;
  final DateTime timestamp;
  final int reactionTimeMs;
  final bool wasCorrect; // For color matching games
  final int pointsEarned;
  
  const HitEvent({
    required this.targetIndex,
    required this.timestamp,
    required this.reactionTimeMs,
    this.wasCorrect = true,
    this.pointsEarned = 1,
  });
}

/// Complete game state during a session
class GameState {
  final GameMode mode;
  final GameDifficulty difficulty;
  final GameStatus status;
  final int score;
  final int hits;
  final int misses;
  final int combo;
  final int bestCombo;
  final int elapsedMs;
  final int remainingMs;
  final List<TargetState> targets;
  final List<HitEvent> hitHistory;
  final Color? requiredColor; // For color-matching games
  final int currentRound;
  final int totalRounds;
  final String? message;
  final int? activeTargetIndex;
  
  // Multiplayer
  final int player1Score;
  final int player2Score;
  
  const GameState({
    required this.mode,
    this.difficulty = GameDifficulty.medium,
    this.status = GameStatus.idle,
    this.score = 0,
    this.hits = 0,
    this.misses = 0,
    this.combo = 0,
    this.bestCombo = 0,
    this.elapsedMs = 0,
    this.remainingMs = 0,
    this.targets = const [],
    this.hitHistory = const [],
    this.requiredColor,
    this.currentRound = 0,
    this.totalRounds = 1,
    this.message,
    this.activeTargetIndex,
    this.player1Score = 0,
    this.player2Score = 0,
  });
  
  /// Create initial state for a game mode
  factory GameState.initial(GameMode mode, int targetCount, GameDifficulty difficulty) {
    return GameState(
      mode: mode,
      difficulty: difficulty,
      remainingMs: mode.type == GameModeType.timed 
          ? mode.getDurationForDifficulty(difficulty) * 1000 
          : 0,
      targets: List.generate(
        targetCount, 
        (i) => TargetState(index: i),
      ),
      totalRounds: mode.customConfig['rounds'] as int? ?? 1,
    );
  }
  
  /// Calculated properties
  double get accuracy => hits + misses > 0 
      ? (hits / (hits + misses)) * 100 
      : 0;
      
  int get averageReactionTimeMs {
    if (hitHistory.isEmpty) return 0;
    final total = hitHistory.fold<int>(
      0, 
      (sum, hit) => sum + hit.reactionTimeMs,
    );
    return total ~/ hitHistory.length;
  }
  
  int get bestReactionTimeMs {
    if (hitHistory.isEmpty) return 0;
    return hitHistory
        .map((h) => h.reactionTimeMs)
        .reduce((a, b) => a < b ? a : b);
  }
  
  bool get isPlaying => status == GameStatus.playing;
  bool get isPaused => status == GameStatus.paused;
  bool get isFinished => status == GameStatus.finished;
  
  String get formattedTime {
    final ms = mode.type == GameModeType.timed ? remainingMs : elapsedMs;
    final seconds = (ms / 1000).floor();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final millis = (ms % 1000) ~/ 10;
    
    if (minutes > 0) {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
    return '$secs.${millis.toString().padLeft(2, '0')}';
  }
  
  GameState copyWith({
    GameMode? mode,
    GameDifficulty? difficulty,
    GameStatus? status,
    int? score,
    int? hits,
    int? misses,
    int? combo,
    int? bestCombo,
    int? elapsedMs,
    int? remainingMs,
    List<TargetState>? targets,
    List<HitEvent>? hitHistory,
    Color? requiredColor,
    int? currentRound,
    int? totalRounds,
    String? message,
    int? activeTargetIndex,
    int? player1Score,
    int? player2Score,
  }) {
    return GameState(
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      score: score ?? this.score,
      hits: hits ?? this.hits,
      misses: misses ?? this.misses,
      combo: combo ?? this.combo,
      bestCombo: bestCombo ?? this.bestCombo,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      remainingMs: remainingMs ?? this.remainingMs,
      targets: targets ?? this.targets,
      hitHistory: hitHistory ?? this.hitHistory,
      requiredColor: requiredColor ?? this.requiredColor,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      message: message ?? this.message,
      activeTargetIndex: activeTargetIndex ?? this.activeTargetIndex,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
    );
  }
}

/// Result of a completed game
class GameResult {
  final String modeId;
  final int score;
  final int hits;
  final int misses;
  final double accuracy;
  final int durationMs;
  final int bestCombo;
  final int averageReactionTimeMs;
  final int bestReactionTimeMs;
  final GameDifficulty difficulty;
  final DateTime playedAt;
  
  const GameResult({
    required this.modeId,
    required this.score,
    required this.hits,
    required this.misses,
    required this.accuracy,
    required this.durationMs,
    required this.bestCombo,
    required this.averageReactionTimeMs,
    required this.bestReactionTimeMs,
    required this.difficulty,
    required this.playedAt,
  });
  
  factory GameResult.fromGameState(GameState state) {
    return GameResult(
      modeId: state.mode.id,
      score: state.score,
      hits: state.hits,
      misses: state.misses,
      accuracy: state.accuracy,
      durationMs: state.elapsedMs,
      bestCombo: state.bestCombo,
      averageReactionTimeMs: state.averageReactionTimeMs,
      bestReactionTimeMs: state.bestReactionTimeMs,
      difficulty: state.difficulty,
      playedAt: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'modeId': modeId,
    'score': score,
    'hits': hits,
    'misses': misses,
    'accuracy': accuracy,
    'durationMs': durationMs,
    'bestCombo': bestCombo,
    'averageReactionTimeMs': averageReactionTimeMs,
    'bestReactionTimeMs': bestReactionTimeMs,
    'difficulty': difficulty.index,
    'playedAt': playedAt.toIso8601String(),
  };
  
  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      modeId: json['modeId'] as String,
      score: json['score'] as int,
      hits: json['hits'] as int,
      misses: json['misses'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      durationMs: json['durationMs'] as int,
      bestCombo: json['bestCombo'] as int,
      averageReactionTimeMs: json['averageReactionTimeMs'] as int,
      bestReactionTimeMs: json['bestReactionTimeMs'] as int,
      difficulty: GameDifficulty.values[json['difficulty'] as int],
      playedAt: DateTime.parse(json['playedAt'] as String),
    );
  }
}
