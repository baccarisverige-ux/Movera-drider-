import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/core/session/driver_session_controller.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/presentation/driver/waybill/waybill_sheet.dart';
import 'package:movera/widgets/navigation_transition.dart';

class DriverRideCompleted extends StatefulWidget {
  const DriverRideCompleted({
    super.key,
    this.waybillRepository,
    this.sessionController,
  });

  final WaybillRepository? waybillRepository;
  final DriverSessionController? sessionController;

  @override
  State<DriverRideCompleted> createState() => _DriverRideCompletedState();
}

class _DriverRideCompletedState extends State<DriverRideCompleted> {
  static const Color _ink = Color(0xFF252E3A);
  static const Color _muted = Color(0xFF66737A);
  static const Color _green = Color(0xFF19865C);
  static const Color _line = Color(0xFFE7ECEA);

  double _rating = 0;
  late final WaybillRepository _waybills;

  WaybillRecord? get _record => _waybills.last;

  @override
  void initState() {
    super.initState();
    _waybills =
        widget.waybillRepository ?? InMemoryWaybillRepository.instance;
  }

  void _finish() {
    widget.sessionController?.stayOnlineAfterTrip();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    navigator.pushReplacement(
      BottomToTopTransition(
        DriverHome(
          initialOnline: true,
          waybillRepository: _waybills,
          sessionController: widget.sessionController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey<String>('ride-completed-scroll'),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildRiderCard(record),
                    const SizedBox(height: 12),
                    _buildRouteCard(record),
                    const SizedBox(height: 12),
                    _buildTripSummary(record),
                    const SizedBox(height: 12),
                    _buildMetaCard(record),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEFF2F1)),
                ),
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  key: const ValueKey<String>('ride-completed-done'),
                  onPressed: _finish,
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F0),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD7EBE1)),
          ),
          child: Image.asset(
            AppAssets.sucess,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ride completed',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Rate your experience',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          glow: false,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 30,
          itemPadding: const EdgeInsets.symmetric(horizontal: 3),
          unratedColor: const Color(0xFFD5DADC),
          itemBuilder: (_, __) => const Icon(
            Icons.star_rounded,
            color: Color(0xFFF2A12E),
          ),
          onRatingUpdate: (rating) => setState(() => _rating = rating),
          updateOnDrag: true,
        ),
      ],
    );
  }

  Widget _buildRiderCard(WaybillRecord? record) {
    return _card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              AppAssets.profileImg,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record?.riderName ?? 'Rider',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record?.service ?? 'Movera',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            record?.fare ?? 'Completed',
            style: const TextStyle(
              color: _green,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(WaybillRecord? record) {
    return _card(
      title: 'Route',
      child: Column(
        children: [
          _routeRow(
            color: _green,
            label: 'Pickup',
            value: record?.pickup ?? 'Pickup',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: SizedBox(
              height: 18,
              child: VerticalDivider(
                color: Color(0xFFD5DDDA),
                thickness: 1,
              ),
            ),
          ),
          _routeRow(
            color: _ink,
            label: 'Drop-off',
            value: record?.dropoff ?? 'Drop-off',
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummary(WaybillRecord? record) {
    return _card(
      title: 'Trip details',
      child: Column(
        children: [
          _summaryRow('Ride cost', record?.fare ?? '—'),
          const SizedBox(height: 12),
          _summaryRow('Service', record?.service ?? 'Movera'),
          const SizedBox(height: 12),
          _summaryRow('Matched via', record?.source ?? 'Movera'),
        ],
      ),
    );
  }

  Widget _buildMetaCard(WaybillRecord? record) {
    final issued = record?.issuedAt;
    final completedAt = issued == null
        ? 'Just now'
        : '${issued.year}-${issued.month.toString().padLeft(2, '0')}-'
            '${issued.day.toString().padLeft(2, '0')} · '
            '${issued.hour.toString().padLeft(2, '0')}:'
            '${issued.minute.toString().padLeft(2, '0')}';

    return _card(
      title: 'Waybill',
      trailing: record == null
          ? null
          : TextButton.icon(
              onPressed: () {
                showMoveraWaybillSheet(
                  context,
                  record,
                  title: 'Last waybill',
                );
              },
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('Open'),
              style: TextButton.styleFrom(
                foregroundColor: _green,
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      child: Column(
        children: [
          _summaryRow('Trip ID', record?.tripId ?? '—'),
          const SizedBox(height: 12),
          _summaryRow('Completed', completedAt),
        ],
      ),
    );
  }

  Widget _card({
    String? title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _routeRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8A959A),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
