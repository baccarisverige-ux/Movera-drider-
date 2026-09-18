import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final MapType mapType;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(CameraPosition)? onCameraMove;
  final void Function()? onCameraIdle;
  final EdgeInsets padding;
  final String? customMapStyle;

  const CustomGoogleMap({
    Key? key,
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
    this.mapType = MapType.normal,
    this.onMapCreated,
    this.onTap,
    this.onLongPress,
    this.onCameraMove,
    this.onCameraIdle,
    this.padding = EdgeInsets.zero,
    this.customMapStyle,
  }) : super(key: key);

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

  // Map style with custom client colors
  // Exact visual palette shared with Movera Rider.
  static const String _defaultMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#eef1e8"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#747974"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f7f8f3"}, {"weight": 2}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d9dcd4"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#d8edb5"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry",
    "stylers": [{"color": "#f2f2ef"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#c1e589"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#aedb6f"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d9dcd5"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#fffdf5"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d5d9cf"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#e6e8e3"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#bfe5ef"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#66848a"}]
  }
]
'''

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
      mapType: widget.mapType,
      padding: widget.padding,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // Call the provided onMapCreated callback
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }

        // Applying a style during web map construction can prevent the
        // platform view from appearing. Apply it after the map is ready and
        // keep a styling failure from taking down the map itself.
        Future<void>.delayed(const Duration(milliseconds: 300), () async {
          if (!mounted) return;
          try {
            await controller.setMapStyle(
              widget.customMapStyle ?? _defaultMapStyle,
            );
          } catch (_) {
            // The default Google map remains usable if a platform rejects style.
          }
        });
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
    // GoogleMap owns its platform controller. Avoid a second web disposal.
    _mapController = null;
    super.dispose();
  }
}

// Extension class for common map operations
extension CustomGoogleMapExtensions on _CustomGoogleMapState {
  Future<void> animateToPosition(LatLng position, {double zoom = 14.0}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  Future<void> animateToFitBounds(LatLngBounds bounds) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  Future<LatLngBounds> getVisibleRegion() async {
    return await _mapController?.getVisibleRegion() ??
        LatLngBounds(southwest: LatLng(0, 0), northeast: LatLng(0, 0));
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
      fillColor: fillColor.withOpacity(0.3),
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
