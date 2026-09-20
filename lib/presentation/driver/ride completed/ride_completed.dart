// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/core/waybill/waybill.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

// Project utilities and widgets (following existing import style in the repo)

class DriverRideCompleted extends StatefulWidget {
  const DriverRideCompleted({super.key});

  @override
  State<DriverRideCompleted> createState() => _DriverRideCompletedState();
}

class _DriverRideCompletedState extends State<DriverRideCompleted> {
  double _rating = 0.0;
  late final WaybillRepository _waybills;

  WaybillRecord? get _record => _waybills.last;

  @override
  void initState() {
    super.initState();
    _waybills =
        widget.waybillRepository ?? InMemoryWaybillRepository.instance;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            50.height,
            _buildHeader(),
            24.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: _buildRiderStrip(context),
            ),
            16.height,

            _buildTripDetailsTitle(),
            16.height,

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: _buildPickupDropSection(),
            ),
            16.height,
            Container(
              height: ResSize.h * 4,
              width: double.infinity,
              color: Color(0xffF9F9F9),
            ),
            16.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: _buildSummaryRows(context),
            ),
            16.height,
            Container(
              height: ResSize.h * 4,
              width: double.infinity,
              color: Color(0xffF9F9F9),
            ),
            16.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                children: [
                  _buildMetaRows(),
                  24.height,
                  CustomButton(
                    centerContent: 'Done',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                        return;
                      }

                      Navigator.pushReplacement(
                        context,
                        BottomToTopTransition(
                          DriverHome(
                            initialOnline: true,
                            waybillRepository: _waybills,
                          ),
                        ),
                      );
                    },
                  ),
                  30.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 12 * ResSize.h),
        Center(child: Image.asset(AppAssets.sucess, height: ResSize.h * 75)),
        16.height,
        Center(
          child: TextWidget(
            text: 'Ride Completed',
            color: AppColor.black,
            fontSize: 20,
            fontWeight: fwBold,
          ),
        ),
        12.height,
        Center(
          child: TextWidget(
            text: 'Rate your experience',
            color: AppColor.black,
            fontSize: 14,
            fontWeight: fwBold,
          ),
        ),
        16.height,
        Center(
          child: RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            glow: false,
            direction: Axis.horizontal,
            allowHalfRating: true,
            unratedColor: Color(0xff909090),
            itemCount: 5,
            itemSize: ResSize.h * 37,
            itemPadding: EdgeInsets.symmetric(horizontal: ResSize.w * 6),
            itemBuilder: (context, _) =>
                Icon(Icons.star_rounded, color: Color(0xffF99417)),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
            updateOnDrag: true,
          ),
        ),
        12.height,
      ],
    );
  }

  Widget _buildRiderStrip(BuildContext context) {
    final record = _record;
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: AssetImage(AppAssets.profileImg),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            record?.riderName ?? 'Rider',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF252E3A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            record?.fare ?? 'Completed',
            style: const TextStyle(
              color: Color(0xFF19865C),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailsTitle() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F9F8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Trip details',
              style: TextStyle(
                color: Color(0xFF66737A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'Completed',
            style: TextStyle(
              color: Color(0xFF19865C),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDropSection() {
    final record = _record;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECEA)),
      ),
      child: Column(
        children: [
          _completedRouteRow(
            color: const Color(0xFF19865C),
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
          _completedRouteRow(
            color: const Color(0xFF252E3A),
            label: 'Drop-off',
            value: record?.dropoff ?? 'Drop-off',
          ),
        ],
      ),
    );
  }

  Widget _completedRouteRow({
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
                  color: Color(0xFF252E3A),
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

  Widget _buildSummaryRows(BuildContext context) {
    final record = _record;
    return Column(
      children: [
        _summaryRow(
          label: 'Ride cost',
          value: record?.fare ?? '—',
        ),
        const SizedBox(height: 14),
        _summaryRow(
          label: 'Service',
          value: record?.service ?? 'Movera',
        ),
        const SizedBox(height: 14),
        _summaryRow(
          label: 'Matched via',
          value: record?.source ?? 'Movera',
        ),
      ],
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF66737A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
              color: Color(0xFF252E3A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRows() {
    final record = _record;
    final issued = record?.issuedAt;
    final completedAt = issued == null
        ? 'Just now'
        : '${issued.year}-${issued.month.toString().padLeft(2, '0')}-'
            '${issued.day.toString().padLeft(2, '0')} · '
            '${issued.hour.toString().padLeft(2, '0')}:'
            '${issued.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        _summaryRow(
          label: 'Trip ID',
          value: record?.tripId ?? '—',
        ),
        const SizedBox(height: 14),
        _summaryRow(
          label: 'Completed',
          value: completedAt,
        ),
      ],
    );
  }

}
