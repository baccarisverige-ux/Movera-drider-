import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/core/location/driver_location_repository.dart';
import 'package:movera/core/location/driver_location_service.dart';
import 'package:movera/core/routing/road_route_service.dart';
import 'package:movera/core/routing/route_repository.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/presentation/driver/home/home.dart';

void main() {
  runApp(const MoveraApp());
}

/// App composition root.
///
/// Long-lived frontend dependencies are created here and injected down into
/// feature screens. When backend adapters replace the current frontend
/// implementations, screen code does not need to change.
class MoveraApp extends StatefulWidget {
  const MoveraApp({super.key});

  @override
  State<MoveraApp> createState() => _MoveraAppState();
}

class _MoveraAppState extends State<MoveraApp> {
  late final DriverSessionController _session;
  late final WaybillRepository _waybills;
  late final DriverLocationRepository _location;
  late final RouteRepository _routing;

  @override
  void initState() {
    super.initState();
    _session = DriverSessionController();
    _waybills = InMemoryWaybillRepository.instance;
    _location = const DriverLocationService();
    _routing = RoadRouteService();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          title: 'Movera Driver',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(
            useMaterial3: true,
          ).copyWith(scaffoldBackgroundColor: AppColor.bg),
          home: DriverHome(
            sessionController: _session,
            waybillRepository: _waybills,
            locationRepository: _location,
            routeRepository: _routing,
          ),
        );
      },
    );
  }
}
