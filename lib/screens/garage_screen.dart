import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../game/audio.dart';
import '../game/models.dart';
import '../game/save.dart';

/// Pick one of six racers. Every car is viable; upgrades are about speed,
/// grip and nitro power — never pay-to-win, purely fun-to-drive variety.
class GarageScreen extends StatefulWidget {
  const GarageScreen({required this.save, super.key});
  final GameSave save;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late final PageController _pc = PageController(viewportFraction: 0.72);
  int _index = 0;

  CarSpec get _current => CarSpec.cars[_index.clamp(0, CarSpec.cars.length - 1)];

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

  void _buyOrSelect() {
    final car = _current;
    if (widget.save.isCarOwned(car.id)) {
      AudioHub.instance.play(Sfx.click);
      setState(() => widget.save.selectedCarId = car.id);
      return;
    }
    if (widget.save.coins < car.price) {
      AudioHub.instance.play(Sfx.bounce, volume: 0.7);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You need ${car.price - widget.save.coins} more coins!'),
        backgroundColor: AppTheme.inkDark,
      ));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Buy ${car.name}?'),
        content: Text(
            'It costs ${car.price} coins. Your coins: ${widget.save.coins}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.niceGreen),
            onPressed: () {
              widget.save.buyCar(car);
              AudioHub.instance.play(Sfx.star);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Buy it!'),
          ),
        ],
      ),
    );
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
                        onTap: _buyOrSelect,
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
                        hero: false, icon: Icons.chevron_left_rounded, onTap: () => _move(-1)),
                    const SizedBox(width: 14),
                    Text('${_index + 1} of ${CarSpec.cars.length}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkDark)),
                    const SizedBox(width: 14),
                    _RoundIconButton(
                        hero: false, icon: Icons.chevron_right_rounded, onTap: () => _move(1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
          const Icon(Icons.monetization_on_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text('${widget.save.coins}',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
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
        child: Icon(icon,
            color: hero ? AppTheme.inkDark : Colors.white, size: 26),
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
    required this.onTap,
  });

  final CarSpec car;
  final bool owned;
  final bool selected;
  final int coins;
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
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
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
                decoration: BoxDecoration(color: Colors.black12,
                    borderRadius: BorderRadius.circular(20)),
                child: CustomPaint(
                  size: const Size(220, 120),
                  painter: CarPreviewPainter(car),
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
