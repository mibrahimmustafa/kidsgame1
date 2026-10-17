import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/haptics.dart';
import '../game/save.dart';

/// Kid safety first: every destructive action (reset progress) hides
/// behind a press-and-hold parent gate (3 seconds), following
/// Google Play Families guidance.
Future<void> showParentSettingsDialog(BuildContext context, GameSave save) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ParentDialog(save: save),
  );
}

class _ParentDialog extends StatefulWidget {
  const _ParentDialog({required this.save});
  final GameSave save;

  @override
  State<_ParentDialog> createState() => _ParentDialogState();
}

class _ParentDialogState extends State<_ParentDialog> {
  Timer? _hold;
  double _holdProgress = 0;

  void _startHold() {
    _hold?.cancel();
    _hold = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) return;
      _holdProgress += 0.05 / 3.0; // 3 seconds to complete
      if (_holdProgress >= 1) {
        t.cancel();
        widget.save.resetAll();
        Navigator.maybePop(context);
      } else {
        setState(() {});
      }
    });
  }

  void _cancelHold() {
    _hold?.cancel();
    if (mounted) setState(() => _holdProgress = 0);
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.save;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.family_restroom_rounded,
                  color: AppTheme.niceBlue),
              const SizedBox(width: 8),
              Text('Grown-Up Settings',
                  style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 16),
            _switchTile(
              icon: Icons.music_note_rounded,
              title: 'Music',
              value: save.musicOn,
              onChanged: (v) {
                AudioHub.instance.attachSave(save);
                save.setMusic(v);
                AudioHub.instance.applySettings();
                setState(() {});
              },
            ),
            _switchTile(
              icon: Icons.volume_up_rounded,
              title: 'Sound effects',
              value: save.sfxOn,
              onChanged: (v) {
                save.setSfx(v);
                if (v) AudioHub.instance.play(Sfx.click);
                setState(() {});
              },
            ),
            _switchTile(
              icon: Icons.videocam_rounded,
              title: 'Real cockpit camera',
              value: save.cockpitView,
              onChanged: (v) {
                AudioHub.instance.attachSave(save);
                save.setCockpitView(v);
                setState(() {});
              },
            ),
            _switchTile(
              icon: Icons.vibration_rounded,
              title: 'Vibration feedback',
              value: save.hapticsOn,
              onChanged: (v) {
                save.setHaptics(v);
                // Instant feel-check: buzz once when turning it back on.
                if (v) Buzz.medium();
                setState(() {});
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Reset all progress — hold for 3 seconds',
              style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onLongPressStart: (_) => _startHold(),
              onLongPressEnd: (_) => _cancelHold(),
              onLongPressCancel: _cancelHold,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    Container(
                      height: 46,
                      color: Colors.redAccent.withValues(alpha: .12),
                      alignment: Alignment.center,
                      child: const Text(
                        'PRESS & HOLD TO RESET',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.redAccent),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _holdProgress.clamp(0, 1),
                      alignment: Alignment.centerLeft,
                      child: Container(height: 46, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.niceBlue),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      visualDensity: VisualDensity.compact,
    );
  }
}
