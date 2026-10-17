// Generates every sound in the game from pure math — no downloads, no
// licenses, no copyright risk. Run once:
//   dart run tool/generate_audio.dart
// Output: assets/audio/*.wav (mono PCM 16-bit, 44.1 kHz)
// ignore_for_file: avoid_print, unused_local_variable

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sr = 44100;
const String outDir = 'assets/audio';

// ------------------------------------------------------------------ waves

double sine(double t, double f) => math.sin(2 * math.pi * f * t);

double square(double t, double f) =>
    math.sin(2 * math.pi * f * t) >= 0 ? 0.6 : -0.6;

double triangle(double t, double f) {
  final p = (t * f) % 1.0;
  return p < 0.5 ? 4 * p - 1 : 1 - 4 * (p - 0.5);
}

int _seed = 12345;
double rand01() {
  _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
  return _seed / 0x7FFFFFFF;
}

double whiteNoise() => rand01() * 2 - 1;

// Moving-average low-pass (simple, fast, good enough for cute sounds).
List<double> lowpass(List<double> x, int w) {
  final out = List<double>.filled(x.length, 0);
  var acc = 0.0;
  for (var i = 0; i < x.length; i++) {
    acc += x[i];
    if (i >= w) acc -= x[i - w];
    out[i] = acc / (i < w ? i + 1 : w);
  }
  return out;
}

// -------------------------------------------------------------- envelopes

double env(double t, double dur, {double a = 0.004, double r = 0.05}) {
  if (t < 0 || t > dur) return 0;
  final atk = (t / a).clamp(0.0, 1.0);
  final rel = ((dur - t) / r).clamp(0.0, 1.0);
  return atk * rel;
}

double expEnv(double t, double dur, {double a = 0.003, double k = 5}) {
  if (t < 0 || t > dur) return 0;
  final atk = (t / a).clamp(0.0, 1.0);
  final fall = math.exp(-k * t / dur);
  return atk * fall;
}

// -------------------------------------------------------------- placement

class Sound {
  Sound()
      : samples = {
          'click.wav': [],
          'coin.wav': [],
          'star.wav': [],
          'honk.wav': [],
          'bounce.wav': [],
          'splash.wav': [],
          'boost.wav': [],
          'win.wav': [],
          'oops.wav': [],
          'menu_music.wav': [],
          'race_music.wav': [],
        };
  final Map<String, List<double>> samples;
}

void mixInto(List<double> dst, double startS, double dur,
    double Function(double t) f, {double gain = 1}) {
  final n0 = (startS * sr).round();
  final n = (dur * sr).round();
  if (dst.length < n0 + n) {
    final extra = List<double>.filled(n0 + n - dst.length, 0);
    dst.addAll(extra);
  }
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    dst[n0 + i] += f(t) * gain;
  }
}

void clampNormalize(List<double> s, {double targetPeak = 0.9}) {
  var peak = 0.0;
  for (final v in s) {
    final a = v.abs();
    if (a > peak) peak = a;
  }
  if (peak < 1e-9) return;
  final g = targetPeak / peak;
  for (var i = 0; i < s.length; i++) {
    s[i] = (s[i] * g).clamp(-1.0, 1.0);
  }
}

List<int> toPcm16(List<double> samples) {
  final bytes = <int>[];
  for (final v in samples) {
    final iv = (v.clamp(-1.0, 1.0) * 32767).round();
    bytes.add(iv & 0xFF);
    bytes.add((iv >> 8) & 0xFF);
  }
  return bytes;
}

void writeWav(String name, List<double> s) {
  final data = toPcm16(s);
  final bytes = BytesBuilder();

  void u32(int v) {
    bytes.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
  }

  void u16(int v) {
    bytes.add([v & 0xFF, (v >> 8) & 0xFF]);
  }

  final dataLen = data.length;
  bytes.add('RIFF'.codeUnits);
  u32(36 + dataLen);
  bytes.add('WAVE'.codeUnits);
  bytes.add('fmt '.codeUnits);
  u32(16); // fmt chunk size
  u16(1); // PCM
  u16(1); // mono
  u32(sr);
  u32(sr * 2); // byte rate
  u16(2); // block align
  u16(16); // bits per sample
  bytes.add('data'.codeUnits);
  u32(dataLen);
  bytes.add(data);

  Directory(outDir).createSync(recursive: true);
  File('$outDir/$name').writeAsBytesSync(bytes.takeBytes());
  print('  wrote $name (${(dataLen / 1024).round()} KB)');
}

// ------------------------------------------------------------- SFX makers

void buildSfx(Map<String, List<double>> m) {
  // click — friendly UI tick
  m['click.wav']!
    ..clear()
    ..length = 0;
  mixInto(m['click.wav']!, 0, 0.09, (t) {
    final f = 420 + t * 2200;
    return sine(t, f) * expEnv(t, 0.09, k: 6);
  }, gain: 0.8);

  // coin — bright two-step ping
  m['coin.wav']!
    ..clear()
    ..length = 0;
  mixInto(m['coin.wav']!, 0, 0.07, (t) {
    return (sine(t, 988) * 0.8 + sine(t, 1976) * 0.3) * expEnv(t, 0.07, k: 4);
  }, gain: 0.7);
  mixInto(m['coin.wav']!, 0.06, 0.16, (t) {
    return (sine(t, 1319) * 0.8 + sine(t, 2638) * 0.25) * expEnv(t, 0.16, k: 3.2);
  }, gain: 0.7);

  // star — quick sparkle arpeggio
  const starNotes = [783.99, 987.77, 1318.51, 1567.98];
  for (var i = 0; i < starNotes.length; i++) {
    final st = 0.07 * i;
    mixInto(m['star.wav']!, st, 0.12, (t) {
      return (sine(t, starNotes[i]) * 0.8 +
              sine(t, starNotes[i] * 2) * 0.35 +
              sine(t, starNotes[i] * 1.003) * 0.3) *
          expEnv(t, 0.12, k: 3.6);
    }, gain: 0.75);
  }

  // honk — cheerful traffic beep
  mixInto(m['honk.wav']!, 0, 0.17, (t) {
    final vib = 6 * math.sin(2 * math.pi * 7 * t);
    final v = square(t, 440 + vib) * 0.5 + triangle(t, 554) * 0.5;
    return v * env(t, 0.17, a: 0.008, r: 0.05);
  }, gain: 0.8);

  // bounce — soft cartoon "boing"
  mixInto(m['bounce.wav']!, 0, 0.22, (t) {
    final f = 300 + 250 * math.exp(-7 * t);
    return (sine(t, f) + 0.3 * sine(t, f * 2)) * expEnv(t, 0.22, k: 3.4);
  }, gain: 0.85);

  // splash — puddle splish
  mixInto(m['splash.wav']!, 0, 0.26, (t) {
    final sweep = 500 * math.exp(-9 * t) + 120;
    return (sine(t, sweep) * 0.6) * expEnv(t, 0.26, k: 3.6);
  }, gain: 0.7);
  final splashNoise = lowpass(
      List<double>.generate((0.26 * sr).round(), (_) => whiteNoise()), 10);
  for (var i = 0; i < splashNoise.length; i++) {
    final t = i / sr;
    splashNoise[i] =
        (splashNoise[i] * 40 + whiteNoise() * 0.55) * expEnv(t, 0.26, k: 4.5);
  }
  mixInto(m['splash.wav']!, 0, 0.26, (t) => t < 0.26 && t >= 0 ? splashNoise[(t * sr).round()] : 0,
      gain: 0.5);

  // boost — rising rocket whoosh
  mixInto(m['boost.wav']!, 0, 0.43, (t) {
    final f = 220 + 760 * (t / 0.43) * (t / 0.43);
    final eng = (sine(t, f) * 0.7 + triangle(t, f * 1.5) * 0.35) *
        env(t, 0.43, a: 0.02, r: 0.12);
    return eng;
  }, gain: 0.9);
  final boostNoise = lowpass(
      List<double>.generate((0.43 * sr).round(), (_) => whiteNoise()), 26);
  for (var i = 0; i < boostNoise.length; i++) {
    final t = i / sr;
    boostNoise[i] *= env(t, 0.43, a: 0.04, r: 0.16);
  }
  mixInto(m['boost.wav']!, 0, 0.43, (t) => t < 0.43 ? boostNoise[(t * sr).round()] : 0,
      gain: 0.5);

  // crash — gentle kid-safe "whoops" (no harsh metal), soft boom + shuffle
  final crashNoise = lowpass(
      List<double>.generate((0.4 * sr).round(), (_) => whiteNoise()), 42);
  for (var i = 0; i < crashNoise.length; i++) {
    final t = i / sr;
    crashNoise[i] *= expEnv(t, 0.4, k: 3.2);
  }
  m['oops.wav']!
    ..clear()
    ..length = 0;
  mixInto(m['oops.wav']!, 0, 0.4, (t) {
    final f = 130 - 80 * (t / 0.4);
    return sine(t, f) * expEnv(t, 0.4, k: 2.6);
  }, gain: 0.95);
  mixInto(m['oops.wav']!, 0, 0.4, (t) => t < 0.4 ? crashNoise[(t * sr).round()] : 0,
      gain: 0.6);

  // win — happy jingle C E G C'
  const winNotes = [523.25, 659.25, 783.99, 1046.5];
  for (var i = 0; i < winNotes.length; i++) {
    final st = 0.14 * i;
    final dur = i == winNotes.length - 1 ? 0.55 : 0.13;
    mixInto(m['win.wav']!, st, dur, (t) {
      return (square(t, winNotes[i]) * 0.35 + sine(t, winNotes[i]) * 0.85) *
          env(t, dur, a: 0.006, r: i == 3 ? 0.4 : 0.05);
    }, gain: 0.85);
  }
}

// ------------------------------------------------------------------ music

/// Simple handcrafted chip-tune loops. Both end exactly where they begin
/// in terms of composition, using per-note envelopes so the loop seam is
/// inaudible.
void buildMusic(Map<String, List<double>> m) {
  // menu_music — 96 BPM, 16 beats (10.0 s), gentle pentatonic lullaby-race
  const bpmA = 96.0;
  const beatA = 60 / bpmA; // 0.625 s
  final durA = beatA * 16;
  final menu = List<double>.filled((durA * sr).round(), 0);
  const bassA = [110.0, 87.31, 130.81, 98.0]; // A2 F3 C3 G2
  for (var b = 0; b < 4; b++) {
    mixInto(menu, beatA * (b * 4), beatA * 3.8, (t) {
      return (sine(t, bassA[b]) * 0.85 + sine(t, bassA[b] * 2) * 0.25) *
          env(t, beatA * 3.8, a: 0.02, r: 0.3);
    }, gain: 0.5);
  }
  // Lead melody, one entry = (freq, beats). Ends before loop end.
  const leadA = <(double, double)>[
    (523.25, 1), (659.25, 1), (783.99, 1.5), (659.25, 0.5),
    (587.33, 1), (523.25, 1), (493.88, 2),
    (523.25, 1), (587.33, 1), (659.25, 1.5), (587.33, 0.5),
    (493.88, 1), (440.0, 1), (523.25, 2),
  ];
  var cursor = 0.0;
  for (final (f, beats) in leadA) {
    final d = beatA * beats * 0.92;
    mixInto(menu, cursor, d, (t) {
      return (sine(t, f) * 0.9 + sine(t, f * 2) * 0.18) * env(t, d, a: 0.015, r: 0.12);
    }, gain: 0.55);
    cursor += beatA * beats;
  }
  // Soft hats on every other beat.
  for (var b = 0; b < 16; b += 2) {
    mixInto(menu, beatA * b, 0.05, (t) => whiteNoise() * expEnv(t, 0.05, k: 6),
        gain: 0.25);
  }
  clampNormalize(menu, targetPeak: 0.85);
  m['menu_music.wav'] = menu;

  // race_music — 132 BPM, 16 beats (~7.27 s), driving and bouncy
  const bpmB = 132.0;
  const beatB = 60 / bpmB;
  final durB = beatB * 16;
  final race = List<double>.filled((durB * sr).round(), 0);
  for (var e = 0; e < 32; e++) {
    final f = e % 4 == 2 ? 110.0 * 1.5 : 110.0; // A2, sprinkle A3
    mixInto(race, beatB * 0.5 * e, beatB * 0.44, (t) {
      return (square(t, f) * 0.7 + sine(t, f) * 0.5) * env(t, beatB * 0.44, a: 0.005, r: 0.05);
    }, gain: 0.42);
  }
  const leadB = <(double, double)>[
    (440.0, 0.5), (523.25, 0.5), (659.25, 0.5), (587.33, 0.5),
    (659.25, 0.5), (783.99, 0.5), (880.0, 1.0),
    (783.99, 0.5), (659.25, 0.5), (523.25, 0.5), (587.33, 0.5),
    (440.0, 0.5), (523.25, 0.5), (659.25, 1.0),
    (783.99, 0.5), (880.0, 0.5), (1046.5, 1.5),
  ];
  cursor = 0;
  for (final (f, beats) in leadB) {
    final d = beatB * beats * 0.9;
    mixInto(race, cursor, d, (t) {
      return (square(t, f) * 0.4 + sine(t, f) * 0.65 + sine(t, f * 2) * 0.15) *
          env(t, d, a: 0.008, r: 0.08);
    }, gain: 0.45);
    cursor += beatB * beats;
  }
  // eighth hats + snare-ish hits on beats 2 & 4
  for (var e = 0; e < 32; e++) {
    mixInto(race, beatB * 0.5 * e, 0.045, (t) => whiteNoise() * expEnv(t, 0.045, k: 6),
        gain: e % 2 == 0 ? 0.22 : 0.14);
  }
  for (final b in [1, 3, 5, 7, 9, 11, 13, 15]) {
    mixInto(race, beatB * b, 0.09, (t) {
      final n = lowpass([whiteNoise(), whiteNoise(), whiteNoise()], 3)[1];
      return n * expEnv(t, 0.09, k: 5);
    }, gain: 0.3);
  }
  clampNormalize(race, targetPeak: 0.88);
  m['race_music.wav'] = race;
}

void main() {
  print('Speedy Stars — synthesizing game audio…');
  final ws = Sound().samples;
  buildSfx(ws);
  buildMusic(ws);
  for (final e in ws.entries) {
    if (e.value.isEmpty) continue; // skip empties so we never ship silence
    var peak = 0.0;
    for (final v in e.value) {
      final a = v.abs();
      if (a > peak) peak = a;
    }
    if (e.key.contains('music')) {
      clampNormalize(e.value, targetPeak: 0.8);
    } else if (peak > 0.01) {
      clampNormalize(e.value, targetPeak: 0.92);
    }
    writeWav(e.key, e.value);
  }
  print('Done. ${ws.length} sounds generated into $outDir');
}
