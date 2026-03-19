import 'package:flutter/material.dart';

/// Type of game mode
enum GameModeType {
  timed,      // Game ends after time limit
  targetBased, // Game ends after hitting target count
  survival,   // Game ends when player misses
  practice,   // No end condition, free play
}

/// Difficulty level affecting game parameters
enum GameDifficulty {
  easy,
  medium,
  hard,
  expert,
}

/// Represents a game mode with all its configuration
class GameMode {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final GameModeType type;
  final GameDifficulty defaultDifficulty;
  final int durationSeconds;
  final int targetHits;
  final int minTargets; // Minimum targets required to play
  final bool supportsMultiplayer;
  final List<String> features;
  final Map<String, dynamic> customConfig;

  const GameMode({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    this.defaultDifficulty = GameDifficulty.medium,
    this.durationSeconds = 30,
    this.targetHits = 10,
    this.minTargets = 1,
    this.supportsMultiplayer = false,
    this.features = const [],
    this.customConfig = const {},
  });

  /// Get duration based on difficulty
  int getDurationForDifficulty(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return (durationSeconds * 1.5).round();
      case GameDifficulty.medium:
        return durationSeconds;
      case GameDifficulty.hard:
        return (durationSeconds * 0.75).round();
      case GameDifficulty.expert:
        return (durationSeconds * 0.5).round();
    }
  }

  /// Get target interval (ms between target activations) based on difficulty
  int getTargetIntervalMs(GameDifficulty difficulty) {
    final baseInterval = customConfig['baseIntervalMs'] as int? ?? 2000;
    switch (difficulty) {
      case GameDifficulty.easy:
        return (baseInterval * 1.5).round();
      case GameDifficulty.medium:
        return baseInterval;
      case GameDifficulty.hard:
        return (baseInterval * 0.7).round();
      case GameDifficulty.expert:
        return (baseInterval * 0.5).round();
    }
  }

  @override
  String toString() => 'GameMode($name)';
}

/// Predefined game modes
class GameModes {
  GameModes._();

  static const randomSnipe30 = GameMode(
    id: 'random_snipe_30',
    name: 'Random Snipe',
    description: 'Hit as many random targets as possible in 30 seconds. '
        'Targets light up one at a time.',
    icon: Icons.shuffle,
    color: Color(0xFF00E5FF),
    type: GameModeType.timed,
    durationSeconds: 30,
    minTargets: 2,
    features: ['Random targets', 'Score tracking', 'Speed bonus'],
    customConfig: {'baseIntervalMs': 1500},
  );

  static const timeTo10 = GameMode(
    id: 'time_to_10',
    name: 'Time to 10',
    description: 'Race to hit 10 targets as fast as possible. '
        'Clock starts when first target lights up.',
    icon: Icons.timer,
    color: Color(0xFFFF9100),
    type: GameModeType.targetBased,
    targetHits: 10,
    minTargets: 2,
    features: ['Speed challenge', 'Personal best tracking'],
    customConfig: {'baseIntervalMs': 1000},
  );

  static const reactionTime = GameMode(
    id: 'reaction_time',
    name: 'Reaction Time',
    description: 'Test your reflexes! A single target lights up after '
        'a random delay. Hit it as fast as you can.',
    icon: Icons.flash_on,
    color: Color(0xFFFFEA00),
    type: GameModeType.practice,
    minTargets: 1,
    features: ['Reaction measurement', 'Average tracking', 'Best time'],
    customConfig: {
      'minDelayMs': 1000,
      'maxDelayMs': 5000,
      'rounds': 5,
    },
  );

  static const marksman = GameMode(
    id: 'marksman',
    name: 'Marksman',
    description: 'One target stays lit. Hit it 10 times in a row as fast '
        'as possible. Perfect your aim!',
    icon: Icons.gps_fixed,
    color: Color(0xFFFF1744),
    type: GameModeType.targetBased,
    targetHits: 10,
    minTargets: 1,
    features: ['Single target focus', 'Accuracy training'],
    customConfig: {'singleTarget': true},
  );

  static const colorHunt = GameMode(
    id: 'color_hunt',
    name: 'Color Hunt',
    description: 'Multiple targets with different colors. Hit only the '
        'target matching the displayed color!',
    icon: Icons.palette,
    color: Color(0xFF00E676),
    type: GameModeType.timed,
    durationSeconds: 45,
    minTargets: 3,
    features: ['Color matching', 'Penalty for wrong hits'],
    customConfig: {
      'baseIntervalMs': 2000,
      'colors': ['red', 'green', 'blue', 'yellow'],
      'wrongHitPenalty': -2,
    },
  );

  static const rapidFire = GameMode(
    id: 'rapid_fire',
    name: 'Rapid Fire',
    description: 'Targets light up faster and faster! How long can you '
        'keep up before missing?',
    icon: Icons.local_fire_department,
    color: Color(0xFFFF5722),
    type: GameModeType.survival,
    minTargets: 2,
    features: ['Increasing speed', 'Survival mode', 'Miss = Game Over'],
    customConfig: {
      'startIntervalMs': 2000,
      'minIntervalMs': 500,
      'speedIncreaseRate': 0.95,
      'maxMisses': 3,
    },
  );

  static const snipeStreak = GameMode(
    id: 'snipe_streak',
    name: 'Snipe Streak',
    description: 'Build the longest hit streak! Missing resets your streak. '
        'Bonus points for consecutive hits.',
    icon: Icons.trending_up,
    color: Color(0xFF9C27B0),
    type: GameModeType.timed,
    durationSeconds: 60,
    minTargets: 2,
    features: ['Streak multiplier', 'Combo bonus'],
    customConfig: {
      'baseIntervalMs': 1800,
      'streakMultiplier': true,
    },
  );

  static const fourCorners = GameMode(
    id: 'four_corners',
    name: 'Four Corners',
    description: 'Hit all 4 targets in sequence as fast as possible. '
        'Complete 5 rounds!',
    icon: Icons.grid_view,
    color: Color(0xFF2196F3),
    type: GameModeType.targetBased,
    targetHits: 20, // 4 targets x 5 rounds
    minTargets: 4,
    features: ['Pattern sequence', 'Full goal coverage'],
    customConfig: {
      'rounds': 5,
      'sequencePattern': true,
    },
  );

  static const lightningRound = GameMode(
    id: 'lightning_round',
    name: 'Lightning Round',
    description: 'Ultra-fast 15-second challenge! How many can you hit?',
    icon: Icons.bolt,
    color: Color(0xFFFFEB3B),
    type: GameModeType.timed,
    durationSeconds: 15,
    minTargets: 2,
    features: ['Short burst', 'High intensity'],
    customConfig: {'baseIntervalMs': 800},
  );

  static const endurance = GameMode(
    id: 'endurance',
    name: 'Endurance',
    description: '2-minute challenge! Pace yourself and maintain accuracy '
        'throughout.',
    icon: Icons.fitness_center,
    color: Color(0xFF607D8B),
    type: GameModeType.timed,
    durationSeconds: 120,
    minTargets: 2,
    features: ['Long duration', 'Stamina test'],
    customConfig: {'baseIntervalMs': 2000},
  );

  static const twoPlayer = GameMode(
    id: 'two_player',
    name: 'Two Player',
    description: 'Compete head-to-head! Each player gets 2 targets. '
        'First to 10 wins!',
    icon: Icons.people,
    color: Color(0xFFE91E63),
    type: GameModeType.targetBased,
    targetHits: 10,
    minTargets: 4,
    supportsMultiplayer: true,
    features: ['Multiplayer', 'Split targets'],
    customConfig: {
      'playersCount': 2,
      'targetsPerPlayer': 2,
    },
  );

  static const practice = GameMode(
    id: 'practice',
    name: 'Free Practice',
    description: 'No timer, no pressure. Light up any target manually '
        'and practice your shots.',
    icon: Icons.sports_hockey,
    color: Color(0xFF78909C),
    type: GameModeType.practice,
    minTargets: 1,
    features: ['Manual control', 'No scoring'],
    customConfig: {'freeMode': true},
  );

  /// All available game modes
  static const List<GameMode> all = [
    randomSnipe30,
    timeTo10,
    reactionTime,
    marksman,
    colorHunt,
    rapidFire,
    snipeStreak,
    fourCorners,
    lightningRound,
    endurance,
    twoPlayer,
    practice,
  ];

  /// Get mode by ID
  static GameMode? getById(String id) {
    try {
      return all.firstWhere((mode) => mode.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get modes that work with the given number of targets
  static List<GameMode> getAvailableModes(int connectedTargets) {
    return all.where((mode) => mode.minTargets <= connectedTargets).toList();
  }
}
