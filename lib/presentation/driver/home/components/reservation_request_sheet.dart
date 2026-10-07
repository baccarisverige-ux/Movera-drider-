import 'package:movera/widgets/single_route_entry.dart';
import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/routing/road_route_service.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/session/driver_runtime_config.dart';
import 'package:movera/presentation/driver/home/components/reservation_route_map.dart';

enum ReservationDecision { accepted, denied, dismissed }

/// Home popup for a reservation request that arrives outside Radar.
Future<ReservationDecision> showReservationRequestSheet(
  BuildContext context,
  ReservationRequestPreview request, {
  WidgetBuilder? mapBuilder,
  RouteRepository? routes,
}) async {
  final decision = await showModalBottomSheet<ReservationDecision>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ReservationRequestSheet(
      request: request,
      mapBuilder: mapBuilder,
      routes: routes,
    ),
  );
  return decision ?? ReservationDecision.dismissed;
}

class ReservationRequestSheet extends StatefulWidget {
  const ReservationRequestSheet({
    super.key,
    required this.request,
    this.mapBuilder,
    this.routes,
  });

  final ReservationRequestPreview request;

  /// Replaces the live maps (popup and full route), for tests and previews.
  final WidgetBuilder? mapBuilder;

  /// Road routing; defaults to [RoadRouteService].
  final RouteRepository? routes;

  @override
  State<ReservationRequestSheet> createState() =>
      _ReservationRequestSheetState();
}

class _ReservationRequestSheetState extends State<ReservationRequestSheet> {
  static const Color _ink = Color(0xFF111614);
  static const Color _muted = Color(0xFF5E6461);
  static const Color _line = Color(0xFFE4E6E5);

  ReservationRequestPreview get request => widget.request;
  RoadRouteService? _ownRoutes;
  late final Future<List<GeoPoint>> _route;

  @override
  void initState() {
    super.initState();
    final routes = widget.routes ??
        (DriverRuntimeConfig.current.externalRouting
            ? _ownRoutes = RoadRouteService()
            : null);
    _route = loadReservationRoute(request, routes);
  }

  @override
  void dispose() {
    _ownRoutes?.dispose();
    super.dispose();
  }

  void _openRouteMap() {
    pushSingle(context,
      MaterialPageRoute<void>(
        builder: (_) => ReservationRouteMapPage(
          request: request,
          route: _route,
          mapBuilder: widget.mapBuilder == null
              ? null
              : (context, _) => widget.mapBuilder!(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You have a new reservation request',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 22,
                height: 1.25,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line, width: 1.5),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                    child: Row(
                      children: [
                        Expanded(child: _priceBlock()),
                        const SizedBox(width: 8),
                        ExcludeSemantics(
                          child: Image.asset(
                            AppAssets.reservationRequest,
                            width: 68,
                            height: 68,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 128,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            IgnorePointer(
                              child: (widget.mapBuilder ?? _liveMap)(context),
                            ),
                            Positioned.fill(
                              child: Material(
                                type: MaterialType.transparency,
                                child: InkWell(
                                  key: const ValueKey<String>(
                                    'reservation-map-open',
                                  ),
                                  onTap: _openRouteMap,
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 8,
                              bottom: 8,
                              child: IgnorePointer(child: _ViewRouteChip()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      children: [
                        _routeRow(
                          dot: const _RouteDot(square: false),
                          label: 'Pickup',
                          address: request.pickupAddress,
                          trailing: request.pickupTime,
                          trailingSub: request.pickupDay,
                        ),
                        _connector(),
                        for (var i = 0; i < request.stops.length; i++) ...[
                          _routeRow(
                            dot: const _RouteDot(square: false, stop: true),
                            label: 'Stop ${i + 1}',
                            address: request.stops[i].address,
                          ),
                          _connector(),
                        ],
                        _routeRow(
                          dot: const _RouteDot(square: true),
                          label: 'Drop-off',
                          address: request.dropoffAddress,
                          trailing: '${request.tripMinutes} min',
                          trailingSub: '${_km(request.tripKm)} ride',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: FilledButton(
                      key: const ValueKey<String>('reservation-deny'),
                      onPressed: () =>
                          Navigator.of(context).pop(ReservationDecision.denied),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEDEEED),
                        foregroundColor: _ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Deny',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 54,
                    child: FilledButton(
                      key: const ValueKey<String>('reservation-accept'),
                      onPressed: () => Navigator.of(context)
                          .pop(ReservationDecision.accepted),
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  request.category,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            request.fare,
            style: const TextStyle(
              color: _ink,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          request.pickupLabel,
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _connector() => Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(width: 2, height: 14, color: _line),
        ),
      );

  Widget _routeRow({
    required Widget dot,
    required String label,
    required String address,
    String? trailing,
    String? trailingSub,
  }) {
    return Row(
      children: [
        dot,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 11.5),
              ),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              trailing,
              style: const TextStyle(
                color: _ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              trailingSub ?? '',
              style: const TextStyle(color: _muted, fontSize: 11.5),
            ),
          ],
        ),
        ],
      ],
    );
  }

  static String _km(double km) =>
      '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';

  Widget _liveMap(BuildContext context) {
    return FutureBuilder<List<GeoPoint>>(
      future: _route,
      initialData: reservationWaypoints(request),
      builder: (context, snapshot) => ReservationRouteMap(
        request: request,
        route: snapshot.data ?? reservationWaypoints(request),
        // Keeps the route clear of the "View route" chip.
        padding: const EdgeInsets.only(bottom: 30),
        fitPadding: 22,
      ),
    );
  }
}

class _ViewRouteChip extends StatelessWidget {
  const _ViewRouteChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172027).withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_full_rounded, size: 13, color: Color(0xFF111614)),
          SizedBox(width: 5),
          Text(
            'View route',
            style: TextStyle(
              color: Color(0xFF111614),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  const _RouteDot({required this.square, this.stop = false});

  final bool square;

  /// A stop: smaller grey dot.
  final bool stop;

  @override
  Widget build(BuildContext context) {
    if (stop) {
      return Container(
        width: 12,
        height: 12,
        alignment: Alignment.center,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8A9195), width: 2.5),
          ),
        ),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: square ? const Color(0xFF111614) : Colors.white,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(2) : null,
        border: square
            ? null
            : Border.all(color: const Color(0xFF111614), width: 3),
      ),
    );
  }
}
