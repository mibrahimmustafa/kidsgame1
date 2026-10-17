import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';

/// The customization hub — a dark showroom. Pick your racer (CARS),
/// pick a chassis (BODIES), then bolt on components (MODS).
/// Everything is FREE and previews live — what you tap is what you drive.
class GarageScreen extends StatefulWidget {
  const GarageScreen({required this.save, this.initialTab = 'cars', super.key});
  final GameSave save;
  final String initialTab;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late final PageController _pc = PageController(viewportFraction: 0.80);
  int _index = 0;
  late String _tab = widget.initialTab;

  static const _accentOf = {
    'cars': Color(0xFFFFC531),
    'bodies': Color(0xFF4FE3C1),
    'mods': Color(0xFFFF7BD5),
  };

  CarSpec get _current =>
      CarSpec.cars[_index.clamp(0, CarSpec.cars.length - 1)];

  Color get _accent => _accentOf[_tab] ?? _accentOf['cars']!;

  void _move(int delta) {
    AudioHub.instance.play(Sfx.click);
    final target = (_index + delta).clamp(0, CarSpec.cars.length - 1);
    _pc.animateToPage(target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic);
    setState(() => _index = target);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _buyCar() {
    final car = _current;
    if (widget.save.isCarOwned(car.id)) return;
    widget.save.buyCar(car);
    AudioHub.instance.play(Sfx.star);
    setState(() {});
  }

  void _buyBody(BodyStyle body) {
    if (widget.save.ownsBody(body.id)) return;
    widget.save.buyBody(body);
    AudioHub.instance.play(Sfx.star);
    setState(() {});
  }

  void _buyMod(CarMod mod) {
    if (widget.save.ownsMod(mod.id)) return;
    widget.save.buyMod(mod);
    AudioHub.instance.play(Sfx.star);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0F22), Color(0xFF101632), Color(0xFF160F33)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: _ShowroomBackdrop(),
              ),
              Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      _GlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop()),
                      const Spacer(),
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFF9FD8FF)],
                        ).createShader(r),
                        child: const Text(
                          'GARAGE',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      _coinBadge(),
                      const SizedBox(width: 10),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _segmentedTabs(),
                  Expanded(child: _tabContent()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segmentedTabs() {
    Widget chip(String id, String label, IconData icon) {
      final active = _tab == id;
      return GestureDetector(
        onTap: () {
          if (_tab == id) return;
          AudioHub.instance.play(Sfx.click);
          setState(() => _tab = id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [
                      (_accentOf[id] ?? _accentOf['cars']!),
                      darken((_accentOf[id] ?? _accentOf['cars']!), .35),
                    ],
                  )
                : null,
            color: active ? null : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(22),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: (_accentOf[id] ?? _accentOf['cars']!)
                            .withValues(alpha: .45),
                        blurRadius: 14,
                        offset: const Offset(0, 4)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 17,
                  color: active ? const Color(0xFF141824) : Colors.white70),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color:
                          active ? const Color(0xFF141824) : Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      chip('cars', 'CARS', Icons.directions_car_rounded),
      const SizedBox(width: 8),
      chip('bodies', 'BODIES', Icons.car_repair_rounded),
      const SizedBox(width: 8),
      chip('mods', 'MODS', Icons.handyman_rounded),
    ]);
  }

  Widget _tabContent() {
    switch (_tab) {
      case 'bodies':
        return _bodiesTab();
      case 'mods':
        return _modsTab();
      default:
        return _carsTab();
    }
  }

  // ----------------------------------------------------------------- CARS
  Widget _carsTab() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pc,
            itemCount: CarSpec.cars.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final car = CarSpec.cars[i];
              final selected = widget.save.selectedCarId == car.id;
              return Padding(
                padding: const EdgeInsets.all(14),
                child: _CarCard(
                  car: car,
                  selected: selected,
                  bodyStyle: BodyStyle.byId(widget.save.bodyId),
                  mods: widget.save.equippedMods,
                  onTap: () {
                    AudioHub.instance.play(Sfx.click);
                    if (selected) return;
                    _buyCar();
                    setState(
                        () => widget.save.selectedCarId = car.id);
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlassIconButton(
                  hero: false,
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _move(-1)),
              const SizedBox(width: 14),
              Text('${_index + 1} of ${CarSpec.cars.length}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: .6))),
              const SizedBox(width: 14),
              _GlassIconButton(
                  hero: false,
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _move(1)),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- BODIES
  Widget _bodiesTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      scrollDirection: Axis.horizontal,
      itemCount: BodyStyle.values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final body = BodyStyle.values[i];
        final active = widget.save.bodyId == body.id;
        return Container(
          width: 262,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color:
                    active ? _accent : Colors.white.withValues(alpha: .12),
                width: 2),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: _accent.withValues(alpha: .30),
                        blurRadius: 22,
                        offset: const Offset(0, 8)),
                  ]
                : const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 14,
                        offset: Offset(0, 8)),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(body.label,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Bouncy(
                child: CustomPaint(
                  size: const Size(200, 100),
                  painter: CarPreviewPainter(
                    _current,
                    bodyStyle: body,
                    mods: widget.save.equippedMods,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _bodyBlurb(body),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: .65)),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (active) return;
                  AudioHub.instance.play(Sfx.click);
                  _buyBody(body);
                  widget.save.bodyId = body.id;
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF26D07C)
                        : Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(18),
                    border: active
                        ? Border.all(color: Colors.transparent)
                        : Border.all(
                            color: Colors.white24,
                          ),
                  ),
                  child: Text(
                    active ? 'EQUIPPED ✓' : 'FREE — EQUIP',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        letterSpacing: .6,
                        color: active
                            ? const Color(0xFF07240F)
                            : const Color(0xFF26D07C)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _bodyBlurb(BodyStyle body) => switch (body) {
        BodyStyle.classic => 'Modern EV lines — silent, cool, quick.',
        BodyStyle.muscle => 'Big hood, bigger attitude. Burns rubber!',
        BodyStyle.sport => 'Low, light and slippery — hugs every corner.',
        BodyStyle.monster => 'Giant wheels that eat cones for breakfast.',
      };

  // ----------------------------------------------------------------- MODS
  Widget _modsTab() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 330,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: CarMod.mods.length,
      itemBuilder: (context, i) {
        final mod = CarMod.mods[i];
        final owned = widget.save.ownsMod(mod.id);
        final on = widget.save.isModEquipped(mod.id);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: on
                  ? _accent.withValues(alpha: .8)
                  : Colors.white.withValues(alpha: .12),
              width: 2,
            ),
            boxShadow: on
                ? [
                    BoxShadow(
                        color: _accent.withValues(alpha: .25),
                        blurRadius: 16,
                        offset: const Offset(0, 5)),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(mod.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(mod.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: Colors.white)),
                    Text(mod.blurb,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: .55))),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (!owned)
                _MiniButton(
                  label: 'FREE — ADD',
                  color: Colors.transparent,
                  borderColor: _accent,
                  textColor: _accent,
                  onTap: _buyModFor(mod),
                )
              else
                _MiniButton(
                  label: on ? 'ON ✓' : 'OFF',
                  color: on
                      ? const Color(0xFF26D07C)
                      : Colors.white.withValues(alpha: .10),
                  textColor: on
                      ? const Color(0xFF07240F)
                      : Colors.white70,
                  onTap: () {
                    AudioHub.instance.play(Sfx.click);
                    widget.save.toggleMod(mod.id);
                    setState(() {});
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  VoidCallback _buyModFor(CarMod mod) => () {
        AudioHub.instance.play(Sfx.click);
        _buyMod(mod);
        setState(() {});
      };

  Widget _coinBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3007),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.coinGold, width: 1.4),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: AppTheme.coinGold, size: 17),
          const SizedBox(width: 4),
          Text('${widget.save.coins}',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  color: AppTheme.coinGold)),
        ],
      ),
    );
  }
}

/// Deep-space showroom backdrop: faint grid + glow orbs + stars.
class _ShowroomBackdrop extends StatelessWidget {
  const _ShowroomBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShowroomPainter(),
      size: MediaQuery.of(context).size,
    );
  }
}

class _ShowroomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // starfield
    for (var i = 0; i < 46; i++) {
      final rand = math.Random(1000 + i);
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height * 0.8;
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * .5,
          Paint()..color = Colors.white.withValues(alpha: .18));
    }
    // two soft accent orbs
    _orb(canvas, Offset(size.width * .82, size.height * .12),
        size.width * .30, const Color(0x26FF7BD5));
    _orb(canvas, Offset(size.width * .08, size.height * .30),
        size.width * .26, const Color(0x224FE3C1));
    // perspective floor lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = 1;
    final horizon = size.height * .72;
    for (var i = -6; i <= 6; i++) {
      canvas.drawLine(
          Offset(size.width * .5 + i * size.width * .055, horizon),
          Offset(size.width * .5 + i * size.width * .34, size.height),
          gridPaint);
    }
    for (var i = 0; i < 5; i++) {
      final y = horizon + (size.height - horizon) * math.pow(i / 5, 2.2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _orb(Canvas c, Offset at, double r, Color color) {
    c.drawCircle(at, r,
        Paint()..shader =RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: at, radius: r)));
  }

  @override
  bool shouldRepaint(covariant _ShowroomPainter old) => false;
}

class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.car,
    required this.selected,
    required this.bodyStyle,
    required this.mods,
    required this.onTap,
  });
  final CarSpec car;
  final bool selected;
  final BodyStyle bodyStyle;
  final List<String> mods;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: selected
                  ? car.accentColor
                  : Colors.white.withValues(alpha: .12),
              width: 2),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: car.accentColor.withValues(alpha: .28),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ]
              : const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 14,
                      offset: Offset(0, 8)),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (r) => LinearGradient(
                colors: [
                  car.bodyColor,
                  Color.lerp(car.bodyColor, Colors.white, .4)!,
                ],
              ).createShader(r),
              child: Text(car.name,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
            Text(car.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: .55))),
            const SizedBox(height: 6),
            Bouncy(
              child: CustomPaint(
                size: const Size(210, 110),
                painter: CarPreviewPainter(
                  car,
                  bodyStyle: bodyStyle,
                  mods: mods,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _statBar('SPEED', car.topSpeed, const Color(0xFFFFC531)),
                  const SizedBox(height: 6),
                  _statBar('GRIP', car.handling, const Color(0xFF4FE3C1)),
                  const SizedBox(height: 6),
                  _statBar('NITRO', car.boostPower / 2, const Color(0xFFFF7BD5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 190,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF26D07C), Color(0xFF189A57)],
                      )
                    : LinearGradient(colors: [
                        car.accentColor,
                        darken(car.accentColor, .3),
                      ]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: (selected
                              ? const Color(0xFF26D07C)
                              : car.accentColor)
                          .withValues(alpha: .4),
                      blurRadius: 14,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Text(
                selected ? 'SELECTED ✓' : 'DRIVE THIS',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: .8,
                    color: Color(0xFF141824)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBar(String label, double value, Color color) {
    final frac = (value / 10).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: .6))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: .10)),
                  FractionallySizedBox(
                    widthFactor: frac,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient:
                            LinearGradient(colors: [color, darken(color, .25)]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
    this.borderColor,
  });
  final String label;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Text(label,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: .4)),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.hero = true,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hero
              ? Colors.white.withValues(alpha: .10)
              : Colors.white.withValues(alpha: .06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .16)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
