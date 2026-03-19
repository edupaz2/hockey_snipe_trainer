import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sounds available in the app
enum GameSound {
  hit,
  miss,
  countdown,
  gameStart,
  gameEnd,
  buttonClick,
  targetActivate,
  streak,
  newHighScore,
  error,
}

/// Audio service for game sounds
class AudioService {
  AudioService();
  
  final Map<GameSound, AudioPlayer> _players = {};
  bool _soundEnabled = true;
  double _volume = 0.7;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  /// Initialize audio players
  Future<void> initialize() async {
    // Pre-create players for low-latency playback
    for (final sound in GameSound.values) {
      _players[sound] = AudioPlayer();
      _players[sound]!.setReleaseMode(ReleaseMode.stop);
    }
  }

  /// Play a sound effect
  Future<void> play(GameSound sound) async {
    if (!_soundEnabled) return;
    
    final player = _players[sound];
    if (player == null) return;
    
    try {
      // Stop any currently playing sound on this player
      await player.stop();
      
      // Set source and play
      await player.setVolume(_volume);
      await player.setSource(_getAssetSource(sound));
      await player.resume();
    } catch (e) {
      // Silently fail - sounds are nice but not critical
    }
  }

  AssetSource _getAssetSource(GameSound sound) {
    switch (sound) {
      case GameSound.hit:
        return AssetSource('sounds/hit.mp3');
      case GameSound.miss:
        return AssetSource('sounds/miss.mp3');
      case GameSound.countdown:
        return AssetSource('sounds/countdown.mp3');
      case GameSound.gameStart:
        return AssetSource('sounds/game_start.mp3');
      case GameSound.gameEnd:
        return AssetSource('sounds/game_end.mp3');
      case GameSound.buttonClick:
        return AssetSource('sounds/click.mp3');
      case GameSound.targetActivate:
        return AssetSource('sounds/target_on.mp3');
      case GameSound.streak:
        return AssetSource('sounds/streak.mp3');
      case GameSound.newHighScore:
        return AssetSource('sounds/high_score.mp3');
      case GameSound.error:
        return AssetSource('sounds/error.mp3');
    }
  }

  /// Enable/disable sounds
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      stopAll();
    }
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    for (final player in _players.values) {
      player.setVolume(_volume);
    }
  }

  /// Stop all currently playing sounds
  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.stop();
    }
  }

  /// Dispose all players
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}

/// Provider for audio service
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for sound enabled state
final soundEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for volume
final volumeProvider = StateProvider<double>((ref) => 0.7);
