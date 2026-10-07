# Driver presentation source inventory

Generated from `ddf074a384dfb1ca3d32ce39b94393badb5d4deb`. This lists source files and callback references, including private widgets, disabled controls and helpers. It is not a reachable-route inventory or interaction certification. Classify each entry and link its runtime state evidence before closing it.

| Source | Widget classes | Callback references | Runtime coverage |
| --- | --- | --- | --- |
| `lib/presentation/common/chat/chat.dart` | Chat, SenderMessage | 2 | PENDING |
| `lib/presentation/common/chat/components/appbar.dart` | ChatAppBar | 2 | PENDING |
| `lib/presentation/driver/accept ride/accept_ride.dart` | AcceptRide, _ThrottledVehicleMap, _SlideRideAction | 4 | PENDING |
| `lib/presentation/driver/accept ride/accept_ride_panel.dart` | _RouteDot, _CleanSheet, _CleanRow | 23 | PENDING |
| `lib/presentation/driver/accept ride/accept_ride_trip.dart` | part/helper; classify entry | 8 | PENDING |
| `lib/presentation/driver/accept ride/adaptive_trip_island.dart` | AdaptiveTripIsland | 5 | PENDING |
| `lib/presentation/driver/accept ride/island_morph.dart` | IslandMorph | 0 | PENDING |
| `lib/presentation/driver/accept ride/island_waiting_motion.dart` | IslandWaitingLane, IslandRollingClock | 0 | PENDING |
| `lib/presentation/driver/accept ride/navigation_instruction_banner.dart` | NavigationInstructionBanner, _ArrivalApproachBanner, _ArrivalPointGraphic, _NextStopLine, _RadarOnOff | 4 | PENDING |
| `lib/presentation/driver/accept ride/rider_cancelled_sheet.dart` | RiderCancelledSheet | 1 | PENDING |
| `lib/presentation/driver/accept ride/trip_bottom_bar.dart` | TripBottomBar, TripJourneyLane | 2 | PENDING |
| `lib/presentation/driver/accept ride/trip_island.dart` | TripIsland | 3 | PENDING |
| `lib/presentation/driver/accept ride/trip_outcome_sheet.dart` | TripOutcomeSheet | 1 | PENDING |
| `lib/presentation/driver/accept ride/trip_top_reveal.dart` | TripTopReveal, TripDestinationCard | 0 | PENDING |
| `lib/presentation/driver/accept ride/waiting_time_sheet.dart` | WaitingTimeSheet, _PhaseCard, _CloseMark, WaitingClock | 5 | PENDING |
| `lib/presentation/driver/add vehicle/add_vehicle.dart` | AddVehicle, VehicleDocuments, _VehiclePhotoPage | 14 | PENDING |
| `lib/presentation/driver/analytics/acceptance rate/acceptance_rate.dart` | AcceptanceRate | 1 | PENDING |
| `lib/presentation/driver/analytics/analytics.dart` | Analytics | 2 | PENDING |
| `lib/presentation/driver/analytics/cancelation rate/cancelation_rate.dart` | CancelationRate | 1 | PENDING |
| `lib/presentation/driver/auth/additional detail/navigation.dart` | AdditionalInfoNavigation, ProgressWidget | 2 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/additional detail/screens/add_vehicle.dart` | AdditionDetailAddVehicle | 0 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/additional detail/screens/upload document/select document type/select_doc_typ.dart` | SelectDocumentType | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/additional detail/screens/upload document/take id photo/take_id_photo.dart` | TakeIdPhoto | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/additional detail/screens/upload document/upload_id.dart` | AdditionDetailUploadId | 0 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/additional detail/screens/vehicle_insurance.dart` | AdditionDetailVehicleInsurance | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/additional detail/screens/vehicle_registeration.dart` | AdditionDetailVehicleRegisteration | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/create acc/create_acc.dart` | DriverCreateAccount | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/create acc/create_acc_phone.dart` | DriverCreateAccountPhone | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/phone verification/phone_verify.dart` | DriverPhoneVerification | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/sign in/sign_in.dart` | DriverSignIn | 4 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/sign in phone/sign_in_phone.dart` | DriverSignInPhone | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/auth/starter/starter.dart` | DriverStarter | 3 | GATED LEGACY / PENDING |
| `lib/presentation/driver/destination mode/destination_picker.dart` | DriverDestinationPicker, _DirectionBadge, _DestinationRow, _NoDestinationResults | 5 | PENDING |
| `lib/presentation/driver/documents/document_preview.dart` | DocumentPreview | 0 | PENDING |
| `lib/presentation/driver/documents/documents.dart` | DriverDocuments | 2 | PENDING |
| `lib/presentation/driver/driving logs/driving_logs.dart` | DrivingLogs | 1 | PENDING |
| `lib/presentation/driver/earning stats/earning_stats.dart` | EarningStatsScreen | 2 | PENDING |
| `lib/presentation/driver/home/components/destination_set_panel.dart` | DestinationSetPanel | 4 | PENDING |
| `lib/presentation/driver/home/components/digital_island.dart` | DigitalIslandShell, DigitalFaceSwitcher, DigitalUpdatingFace, DigitalMessageFace, _TickerLine | 0 | PENDING |
| `lib/presentation/driver/home/components/driver_sheet_nav.dart` | _ScheduledRideIcon | 10 | PENDING |
| `lib/presentation/driver/home/components/driver_suspended_sheet.dart` | DriverSuspendedSheet | 1 | PENDING |
| `lib/presentation/driver/home/components/home_island_notices.dart` | part/helper; classify entry | 1 | PENDING |
| `lib/presentation/driver/home/components/island_messages.dart` | part/helper; classify entry | 0 | PENDING |
| `lib/presentation/driver/home/components/radar_edge_dash.dart` | RadarSheetOutline, RadarEdgeDash | 0 | PENDING |
| `lib/presentation/driver/home/components/reservation_request_sheet.dart` | ReservationRequestSheet, _ViewRouteChip, _RouteDot | 3 | PENDING |
| `lib/presentation/driver/home/components/reservation_route_map.dart` | ReservationRouteMap, ReservationRouteMapPage | 1 | PENDING |
| `lib/presentation/driver/home/components/trip_problem_sheet.dart` | part/helper; classify entry | 2 | PENDING |
| `lib/presentation/driver/home/home.dart` | DriverHome | 7 | PENDING |
| `lib/presentation/driver/home/home_map_sheet.dart` | part/helper; classify entry | 23 | PENDING |
| `lib/presentation/driver/home/home_offer_radar.dart` | part/helper; classify entry | 8 | PENDING |
| `lib/presentation/driver/my bank/add new account/add_new_account.dart` | AddNewAccount | 4 | PENDING |
| `lib/presentation/driver/my bank/my_bank.dart` | MyBank | 2 | PENDING |
| `lib/presentation/driver/my queue position/components/in_airport_queue.dart` | InAirportQueue | 1 | PENDING |
| `lib/presentation/driver/my queue position/my_queue_pos.dart` | MyQueuePosition | 2 | PENDING |
| `lib/presentation/driver/my wallet/wallet.dart` | WalletScreen | 3 | PENDING |
| `lib/presentation/driver/overlays/map_overlay_insets.dart` | part/helper; classify entry | 0 | PENDING |
| `lib/presentation/driver/overlays/trip_status_banner.dart` | TripStatusBanner | 0 | PENDING |
| `lib/presentation/driver/pin verification/pin_verification.dart` | PinVerification | 3 | PENDING |
| `lib/presentation/driver/preferences/preferences.dart` | Preferences | 4 | PENDING |
| `lib/presentation/driver/profile/legal_document.dart` | LegalDocumentScreen | 1 | PENDING |
| `lib/presentation/driver/profile/profile.dart` | DriverProfile | 7 | PENDING |
| `lib/presentation/driver/promotions/promotions.dart` | Promotions | 4 | PENDING |
| `lib/presentation/driver/ride completed/ride_completed.dart` | DriverRideCompleted | 2 | PENDING |
| `lib/presentation/driver/ride history/history detail/history_detail.dart` | DriverRideHistoryDetail | 2 | PENDING |
| `lib/presentation/driver/ride history/ride_history.dart` | DriverRideHistory, _PeriodButton, _MetricCard, _BreakdownRow, _HistoryRideCard | 8 | PENDING |
| `lib/presentation/driver/ride requests/ride_requests.dart` | RideRequests, _LiveDot | 3 | PENDING |
| `lib/presentation/driver/safety toolkits/safety_toolkits.dart` | SafetyToolKits, _SafetyToolButton | 13 | PENDING |
| `lib/presentation/driver/scheduled rides/scheduled_rides.dart` | ScheduledRidesScreen, _ScheduledRideCard, _RideMeta, _RoutePreview, _ScheduledRideDetailsScreen, _DetailMetric, _PlanRow, _CancelReasonSheet, _CancelConfirmationSheet | 12 | PENDING |
| `lib/presentation/driver/settings/accessibility/accessibility.dart` | Accessibility | 8 | PENDING |
| `lib/presentation/driver/settings/emergency_contacts.dart` | EmergencyContactsScreen, _ContactComposer | 5 | PENDING |
| `lib/presentation/driver/settings/settings.dart` | Settings | 7 | PENDING |
| `lib/presentation/driver/settings/sound & voice/sound_voice.dart` | SoundAndVoice | 6 | PENDING |
| `lib/presentation/driver/sheets/movera_snap_sheet_controller.dart` | part/helper; classify entry | 0 | PENDING |
| `lib/presentation/driver/sheets/sheet_trace.dart` | part/helper; classify entry | 0 | PENDING |
| `lib/presentation/driver/side menu/side_menu.dart` | DriverSideMenu | 12 | PENDING |
| `lib/presentation/driver/support/support_inbox.dart` | SupportInboxScreen, _TicketCard, _Conversation, _SupportIcon, _DraftFormLifetime | 10 | PENDING |
| `lib/presentation/driver/vehicles/vehicles.dart` | DriverVehicles | 4 | PENDING |
| `lib/presentation/driver/waybill/waybill_sheet.dart` | _WaybillHero, _WaybillSection, _RouteSection, _RouteRow | 0 | PENDING |
