import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  static const privacy = LegalDocumentScreen(
    title: 'Privacy policy',
    body:
        'Movera Driver uses location, trip and vehicle data to assign rides, '
        'show routes and keep a waybill on this device.\n\n'
        'Demo builds keep this information in memory on the phone. Nothing is '
        'sold to advertisers. You can log out at any time from Profile.\n\n'
        'When a live backend is connected, the same screens will keep using '
        'this policy text until a signed version is published.',
  );

  static const terms = LegalDocumentScreen(
    title: 'Terms of service',
    body:
        'You agree to drive only with a valid licence, insurance and a vehicle '
        'that matches the documents in this app.\n\n'
        'Radar offers are first-come. Matching another order while on a trip '
        'is optional. Completing a trip creates a waybill you can reopen from Home.\n\n'
        'Movera may suspend a demo account that misuses Safety tools or '
        'emergency calling.',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColor.title,
            size: ResSize.h * 18,
          ),
        ),
        centerTitle: true,
        title: TextWidget(
          text: title,
          color: AppColor.title,
          fontSize: 16,
          fontWeight: fwMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF3F4A50),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
