import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/models/title_image.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class Preferences extends StatefulWidget {
  const Preferences({super.key});

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  List<TitleImageModel> preferences = [
    TitleImageModel(image: AppAssets.mini, title: "Mini Ride"),
    TitleImageModel(image: AppAssets.ecoFriendly, title: "Eco-Friendy"),
    TitleImageModel(image: AppAssets.xl, title: "Movera XL"),
    TitleImageModel(image: AppAssets.luxury, title: "Luxury"),
  ];
  // ✅ Move this outside the build() method
  List<bool> selectedPreferences = [];

  @override
  void initState() {
    super.initState();
    selectedPreferences = List.generate(preferences.length, (index) => false);
  }

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
          text: 'Preferences',
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
              text: "Select preferences",
              color: AppColor.title,
              fontSize: 18,
              fontWeight: fwSemiBold,
            ),
            16.height,
            GridView.builder(
              shrinkWrap: true,
              clipBehavior: Clip.none,
              padding: EdgeInsets.all(0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisExtent: ResSize.h * 150,
                crossAxisSpacing: ResSize.w * 12,
                mainAxisSpacing: ResSize.h * 12,
                crossAxisCount: 2,
              ),
              itemCount: preferences.length,
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedPreferences[index] = !selectedPreferences[index];
                    });
                  },
                  child: Container(
                    height: ResSize.h * 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Color(0xff909090).withOpacity(0.12),
                          blurRadius: 0,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 12,
                        vertical: ResSize.h * 12,
                      ),
                      child: Stack(
                        children: [
                          TextWidget(
                            text: preferences[index].title,
                            color: AppColor.title,
                            fontWeight: fwBold,
                            fontSize: 18,
                          ),
                          selectedPreferences[index]
                              ? Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: ResSize.h * 3,
                                    ),
                                    child: Container(
                                      height: ResSize.h * 20,
                                      width: ResSize.w * 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColor.primary,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.done_rounded,
                                          color: AppColor.white,
                                          size: ResSize.h * 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Image.asset(
                              preferences[index].image,
                              height: ResSize.h * 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
