import 'package:flutter/material.dart';
import 'package:movera/core/vehicle/local_vehicle_store.dart';
import 'package:movera/presentation/driver/add%20vehicle/add_vehicle.dart';

class DriverVehicles extends StatefulWidget {
  const DriverVehicles({super.key});

  @override
  State<DriverVehicles> createState() => _DriverVehiclesState();
}
class _DriverVehiclesState extends State<DriverVehicles> {
  final _store=LocalVehicleStore();
  List<Map<String,dynamic>> _vehicles=[];
  bool _failed=false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final rows=await _store.list();if(mounted) { setState(() {_vehicles=rows;_failed=false;}); } }
    catch(_) { if(mounted) { setState(()=>_failed=true); } }
  }
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF7D898F);
  static const Color _line = Color(0xFFE6E8EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(tooltip: 'Back', 
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        title: const Text(
          'Vehicles',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(tooltip: 'Add vehicle', 
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const AddVehicle()),
              );
              if(mounted) { await _load(); }
            },
            icon: const Icon(Icons.add_rounded, color: _ink),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if(_failed) TextButton(onPressed:_load, child:const Text('Could not load local vehicle drafts — Retry')),
          const Text('Local vehicle drafts — not activated or verified'),
          for(final vehicle in _vehicles) Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle['year']} ${vehicle['make']} ${vehicle['model']}',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 26,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vehicle['plate'] as String,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Trips only',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => VehicleDocuments(
                            vehicleId: vehicle['id'] as String,
                            make: vehicle['make'] as String,
                            model: vehicle['model'] as String,
                            year: vehicle['year'] as String,
                            plate: vehicle['plate'] as String,
                          ),
                        ),
                      );
                      if(mounted) { await _load(); }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F6F7),
                      foregroundColor: _ink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Manage vehicles',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore vehicle opportunities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Connect with a fleet partner or browse rental or purchase offers if you need another vehicle.',
                  style: TextStyle(
                    color: Color(0xFFD5DCE0),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
