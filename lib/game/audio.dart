import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'save.dart';

/// Every sound the game can make. Names map 1:1 to WAV files the
/// `tool/generate_audio.dart` synthesizer produces.
enum Sfx { click, coin, star, honk, bounce, splash, boost, win, oops, screech }

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
  AudioPlayer? _enginePlayer;
  double _lastEngineRate = -1;
  Duration _engineThrottle = Duration.zero;
  String? _currentTrack;
  /// Last track any screen asked for — lets "Music back ON" resume
  /// exactly where the app is, without waiting for the next screen.
  String? _lastTrack;
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
      final e = AudioPlayer();
      unawaited(e.setReleaseMode(ReleaseMode.loop));
      unawaited(e.setVolume(0.0));
      _enginePlayer = e;
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
    _lastTrack = track;
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

  /// Called the instant a grown-up flips a settings toggle so the
  /// change is felt immediately — music dies right away, and turning
  /// it back on resumes the track for the current screen.
  void applySettings() {
    final save = _save;
    if (save == null) return;
    if (!save.musicOn) {
      stopMusic();
    } else if (_lastTrack != null && _currentTrack == null) {
      playMusic(_lastTrack!);
    }
  }

  void attachSave(GameSave save) => _save = save;

  // ---------------------------------------------------------------- engine

  /// The heart of the cockpit feel: a looping engine drone whose pitch
  /// and hustle track the real speed. Throttled so we don't spam the
  /// audio device every frame. [load] = 0 .. 1.35 (1.0 = cruise speed).
  void engine(double load) {
    final p = _enginePlayer;
    final save = _save;
    if (p == null) return;
    if (save != null && !save.sfxOn) {
      _lastEngineRate = -1;
      unawaited(p.setVolume(0.0));
      return;
    }
    final clamped = load.clamp(0.0, 1.35);
    try {
      final now = Duration(
          microseconds: (load * 1000).round()); // cheap clock for throttle
      final rate = 0.55 + clamped * 1.05;
      final vol = (0.10 + clamped * 0.20).clamp(0.0, 0.5);
      if (_lastEngineRate < 0) {
        unawaited(_playEngine(p));
        _lastEngineRate = rate;
      }
      if (now - _engineThrottle < const Duration(milliseconds: 1)) return;
      _engineThrottle = now;
      if ((rate - _lastEngineRate).abs() > 0.02) {
        _lastEngineRate = rate;
        unawaited(p.setPlaybackRate(rate));
      }
      unawaited(p.setVolume(vol));
    } catch (_) {}
  }

  Future<void> _playEngine(AudioPlayer p) async {
    try {
      await p.play(AssetSource('audio/engine_loop.wav'));
    } catch (_) {}
  }

  void engineStop() {
    _lastEngineRate = -1;
    try {
      unawaited(_enginePlayer?.setVolume(0.0));
      unawaited(_enginePlayer?.stop());
    } catch (_) {}
  }
}
