import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'save.dart';

/// Every sound the game can make. Names map 1:1 to WAV files the
/// `tool/generate_audio.dart` synthesizer produces.
enum Sfx { click, coin, star, honk, bounce, splash, boost, win, oops }

/// Central audio hub with a tiny round-robin SFX pool so overlapping
/// effects gently replace each other instead of stacking into noise.
/// Every call is failure-safe: a missing plugin or asset can never
/// crash gameplay.
class AudioHub {
  AudioHub._();

  static final AudioHub instance = AudioHub._();

  static const int poolSize = 5;
  final List<AudioPlayer> _pool = <AudioPlayer>[];
  int _cursor = 0;
  AudioPlayer? _musicPlayer;
  String? _currentTrack;
  GameSave? _save;
  bool _ready = false;

  /// Safe in tests and missing-assets environments.
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      for (var i = 0; i < poolSize; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(p);
      }
      final m = AudioPlayer();
      unawaited(m.setReleaseMode(ReleaseMode.loop));
      _musicPlayer = m;
    } catch (e) {
      debugPrint('AudioHub init skipped: $e');
    }
  }

  Future<void> _playAsset(AudioPlayer p, String asset, double volume) async {
    try {
      await p.play(AssetSource(asset), volume: volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('audio skipped ($asset): $e');
    }
  }

  void play(Sfx sfx, {double volume = 1}) {
    final save = _save;
    if (save != null && !save.sfxOn) return;
    if (_pool.isEmpty) return;
    var p = _pool[_cursor];
    _cursor = (_cursor + 1) % _pool.length;
    unawaited(_playAsset(p, 'audio/${sfx.name}.wav', volume));
  }

  void playMusic(String track) {
    final save = _save;
    final p = _musicPlayer;
    if (p == null) return;
    if (save != null && !save.musicOn) {
      stopMusic();
      return;
    }
    if (_currentTrack == track) return;
    _currentTrack = track;
    unawaited(p.setVolume(0.45));
    unawaited(_playAsset(p, 'audio/$track.wav', 0.45));
  }

  void stopMusic() {
    if (_currentTrack == null && _musicPlayer == null) return;
    _currentTrack = null;
    try {
      unawaited(_musicPlayer?.stop());
    } catch (_) {}
  }

  void attachSave(GameSave save) => _save = save;
}
