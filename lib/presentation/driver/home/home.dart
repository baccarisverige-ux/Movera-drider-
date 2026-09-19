import 'dart:async';
import 'dart:ui' as ui;
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:movera/presentation/driver/accept%20ride/accept_ride.dart';
import 'package:movera/presentation/driver/home/components/account_activation_diaglog.dart';
import 'package:movera/presentation/driver/home/components/driver_sheet_nav.dart';
import 'package:movera/presentation/driver/home/components/home_direct_offer.dart';
import 'package:movera/presentation/driver/home/components/destination_set_panel.dart';
import 'package:movera/presentation/driver/my%20queue%20position/components/in_airport_queue.dart';
import 'package:movera/presentation/driver/my%20wallet/wallet.dart';
import 'package:movera/presentation/driver/promotions/promotions.dart';
import 'package:movera/presentation/driver/ride%20requests/ride_requests.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/safety%20toolkits/safety_toolkits.dart';
import 'package:movera/presentation/driver/search%20location/pickup_location.dart';
import 'package:movera/presentation/driver/side%20menu/side_menu.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
part 'home_state.dart';
part 'home_radar_a1.dart';
part 'home_radar_a2.dart';
part 'home_radar_b1.dart';
part 'home_radar_b2.dart';
part 'home_sheet.dart';


class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}
