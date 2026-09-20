import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class DriverDestinationResult {
  const DriverDestinationResult({
    required this.position,
    required this.address,
  });

  final LatLng position;
  final String address;
}

class DriverDestinationPicker extends StatefulWidget {
  const DriverDestinationPicker({super.key});

  static Future<DriverDestinationResult?> open(BuildContext context) {
    return Navigator.of(context).push<DriverDestinationResult>(
      MaterialPageRoute(
        builder: (_) => const DriverDestinationPicker(),
      ),
    );
  }

  @override
  State<DriverDestinationPicker> createState() =>
      _DriverDestinationPickerState();
}

class _DriverDestinationPickerState extends State<DriverDestinationPicker> {
  static const LatLng _stockholm = LatLng(59.3293, 18.0686);

  static const List<_DestinationPlace> _places = [
    _DestinationPlace(
      name: 'Stockholm Central',
      address: 'Centralplan 15, Stockholm',
      position: LatLng(59.3300, 18.0581),
    ),
    _DestinationPlace(
      name: 'Kista centrum',
      address: 'Kista Galleria, Stockholm',
      position: LatLng(59.4032, 17.9448),
    ),
    _DestinationPlace(
      name: 'Solna centrum',
      address: 'Solna Torg, Solna',
      position: LatLng(59.3603, 18.0009),
    ),
    _DestinationPlace(
      name: 'Södertälje centrum',
      address: 'Storgatan, Södertälje',
      position: LatLng(59.1955, 17.6253),
    ),
    _DestinationPlace(
      name: 'Arlanda Airport',
      address: 'Stockholm Arlanda Airport',
      position: LatLng(59.6519, 17.9186),
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _center = _stockholm;
  String _selectedAddress = 'Move the map or search for one destination';
  bool _cameraMoving = false;

  List<_DestinationPlace> get _filteredPlaces {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _places.where((place) {
      return place.name.toLowerCase().contains(query) ||
          place.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _selectPlace(_DestinationPlace place) async {
    setState(() {
      _center = place.position;
      _selectedAddress = place.address;
      _searchController.text = place.name;
      _cameraMoving = false;
    });
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: place.position, zoom: 15.8),
      ),
    );
  }

  void _confirm() {
    final typed = _searchController.text.trim();
    final address = _selectedAddress.startsWith('Move the map')
        ? (typed.isEmpty ? 'Selected destination' : typed)
        : _selectedAddress;

    Navigator.of(context).pop(
      DriverDestinationResult(
        position: _center,
        address: address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final results = _filteredPlaces;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomGoogleMap(
              initialPosition: const CameraPosition(
                target: _stockholm,
                zoom: 14.2,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMove: (position) {
                _cameraMoving = true;
                _center = position.target;
              },
              onCameraIdle: () {
                if (!_cameraMoving || !mounted) return;
                setState(() {
                  _cameraMoving = false;
                  if (_searchController.text.trim().isEmpty) {
                    _selectedAddress =
                        'Selected point · ${_center.latitude.toStringAsFixed(4)}, ${_center.longitude.toStringAsFixed(4)}';
                  }
                });
              },
            ),
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 82),
                child: _DestinationPin(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  PointerInterceptor(
                    child: Material(
                      color: Colors.white,
                      elevation: 3,
                      shadowColor: const Color(0xFF172027).withOpacity(0.14),
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: const ValueKey<String>('destination-picker-back'),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PointerInterceptor(
                      child: Material(
                        color: Colors.white,
                        elevation: 3,
                        shadowColor:
                            const Color(0xFF172027).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        child: TextField(
                          key: const ValueKey<String>('destination-search'),
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Where are you heading?',
                            prefixIcon: Icon(Icons.search_rounded),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (results.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(66, 70, 14, 0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: PointerInterceptor(
                    child: Material(
                      color: Colors.white,
                      elevation: 5,
                      shadowColor:
                          const Color(0xFF172027).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 230),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 48,
                          ),
                          itemBuilder: (context, index) {
                            final place = results[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF315E4D),
                              ),
                              title: Text(
                                place.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF252E3A),
                                ),
                              ),
                              subtitle: Text(
                                place.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectPlace(place),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PointerInterceptor(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomInset),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8E5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF172027).withOpacity(0.14),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set destination',
                      style: TextStyle(
                        color: Color(0xFF252E3A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Movera will prioritize trips that keep you moving toward this destination.',
                      style: TextStyle(
                        color: Color(0xFF7D898F),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.near_me_outlined,
                            size: 19,
                            color: Color(0xFF315E4D),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedAddress,
                            key: const ValueKey<String>(
                              'destination-selected-address',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF3C474D),
                              fontSize: 12.5,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        key: const ValueKey<String>('destination-confirm'),
                        onPressed: _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF252E3A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Start Destination Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 62,
          width: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF58E5A6).withOpacity(0.14),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          height: 40,
          width: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF252E3A),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.near_me_rounded,
            color: Colors.white,
            size: 19,
          ),
        ),
      ],
    );
  }
}

class _DestinationPlace {
  const _DestinationPlace({
    required this.name,
    required this.address,
    required this.position,
  });

  final String name;
  final String address;
  final LatLng position;
}
