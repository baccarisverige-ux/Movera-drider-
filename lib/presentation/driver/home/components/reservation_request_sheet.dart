import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/core/geo/geo_point_maps.dart';
import 'package:movera/widgets/custom_google_map.dart';

enum ReservationDecision { accepted, denied, dismissed }

/// Home popup for a reservation request that arrives outside Radar.
Future<ReservationDecision> showReservationRequestSheet(
  BuildContext context,
  ReservationRequestPreview request, {
  WidgetBuilder? mapBuilder,
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
    ),
  );
  return decision ?? ReservationDecision.dismissed;
}

class ReservationRequestSheet extends StatelessWidget {
  const ReservationRequestSheet({
    super.key,
    required this.request,
    this.mapBuilder,
  });

  final ReservationRequestPreview request;

  /// Replaces the live map, for tests and previews.
  final WidgetBuilder? mapBuilder;

  static const Color _ink = Color(0xFF111614);
  static const Color _muted = Color(0xFF5E6461);
  static const Color _line = Color(0xFFE4E6E5);

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
                        child: IgnorePointer(
                          child: (mapBuilder ?? _liveMap)(context),
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
                          trailing: '${request.pickupMinutes} min',
                          trailingSub: '${_km(request.pickupKm)} away',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(width: 2, height: 14, color: _line),
                          ),
                        ),
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

  Widget _routeRow({
    required Widget dot,
    required String label,
    required String address,
    required String trailing,
    required String trailingSub,
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
              trailingSub,
              style: const TextStyle(color: _muted, fontSize: 11.5),
            ),
          ],
        ),
      ],
    );
  }

  static String _km(double km) =>
      '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';

  Widget _liveMap(BuildContext context) {
    final pickup = request.pickup.toLatLng();
    final dropoff = request.dropoff.toLatLng();
    final center = LatLng(
      (pickup.latitude + dropoff.latitude) / 2,
      (pickup.longitude + dropoff.longitude) / 2,
    );
    // Fit both points in a ~340 x 128 px frame.
    final spanKm = math.max(0.5, request.pickup.distanceMetersTo(request.dropoff) / 1000);
    final zoom = (14.2 - math.log(spanKm / 1.2) / math.ln2).clamp(9.0, 15.0);
    return CustomGoogleMap(
      initialPosition: CameraPosition(target: center, zoom: zoom),
      markers: {
        Marker(
          markerId: const MarkerId('reservation-pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('reservation-dropoff'),
          position: dropoff,
        ),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('reservation-route'),
          points: [pickup, dropoff],
          color: _ink,
          width: 4,
        ),
      },
      myLocationEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }
}

class _RouteDot extends StatelessWidget {
  const _RouteDot({required this.square});

  final bool square;

  @override
  Widget build(BuildContext context) {
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
