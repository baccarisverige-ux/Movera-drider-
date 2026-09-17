import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverDocuments extends StatelessWidget {
  const DriverDocuments({super.key});
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
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColor.title,
            size: ResSize.h * 18,
          ),
        ),
        centerTitle: true,
        title: TextWidget(
          text: 'Document',
          color: AppColor.title,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            12.height,
            Container(
              height: ResSize.h * 8,
              width: double.infinity,
              color: const Color(0xFFFAFAFA),
            ),
            16.height,
            TextWidget(
              text: "Driver Requirements",
              color: AppColor.title,
              fontSize: 18,
              fontWeight: fwSemiBold,
            ),
            16.height,
            item(documentType: "Driver’s License"),
            Divider(height: 0, thickness: 0.2, color: AppColor.border),
            item(documentType: "Insurance", isFailed: true),
            Divider(height: 0, thickness: 0.2, color: AppColor.border),
            item(documentType: "Vehicle Verification"),
            Divider(height: 0, thickness: 0.2, color: AppColor.border),
            item(documentType: "Driver’s ID"),
          ],
        ),
      ),
    );
  }

  Widget item({String? documentType, bool isFailed = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: ResSize.h * 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: documentType,
                  color: AppColor.subtitle,
                  fontSize: 16,
                  fontWeight: fwMedium,
                ),
                4.height,
                TextWidget(
                  text: isFailed ? "Failed" : "Verified",
                  color: isFailed ? AppColor.red : AppColor.green,
                  fontSize: 16,
                  fontWeight: fwMedium,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: ResSize.h * 20,
            color: AppColor.black,
          ),
        ],
      ),
    );
  }
}
