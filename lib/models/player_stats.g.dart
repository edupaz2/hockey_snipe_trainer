// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HighScoreAdapter extends TypeAdapter<HighScore> {
  @override
  final int typeId = 0;

  @override
  HighScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HighScore(
      modeId: fields[0] as String,
      score: fields[1] as int,
      hits: fields[2] as int,
      accuracy: fields[3] as double,
      durationMs: fields[4] as int,
      difficultyIndex: fields[5] as int,
      playedAt: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HighScore obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.modeId)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.hits)
      ..writeByte(3)
      ..write(obj.accuracy)
      ..writeByte(4)
      ..write(obj.durationMs)
      ..writeByte(5)
      ..write(obj.difficultyIndex)
      ..writeByte(6)
      ..write(obj.playedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlayerStatsAdapter extends TypeAdapter<PlayerStats> {
  @override
  final int typeId = 1;

  @override
  PlayerStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerStats(
      totalShots: fields[0] as int,
      totalHits: fields[1] as int,
      totalMisses: fields[2] as int,
      totalGamesPlayed: fields[3] as int,
      totalPlayTimeMs: fields[4] as int,
      bestOverallStreak: fields[5] as int,
      bestReactionTimeMs: fields[6] as int,
      firstPlayedAt: fields[7] as String?,
      lastPlayedAt: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStats obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.totalShots)
      ..writeByte(1)
      ..write(obj.totalHits)
      ..writeByte(2)
      ..write(obj.totalMisses)
      ..writeByte(3)
      ..write(obj.totalGamesPlayed)
      ..writeByte(4)
      ..write(obj.totalPlayTimeMs)
      ..writeByte(5)
      ..write(obj.bestOverallStreak)
      ..writeByte(6)
      ..write(obj.bestReactionTimeMs)
      ..writeByte(7)
      ..write(obj.firstPlayedAt)
      ..writeByte(8)
      ..write(obj.lastPlayedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
