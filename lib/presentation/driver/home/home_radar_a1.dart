part of 'home.dart';

extension _DriverHomeRadarA1 on _DriverHomeState {
  Widget _buildRadarMapBackdropImpl() {
    return SizedBox.expand(
      child: CustomGoogleMap(
        initialPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        trafficEnabled: false,
        buildingsEnabled: true,
        indoorViewEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onTap: (LatLng position) {},
      ),
    );
  }
  Widget bodyImpl({bool isDestinationPanel = false}) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: [
          CustomGoogleMap(
            initialPosition: _initialPosition,
            markers: {
              ..._markers,
              ..._directOfferRouteMarkers,
            },
            polylines: _directOfferRoutePolylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onTap: (LatLng position) {},
          ),
          isDestinationPanel
              ? Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    AppAssets.destinationSelected,
                    height: ResSize.h * 241,
                  ),
                )
              : SizedBox(),
          isDestinationPanel
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 140, right: 30),
                    child: InkWell(
                      onTap: () {
                        showSafetyToolKitSheet(context);
                      },
                      child: Image.asset(
                        AppAssets.direction,
                        height: ResSize.h * 90,
                      ),
                    ),
                  ),
                )
              : SizedBox(),
          Visibility(
            visible: true,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResSize.h * 55,
                horizontal: screenHorizPadding,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: ResSize.h * 38.5,
                      width: ResSize.w * 83,
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFF0F2F3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF172027).withOpacity(0.11),
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) => InkWell(
                                onTap: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                child: Center(
                                  child: Icon(
                                    Icons.menu_open_rounded,
                                    size: ResSize.h * 17,
                                    color: AppColor.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _mapControlDividerImpl(),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                showDriverSearchPickupLocationSheet(
                                  context,
                                  openDestinationPanel,
                                );
                              },
                              child: Center(
                                child: Image.asset(
                                  AppAssets.search,
                                  height: ResSize.h * 13,
                                  color: AppColor.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  isDestinationPanel
                      ? Padding(
                          padding: EdgeInsets.only(top: ResSize.h * 12),
                          child: InAirportQueue(),
                        )
                      : SizedBox(),
                ],
              ),
            ),
          ),
          if (!isDestinationPanel)
            ValueListenableBuilder<double>(
              valueListenable: _panelSlidePosition,
              builder: (context, panelPosition, child) {
                final maxPanelHeight =
                    MediaQuery.of(context).size.height * 0.86;
                const minPanelHeight = 108.0;
                final currentPanelHeight =
                    minPanelHeight +
                    ((maxPanelHeight - minPanelHeight) * panelPosition);
                final radarBottom = currentPanelHeight - 50;
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: radarBottom,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      reverseDuration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final scale = Tween<double>(
                          begin: 0.94,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<String>(
                          _isOnline
                              ? 'radar-online'
                              : _isGoingOnline
                              ? 'radar-connecting'
                              : 'radar-offline',
                        ),
                        child: _isOnline
                            ? _buildTripRadarButtonImpl()
                            : _isGoingOnline
                            ? _buildGoingOnlineButtonImpl()
                            : _buildGoOnlineButtonImpl(),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (!isDestinationPanel)
            Positioned(
              left: 14,
              right: 14,
              bottom: 178,
              child: IgnorePointer(
                ignoring: _homeDirectOffer == null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  reverseDuration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.10),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slide,
                        child: child,
                      ),
                    );
                  },
                  child: _homeDirectOffer == null
                      ? const SizedBox.shrink(
                          key: ValueKey<String>('no-direct-offer'),
                        )
                      : KeyedSubtree(
                          key: ValueKey<String>(_homeDirectOffer!.id),
                          child: _buildHomeDirectOfferCardImpl(
                            _homeDirectOffer!,
                          ),
                        ),
                ),
              ),
            ),
          if (!isDestinationPanel) ...[
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: _showTodaySummaryPopup
                  ? Curves.easeInCubic
                  : Curves.easeOutBack,
              left: _showTodaySummaryPopup ? -58 : -12,
              top: MediaQuery.sizeOf(context).height * 0.44,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showTodaySummaryPopup ? 0 : 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showTodaySummary,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(19),
                    ),
                    child: Container(
                      width: 62,
                      height: 50,
                      padding: const EdgeInsets.only(left: 14, right: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFA),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(19),
                        ),
                        border: Border.all(
                          color: const Color(0xFFDDE5E1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF172027).withOpacity(0.13),
                            blurRadius: 16,
                            offset: const Offset(4, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF315E4D),
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 460),
              curve: _showTodaySummaryPopup
                  ? Curves.easeOutCubic
                  : Curves.easeInCubic,
              left: _showTodaySummaryPopup ? 14 : -360,
              top: MediaQuery.sizeOf(context).height * 0.25,
              child: IgnorePointer(
                ignoring: !_showTodaySummaryPopup,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: _showTodaySummaryPopup ? 1 : 0,
                  child: _buildTodaySummaryPopupImpl(),
                ),
              ),
            ),
          ],
          if (!isDestinationPanel)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              right: 16,
              bottom: _homeDirectOffer == null ? 138 : 458,
              child: Material(
                color: AppColor.white,
                elevation: 4,
                shadowColor: const Color(0xFF1D2730).withOpacity(0.16),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => showSafetyToolKitSheet(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    height: 42,
                    width: 42,
                    child: Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF3F4A50),
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}
