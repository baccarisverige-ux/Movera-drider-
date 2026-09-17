import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/custom_textfield.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AddNewAccount extends StatelessWidget {
  const AddNewAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
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
          text: 'Add new account',
          color: AppColor.title,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.height,
              TextWidget(
                text: 'Bank Information',
                color: AppColor.title,
                fontSize: 24,
                fontWeight: fwBold,
              ),
              26.height,
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 18,
                  vertical: ResSize.h * 22,
                ),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Account Holder Name',
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                    ),
                    8.height,
                    customTextfield(
                      fillColor: Color(0xffF6F8FA),
                      borderColor: Colors.transparent,
                      borderWidth: 0,
                      hint: "Holder name",
                    ),
                    8.height,
                    TextWidget(
                      text: 'Bank Name',
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                    ),
                    8.height,
                    customTextfield(
                      fillColor: Color(0xffF6F8FA),
                      borderColor: Colors.transparent,
                      borderWidth: 0,
                      hint: "Bank name",
                    ),
                    8.height,
                    TextWidget(
                      text: 'Branch Code',
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                    ),
                    8.height,
                    customTextfield(
                      fillColor: Color(0xffF6F8FA),
                      borderColor: Colors.transparent,
                      borderWidth: 0,
                      hint: "Branch Code",
                    ),
                    8.height,
                    TextWidget(
                      text: 'Account Number',
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                    ),
                    8.height,
                    customTextfield(
                      fillColor: Color(0xffF6F8FA),
                      borderColor: Colors.transparent,
                      borderWidth: 0,
                      hint: "Account Number",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenHorizPadding,
          vertical: ResSize.h * 20,
        ),
        child: CustomButton(
          centerContent: "Add Account",
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
