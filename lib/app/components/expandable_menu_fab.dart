// Menu flottant déployable (premier niveau de navigation de Social) : un bouton rond avec ondes pulsées
// qui déploie vers le haut les sous-sections (icône + libellé). Aucune dépendance externe.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FabMenuItem {
  final IconData icon;
  final String label;
  final int badge; // > 0 : pastille de notification
  final String? asset; // logo (remplace l'icône)
  const FabMenuItem({
    required this.icon,
    required this.label,
    this.badge = 0,
    this.asset,
  });
}

class ExpandableMenuFab extends StatefulWidget {
  final List<FabMenuItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final Color color;
  final double bottom;
  const ExpandableMenuFab({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.color,
    this.bottom = 16,
  });

  @override
  State<ExpandableMenuFab> createState() => _ExpandableMenuFabState();
}

class _ExpandableMenuFabState extends State<ExpandableMenuFab>
    with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();
  bool get _isOpen =>
      _open.status == AnimationStatus.forward ||
      _open.status == AnimationStatus.completed;

  @override
  void dispose() {
    _open.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_isOpen) {
      _open.reverse();
    } else {
      _open.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<int>(0, (a, e) => a + e.badge);
    return AnimatedBuilder(
      animation: _open,
      builder: (_, __) {
        final t = Curves.easeOutBack.transform(_open.value.clamp(0.0, 1.0));
        return Stack(
          children: [
            if (_open.value > 0)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggle,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45 * _open.value),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              bottom: widget.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = widget.items.length - 1; i >= 0; i--)
                    if (_open.value > 0)
                      Opacity(
                        opacity:
                            ((_open.value * 1.4) -
                                    (widget.items.length - 1 - i) * 0.08)
                                .clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 24 * (i + 1)),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _pill(i),
                          ),
                        ),
                      ),
                  _main(total),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pill(int i) {
    final it = widget.items[i];
    final sel = i == widget.selected;
    return GestureDetector(
      onTap: () {
        widget.onSelect(i);
        _toggle();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                elevation: 6,
                color: sel ? widget.color : Colors.white,
                shape: const CircleBorder(),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: it.asset != null
                      ? Padding(
                          padding: const EdgeInsets.all(9),
                          child: Image.asset(it.asset!, fit: BoxFit.contain),
                        )
                      : Icon(
                          it.icon,
                          color: sel ? Colors.white : widget.color,
                          size: 24,
                        ),
                ),
              ),
              if (it.badge > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      it.badge > 99 ? '99+' : '${it.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? widget.color : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              it.label,
              style: TextStyle(
                color: sel ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _main(int badge) {
    final cur = widget.items[widget.selected.clamp(0, widget.items.length - 1)];
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ondes pulsées (seulement quand le menu est fermé)
          if (_open.value == 0)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  for (final o in [0.0, 0.5])
                    Container(
                      width: 56 + 34 * ((_pulse.value + o) % 1),
                      height: 56 + 34 * ((_pulse.value + o) % 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(
                          alpha: 0.22 * (1 - ((_pulse.value + o) % 1)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Material(
            elevation: 8,
            color: widget.color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Transform.rotate(
                  angle: _open.value * 0.785,
                  child: Icon(
                    _open.value > 0.5 ? Icons.add_rounded : cur.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          if (badge > 0 && _open.value == 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
