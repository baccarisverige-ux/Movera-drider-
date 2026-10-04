import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/widgets/route_mark_pins.dart';

/// Top of the Active Ride map: the navigation card, which the driver can
/// pull down to reveal the Home island (menu, earnings, search) above it,
/// and push back up to hide it.
class TripTopReveal extends StatefulWidget {
  const TripTopReveal({
    super.key,
    required this.child,
    this.onMenu,
    this.onSearch,
    this.initiallyOpen = false,
  });

  /// The navigation card.
  final Widget child;
  final VoidCallback? onMenu;
  final VoidCallback? onSearch;
  final bool initiallyOpen;

  @override
  State<TripTopReveal> createState() => _TripTopRevealState();
}

class _TripTopRevealState extends State<TripTopReveal> {
  late bool _open = widget.initiallyOpen;
  double _drag = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    _drag += details.delta.dy;
    if (!_open && _drag > 14) {
      setState(() => _open = true);
      _drag = 0;
    } else if (_open && _drag < -14) {
      setState(() => _open = false);
      _drag = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: EdgeInsets.only(top: pad.top + 8),
                  child: TripTopIsland(
                    onMenu: widget.onMenu,
                    onSearch: widget.onSearch,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        GestureDetector(
          key: const ValueKey<String>('trip-top-reveal'),
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (_) => _drag = 0,
          onVerticalDragUpdate: _onDragUpdate,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // With the island shown, the card sits right under it.
              MediaQuery.removePadding(
                context: context,
                removeTop: _open,
                child: widget.child,
              ),
              // Small handle: the card can be pulled down.
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111614).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Home island on the trip screen: menu, today's earnings (hidden
/// until tapped) and search.
class TripTopIsland extends StatefulWidget {
  const TripTopIsland({super.key, this.onMenu, this.onSearch});

  final VoidCallback? onMenu;
  final VoidCallback? onSearch;

  @override
  State<TripTopIsland> createState() => _TripTopIslandState();
}

class _TripTopIslandState extends State<TripTopIsland> {
  static const Color _ink = Color(0xFF111614);
  bool _showEarnings = false;

  @override
  Widget build(BuildContext context) {
    Widget divider() =>
        Container(width: 1, height: 20, color: const Color(0xFFE2E5E7));
    return Material(
      key: const ValueKey<String>('trip-top-island'),
      color: Colors.white,
      elevation: 6,
      shadowColor: const Color(0x38172027),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 252,
        height: 48,
        child: Row(
          children: [
            Tooltip(
              message: 'Menu',
              child: InkWell(
                onTap: widget.onMenu,
                child: const SizedBox(
                  width: 50,
                  height: 48,
                  child: Icon(Icons.menu_open_rounded, size: 22, color: _ink),
                ),
              ),
            ),
            divider(),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _showEarnings = !_showEarnings),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 19,
                        color: Color(0xFF1FA463),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _showEarnings ? '183.25 kr' : '•••• kr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            divider(),
            Tooltip(
              message: 'Search',
              child: InkWell(
                onTap: widget.onSearch,
                child: SizedBox(
                  width: 50,
                  height: 48,
                  child: Center(
                    child: Image.asset(AppAssets.search, height: 17, color: _ink),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small top card shown while the trip sheet is lifted: only where the
/// driver is heading, street on the first line and area on the second.
class TripDestinationCard extends StatelessWidget {
  const TripDestinationCard({
    super.key,
    required this.address,
    this.kind = RouteMarkKind.pickup,
    this.fallbackArea,
  });

  /// Full address, e.g. "Porslinsvägen 3, Södertälje".
  final String address;

  /// Which route mark leads the card, as on the map.
  final RouteMarkKind kind;

  /// Second line when [address] has no area part.
  final String? fallbackArea;

  @override
  Widget build(BuildContext context) {
    final comma = address.indexOf(',');
    final street = (comma < 0 ? address : address.substring(0, comma)).trim();
    final rest = comma < 0 ? '' : address.substring(comma + 1).trim();
    final area = rest.isNotEmpty ? rest : (fallbackArea ?? '').trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 6,
        8,
        0,
      ),
      child: Container(
        key: const ValueKey<String>('active-ride-destination-card'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            RouteMarkIcon(kind, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    street,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (area.isNotEmpty)
                    Text(
                      area,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
