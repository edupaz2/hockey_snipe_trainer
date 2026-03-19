import 'package:hive/hive.dart';
import 'game_state.dart';
import 'game_mode.dart';

part 'player_stats.g.dart';

/// High score entry for a game mode
@HiveType(typeId: 0)
class HighScore extends HiveObject {
  @HiveField(0)
  final String modeId;
  
  @HiveField(1)
  final int score;
  
  @HiveField(2)
  final int hits;
  
  @HiveField(3)
  final double accuracy;
  
  @HiveField(4)
  final int durationMs;
  
  @HiveField(5)
  final int difficultyIndex;
  
  @HiveField(6)
  final String playedAt;

  HighScore({
    required this.modeId,
    required this.score,
    required this.hits,
    required this.accuracy,
    required this.durationMs,
    required this.difficultyIndex,
    required this.playedAt,
  });

  DateTime get playedAtDateTime => DateTime.parse(playedAt);
  GameDifficulty get difficulty => GameDifficulty.values[difficultyIndex];

  factory HighScore.fromGameResult(GameResult result) {
    return HighScore(
      modeId: result.modeId,
      score: result.score,
      hits: result.hits,
      accuracy: result.accuracy,
      durationMs: result.durationMs,
      difficultyIndex: result.difficulty.index,
      playedAt: result.playedAt.toIso8601String(),
    );
  }
}

/// Overall player statistics
@HiveType(typeId: 1)
class PlayerStats extends HiveObject {
  @HiveField(0)
  int totalShots;
  
  @HiveField(1)
  int totalHits;
  
  @HiveField(2)
  int totalMisses;
  
  @HiveField(3)
  int totalGamesPlayed;
  
  @HiveField(4)
  int totalPlayTimeMs;
  
  @HiveField(5)
  int bestOverallStreak;
  
  @HiveField(6)
  int bestReactionTimeMs;
  
  @HiveField(7)
  String? firstPlayedAt;
  
  @HiveField(8)
  String? lastPlayedAt;

  PlayerStats({
    this.totalShots = 0,
    this.totalHits = 0,
    this.totalMisses = 0,
    this.totalGamesPlayed = 0,
    this.totalPlayTimeMs = 0,
    this.bestOverallStreak = 0,
    this.bestReactionTimeMs = 0,
    this.firstPlayedAt,
    this.lastPlayedAt,
  });

  /// Overall accuracy percentage
  double get accuracy => totalShots > 0 
      ? (totalHits / totalShots) * 100 
      : 0;

  /// Average play time per game in minutes
  double get avgPlayTimeMinutes => totalGamesPlayed > 0 
      ? (totalPlayTimeMs / totalGamesPlayed) / 60000 
      : 0;

  /// Total play time formatted as "Xh Ym"
  String get formattedTotalPlayTime {
    final totalMinutes = totalPlayTimeMs ~/ 60000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Update stats after a game
  void updateFromGameResult(GameResult result) {
    totalShots += result.hits + result.misses;
    totalHits += result.hits;
    totalMisses += result.misses;
    totalGamesPlayed++;
    totalPlayTimeMs += result.durationMs;
    
    if (result.bestCombo > bestOverallStreak) {
      bestOverallStreak = result.bestCombo;
    }
    
    if (result.bestReactionTimeMs > 0 && 
        (bestReactionTimeMs == 0 || result.bestReactionTimeMs < bestReactionTimeMs)) {
      bestReactionTimeMs = result.bestReactionTimeMs;
    }
    
    firstPlayedAt ??= result.playedAt.toIso8601String();
    lastPlayedAt = result.playedAt.toIso8601String();
    
    save();
  }
}

/// Statistics per game mode
class ModeStats {
  final String modeId;
  final int gamesPlayed;
  final int bestScore;
  final int totalHits;
  final double bestAccuracy;
  final int bestTimeMs; // For time-based modes (fastest completion)
  final List<HighScore> recentScores;
  
  const ModeStats({
    required this.modeId,
    this.gamesPlayed = 0,
    this.bestScore = 0,
    this.totalHits = 0,
    this.bestAccuracy = 0,
    this.bestTimeMs = 0,
    this.recentScores = const [],
  });
  
  GameMode? get mode => GameModes.getById(modeId);
  
  ModeStats copyWith({
    String? modeId,
    int? gamesPlayed,
    int? bestScore,
    int? totalHits,
    double? bestAccuracy,
    int? bestTimeMs,
    List<HighScore>? recentScores,
  }) {
    return ModeStats(
      modeId: modeId ?? this.modeId,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      bestScore: bestScore ?? this.bestScore,
      totalHits: totalHits ?? this.totalHits,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
      recentScores: recentScores ?? this.recentScores,
    );
  }
}
