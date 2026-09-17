import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/auth/phone%20verification/phone_verify.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/custom_textfield.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/phone_picker.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class DriverCreateAccountPhone extends StatefulWidget {
  const DriverCreateAccountPhone({super.key});

  @override
  State<DriverCreateAccountPhone> createState() =>
      _DriverCreateAccountPhoneState();
}

class _DriverCreateAccountPhoneState extends State<DriverCreateAccountPhone> {
  String selectedCountryCode = '+92';
  Country? selectedCountry; // Add this to store the selected country

  @override
  void initState() {
    super.initState();
    // Set default country (United States)
    selectedCountry = CountryPickerUtils.getCountryByIsoCode('US');
    selectedCountryCode = '+1';
  }

  void updateCountryCode(String newCode, Country country) {
    setState(() {
      selectedCountryCode = newCode;
      selectedCountry = country;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            56.height,
            Transform.translate(
              offset: Offset(ResSize.w * -10, 0),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColor.title,
                  size: ResSize.h * 22,
                ),
              ),
            ),
            18.height,
            TextWidget(
              text: "Phone number",
              fontSize: 24,
              fontWeight: fwExtraBold,
            ),
            9.height,
            TextWidget(
              textAlign: TextAlign.start,
              text: "Enter a valid phone number where we will send",
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
            14.height,
            customTextfield(
              contentHorizPadding: 0,
              hint: "Phone number",
              keyboardType: TextInputType.phone,
              prefixWidget: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return PhoneNumberPicker(
                        onCountryCodeSelected: updateCountryCode,
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    top: 7,
                    bottom: 7,
                    right: 0,
                  ),
                  child: SizedBox(
                    width: ResSize.w * 75,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Display country flag instead of country code
                        if (selectedCountry != null)
                          CountryPickerUtils.getDefaultFlagImage(
                            selectedCountry!,
                          ),
                        5.width,

                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColor.hintText,
                          size: ResSize.h * 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: ResSize.h * 80,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            children: [
              CustomButton(
                centerContent: "Continue",
                onPressed: () {
                  Navigator.push(
                    context,
                    BottomToTopTransition(const DriverPhoneVerification()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
