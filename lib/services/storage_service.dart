import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/player_stats.dart';
import '../models/game_state.dart';
import '../models/game_mode.dart';

/// Storage service for persisting game data
class StorageService {
  static const String _highScoresBoxName = 'high_scores';
  static const String _playerStatsBoxName = 'player_stats';
  static const String _settingsBoxName = 'settings';
  
  late Box<HighScore> _highScoresBox;
  late Box<PlayerStats> _playerStatsBox;
  late Box<dynamic> _settingsBox;
  
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HighScoreAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PlayerStatsAdapter());
    }
    
    // Open boxes
    _highScoresBox = await Hive.openBox<HighScore>(_highScoresBoxName);
    _playerStatsBox = await Hive.openBox<PlayerStats>(_playerStatsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    
    // Initialize player stats if not exists
    if (_playerStatsBox.isEmpty) {
      await _playerStatsBox.put('stats', PlayerStats());
    }
    
    _initialized = true;
  }

  // ============================================================
  // HIGH SCORES
  // ============================================================

  /// Get all high scores for a game mode
  List<HighScore> getHighScores(String modeId, {int limit = 10}) {
    final scores = _highScoresBox.values
        .where((score) => score.modeId == modeId)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    
    return scores.take(limit).toList();
  }

  /// Get best high score for a mode
  HighScore? getBestScore(String modeId) {
    final scores = getHighScores(modeId, limit: 1);
    return scores.isEmpty ? null : scores.first;
  }

  /// Check if score is a new high score
  bool isNewHighScore(String modeId, int score) {
    final best = getBestScore(modeId);
    return best == null || score > best.score;
  }

  /// Save a new high score
  Future<void> saveHighScore(GameResult result) async {
    final highScore = HighScore.fromGameResult(result);
    await _highScoresBox.add(highScore);
    
    // Keep only top 50 scores per mode
    await _pruneHighScores(result.modeId, 50);
  }

  Future<void> _pruneHighScores(String modeId, int maxCount) async {
    final allScores = _highScoresBox.values
        .where((score) => score.modeId == modeId)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    
    if (allScores.length > maxCount) {
      final toDelete = allScores.skip(maxCount).toList();
      for (final score in toDelete) {
        await score.delete();
      }
    }
  }

  /// Get all high scores grouped by mode
  Map<String, List<HighScore>> getAllHighScoresByMode() {
    final result = <String, List<HighScore>>{};
    
    for (final mode in GameModes.all) {
      final scores = getHighScores(mode.id);
      if (scores.isNotEmpty) {
        result[mode.id] = scores;
      }
    }
    
    return result;
  }

  // ============================================================
  // PLAYER STATS
  // ============================================================

  /// Get player stats
  PlayerStats getPlayerStats() {
    return _playerStatsBox.get('stats') ?? PlayerStats();
  }

  /// Update player stats after a game
  Future<void> updatePlayerStats(GameResult result) async {
    final stats = getPlayerStats();
    stats.updateFromGameResult(result);
    await _playerStatsBox.put('stats', stats);
  }

  /// Get mode-specific stats
  ModeStats getModeStats(String modeId) {
    final highScores = getHighScores(modeId);
    
    if (highScores.isEmpty) {
      return ModeStats(modeId: modeId);
    }
    
    final best = highScores.first;
    final totalHits = highScores.fold<int>(0, (sum, s) => sum + s.hits);
    final bestAccuracy = highScores
        .map((s) => s.accuracy)
        .fold<double>(0, (max, acc) => acc > max ? acc : max);
    
    return ModeStats(
      modeId: modeId,
      gamesPlayed: highScores.length,
      bestScore: best.score,
      totalHits: totalHits,
      bestAccuracy: bestAccuracy,
      bestTimeMs: best.durationMs,
      recentScores: highScores.take(5).toList(),
    );
  }

  /// Reset all stats
  Future<void> resetAllStats() async {
    await _highScoresBox.clear();
    await _playerStatsBox.put('stats', PlayerStats());
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  /// Get a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Set a setting value
  Future<void> setSetting<T>(String key, T value) async {
    await _settingsBox.put(key, value);
  }

  /// Sound enabled setting
  bool get soundEnabled => getSetting<bool>('soundEnabled', defaultValue: true) ?? true;
  Future<void> setSoundEnabled(bool enabled) => setSetting('soundEnabled', enabled);

  /// Volume setting
  double get volume => getSetting<double>('volume', defaultValue: 0.7) ?? 0.7;
  Future<void> setVolume(double volume) => setSetting('volume', volume);

  /// Haptic feedback setting
  bool get hapticEnabled => getSetting<bool>('hapticEnabled', defaultValue: true) ?? true;
  Future<void> setHapticEnabled(bool enabled) => setSetting('hapticEnabled', enabled);

  /// Dark mode (always dark for this app, but could be extended)
  bool get darkMode => true;

  /// Simulation mode (for testing without physical targets)
  bool get simulationMode => getSetting<bool>('simulationMode', defaultValue: false) ?? false;
  Future<void> setSimulationMode(bool enabled) => setSetting('simulationMode', enabled);

  /// Last used difficulty
  int get lastDifficultyIndex => getSetting<int>('lastDifficulty', defaultValue: 1) ?? 1;
  Future<void> setLastDifficulty(GameDifficulty difficulty) => 
      setSetting('lastDifficulty', difficulty.index);
  GameDifficulty get lastDifficulty => GameDifficulty.values[lastDifficultyIndex];

  /// Dispose
  Future<void> dispose() async {
    await Hive.close();
  }
}

/// Provider for storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for player stats
final playerStatsProvider = Provider<PlayerStats>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getPlayerStats();
});

/// Provider for high scores of a specific mode
final highScoresProvider = Provider.family<List<HighScore>, String>((ref, modeId) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getHighScores(modeId);
});

/// Provider for mode stats
final modeStatsProvider = Provider.family<ModeStats, String>((ref, modeId) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getModeStats(modeId);
});

/// Provider for simulation mode
final simulationModeProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.simulationMode;
});
