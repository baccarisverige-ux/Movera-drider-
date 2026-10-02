import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/widgets/movera_map_style_lab.dart';
import 'dart:math' as math;

class CustomGoogleMap extends StatefulWidget {
  final CameraPosition? initialPosition;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Set<Circle>? circles;
  final Set<Polygon>? polygons;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final bool compassEnabled;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final bool indoorViewEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final MapType mapType;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(CameraPosition)? onCameraMove;
  final void Function()? onCameraIdle;
  final EdgeInsets padding;
  final String? customMapStyle;

  const CustomGoogleMap({
    super.key,
    this.initialPosition,
    this.markers,
    this.polylines,
    this.circles,
    this.polygons,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapToolbarEnabled = false,
    this.compassEnabled = false,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.indoorViewEnabled = false,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.mapType = MapType.normal,
    this.onMapCreated,
    this.onTap,
    this.onLongPress,
    this.onCameraMove,
    this.onCameraIdle,
    this.padding = EdgeInsets.zero,
    this.customMapStyle,
  });

  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  GoogleMapController? _mapController;

  // Default location - central Stockholm, the app's operating city.
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686),
    zoom: 13.0,
  );

  final MoveraMapStyleController _mapStyle =
      MoveraMapStyleController.instance;

  @override
  void initState() {
    super.initState();
    _mapStyle.addListener(_handleMapStyleChanged);
    unawaited(_mapStyle.ensureLoaded());
  }

  void _handleMapStyleChanged() {
    if (mounted && widget.customMapStyle == null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: widget.initialPosition ?? _defaultPosition,
      markers: widget.markers ?? {},
      polylines: widget.polylines ?? {},
      circles: widget.circles ?? {},
      polygons: widget.polygons ?? {},
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      mapToolbarEnabled: widget.mapToolbarEnabled,
      compassEnabled: widget.compassEnabled,
      trafficEnabled: widget.trafficEnabled,
      buildingsEnabled: widget.buildingsEnabled,
      indoorViewEnabled: widget.indoorViewEnabled,
      scrollGesturesEnabled: widget.scrollGesturesEnabled,
      zoomGesturesEnabled: widget.zoomGesturesEnabled,
      rotateGesturesEnabled: widget.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.tiltGesturesEnabled,
      mapType: widget.mapType,
      padding: widget.padding,
      style: widget.customMapStyle ?? _mapStyle.styleJson,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // Call the provided onMapCreated callback
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }
      },
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
    );
  }

  // Getter to access the map controller from outside
  GoogleMapController? get mapController => _mapController;

  @override
  void dispose() {
    _mapStyle.removeListener(_handleMapStyleChanged);
    // GoogleMap owns its platform controller. Avoid a second web disposal.
    _mapController = null;
    super.dispose();
  }
}

// Helper class for creating common map elements
class MapHelper {
  // Create a custom marker
  static Future<Marker> createCustomMarker({
    required String markerId,
    required LatLng position,
    String? infoWindow,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
  }) async {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(title: infoWindow),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: onTap,
    );
  }

  // Create a polyline (route)
  static Polyline createRoute({
    required String polylineId,
    required List<LatLng> points,
    Color color = Colors.blue,
    double width = 5.0,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width.toInt(),
    );
  }

  // Create a circle
  static Circle createCircle({
    required String circleId,
    required LatLng center,
    required double radius,
    Color fillColor = Colors.blue,
    Color strokeColor = Colors.blue,
    double strokeWidth = 2.0,
  }) {
    return Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: radius,
      fillColor: fillColor.withValues(alpha: 0.3),
      strokeColor: strokeColor,
      strokeWidth: strokeWidth.toInt(),
    );
  }

  // Calculate bounds for multiple points
  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double minLat = list.first.latitude;
    double minLng = list.first.longitude;
    double maxLat = list.first.latitude;
    double maxLng = list.first.longitude;

    for (LatLng point in list) {
      minLat = math.min(minLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLat = math.max(maxLat, point.latitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

// Import this for math operations
