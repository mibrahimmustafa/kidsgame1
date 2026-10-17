import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';

/// The customization hub: pick your racer (CARS), pick a chassis
/// (BODIES), then bolt on as many components as you own (MODS).
/// Everything previews live — what you buy is exactly what you drive.
class GarageScreen extends StatefulWidget {
  const GarageScreen({required this.save, this.initialTab = 'cars', super.key});
  final GameSave save;
  final String initialTab;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late final PageController _pc = PageController(viewportFraction: 0.72);
  int _index = 0;
  late String _tab = widget.initialTab;

  CarSpec get _current =>
      CarSpec.cars[_index.clamp(0, CarSpec.cars.length - 1)];

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

  void _notEnoughCoins(int needed) {
    AudioHub.instance.play(Sfx.bounce, volume: 0.7);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('You need $needed more coins!'),
      backgroundColor: AppTheme.inkDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _buyCar() {
    final car = _current;
    if (widget.save.isCarOwned(car.id)) return;
    if (widget.save.coins < car.price) {
      _notEnoughCoins(car.price - widget.save.coins);
      return;
    }
    widget.save.buyCar(car);
    AudioHub.instance.play(Sfx.star);
    setState(() {});
  }

  void _buyBody(BodyStyle body) {
    if (widget.save.ownsBody(body.id)) return;
    if (widget.save.coins < body.price) {
      _notEnoughCoins(body.price - widget.save.coins);
      return;
    }
    widget.save.buyBody(body);
    AudioHub.instance.play(Sfx.star);
    setState(() {});
  }

  void _buyMod(CarMod mod) {
    if (widget.save.ownsMod(mod.id)) return;
    if (widget.save.coins < mod.price) {
      _notEnoughCoins(mod.price - widget.save.coins);
      return;
    }
    widget.save.buyMod(mod);
    AudioHub.instance.play(Sfx.star);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 8),
                  _RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  Text(
                    'GARAGE',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.inkDark, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  _coinBadge(),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 10),
              _segmentedTabs(),
              Expanded(child: _tabContent()),
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppTheme.inkDark : Colors.white.withValues(alpha: .8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: active
                ? const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? Colors.white : AppTheme.inkDark),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppTheme.inkDark)),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip('cars', 'CARS', Icons.directions_car_rounded),
        const SizedBox(width: 8),
        chip('bodies', 'BODIES', Icons.car_repair_rounded),
        const SizedBox(width: 8),
        chip('mods', 'MODS', Icons.handyman_rounded),
      ],
    );
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
              final owned = widget.save.isCarOwned(car.id);
              final selected = widget.save.selectedCarId == car.id;
              return Padding(
                padding: const EdgeInsets.all(14),
                child: _CarCard(
                  car: car,
                  owned: owned,
                  selected: selected,
                  coins: widget.save.coins,
                  bodyStyle: BodyStyle.byId(widget.save.bodyId),
                  mods: widget.save.equippedMods,
                  onTap: _buyOrSelectCar,
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
              _RoundIconButton(
                  hero: false,
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _move(-1)),
              const SizedBox(width: 14),
              Text('${_index + 1} of ${CarSpec.cars.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppTheme.inkDark)),
              const SizedBox(width: 14),
              _RoundIconButton(
                  hero: false,
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _move(1)),
            ],
          ),
        ),
      ],
    );
  }

  void _buyOrSelectCar() {
    final car = _current;
    if (widget.save.isCarOwned(car.id)) {
      AudioHub.instance.play(Sfx.click);
      setState(() => widget.save.selectedCarId = car.id);
      return;
    }
    _buyCar();
  }

  // --------------------------------------------------------------- BODIES
  Widget _bodiesTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      itemCount: BodyStyle.values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        final body = BodyStyle.values[i];
        final owned = widget.save.ownsBody(body.id);
        final active = widget.save.bodyId == body.id;
        return Container(
          width: 250,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: active ? AppTheme.niceGreen : Colors.transparent,
                width: 3),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(body.label,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.inkDark)),
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
                style:
                    const TextStyle(fontSize: 12, color: AppTheme.inkDark),
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: active
                      ? AppTheme.niceGreen
                      : owned
                          ? AppTheme.niceBlue
                          : widget.save.coins >= body.price
                              ? AppTheme.coinGold
                              : Colors.grey.shade400,
                ),
                onPressed: () {
                  if (active) return;
                  if (owned) {
                    AudioHub.instance.play(Sfx.click);
                    widget.save.bodyId = body.id;
                    setState(() {});
                  } else {
                    _buyBody(body);
                  }
                },
                child: Text(
                  active
                      ? 'EQUIPPED ✓'
                      : owned
                          ? 'EQUIP'
                          : 'BUY • ${body.price}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _bodyBlurb(BodyStyle body) => switch (body) {
        BodyStyle.classic => 'The trusty all-rounder — perfect for learning.',
        BodyStyle.muscle => 'Big hood, bigger attitude. Burns rubber!',
        BodyStyle.sport => 'Low, light and slippery — hugs every corner.',
        BodyStyle.monster => 'Giant wheels that eat cones for breakfast.',
      };

  // ----------------------------------------------------------------- MODS
  Widget _modsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        childAspectRatio: 2.9,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on ? AppTheme.niceGreen : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Text(mod.emoji, style: const TextStyle(fontSize: 30)),
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
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(mod.blurb,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.black.withValues(alpha: .55))),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (!owned)
                _MiniButton(
                  label: '• ${mod.price}',
                  color: widget.save.coins >= mod.price
                      ? AppTheme.coinGold
                      : Colors.grey.shade400,
                  onTap: () => _buyMod(mod),
                )
              else
                _MiniButton(
                  label: on ? 'ON ✓' : 'OFF',
                  color: on ? AppTheme.niceGreen : Colors.black12,
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

  Widget _coinBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.coinGold,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text('${widget.save.coins}',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
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
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: hero ? Colors.white : const Color(0x30000000),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: hero ? AppTheme.inkDark : Colors.white, size: 26),
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.car,
    required this.owned,
    required this.selected,
    required this.coins,
    required this.bodyStyle,
    required this.mods,
    required this.onTap,
  });

  final CarSpec car;
  final bool owned;
  final bool selected;
  final int coins;
  final BodyStyle bodyStyle;
  final List<String> mods;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = darken(car.bodyColor, .3);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: selected ? AppTheme.niceGreen : Colors.transparent,
              width: 3),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              car.name,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: dark == Colors.white ? AppTheme.inkDark : dark),
            ),
            const SizedBox(height: 10),
            Bouncy(
              child: Container(
                width: 220,
                height: 120,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20)),
                child: CustomPaint(
                  size: const Size(220, 120),
                  painter: CarPreviewPainter(
                    car,
                    bodyStyle: bodyStyle,
                    mods: mods,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(car.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.inkDark)),
            ),
            const SizedBox(height: 10),
            _StatRow(label: 'SPEED', value: car.topSpeed / 76),
            _StatRow(label: 'GRIP', value: car.handling / 3.25),
            _StatRow(label: 'NITRO', value: (car.boostPower - 1.2) / 0.6),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: selected
                    ? AppTheme.niceGreen
                    : owned
                        ? AppTheme.niceBlue
                        : coins >= car.price
                            ? AppTheme.coinGold
                            : Colors.grey.shade400,
              ),
              onPressed: onTap,
              child: Text(
                selected
                    ? 'SELECTED ✓'
                    : owned
                        ? 'SELECT'
                        : 'BUY • ${car.price}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 48,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                color: AppTheme.nicePink,
                backgroundColor: Colors.black12,
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
