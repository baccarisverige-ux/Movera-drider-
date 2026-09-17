import 'package:flutter/material.dart';
import 'package:circle_progress_bar/circle_progress_bar.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/models/onboarding.dart';
import 'package:movera/presentation/driver/auth/starter/starter.dart';
import 'package:movera/presentation/rider/auth/starter/starter.dart';
import 'package:movera/presentation/rider/home/home.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  String currentTitle = '';
  String currentSubtitle = '';
  int currentPageIndex = 0;

  List<OnBoardingModel> onBoardingList = [
    OnBoardingModel(
      image: AppAssets.onboarding_1,
      title: 'Your Journey',
      subTitle:
          "From pick-up to drop-off, your ride is more than a trip its an experience. Smooth, Smart and just made for you",
    ),
    OnBoardingModel(
      image: AppAssets.onboarding_2,
      title: 'Our priority',
      subTitle:
          "We value your time and trust. That’s why we ensure fast, secure and seamless car bookings alwasy centered around you",
    ),
  ];
  @override
  void initState() {
    super.initState();
    currentTitle = onBoardingList[currentPageIndex].title;
    currentSubtitle = onBoardingList[currentPageIndex].subTitle;
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isImageAnimate = true;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload images
    for (var item in onBoardingList) {
      precacheImage(AssetImage(item.image), context);
    }
  }

  bool isImageAnimate = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            60.height,

            Expanded(
              child: PageView.builder(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                controller: controller,
                itemCount: onBoardingList.length,
                clipBehavior: Clip.none,
                onPageChanged: (int index) {
                  setState(() {
                    currentPageIndex = index;
                    currentTitle = onBoardingList[index].title;
                    currentSubtitle = onBoardingList[index].subTitle;
                    isImageAnimate = true;
                  });
                  // Preload next image
                  if (index < onBoardingList.length - 1) {
                    precacheImage(
                      AssetImage(onBoardingList[index + 1].image),
                      context,
                    );
                  }
                },
                itemBuilder: (_, index) {
                  return SizedBox(
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: ResSize.h * 50,
                              // left: ResSize.w * 30,
                              // right: ResSize.w * 30,
                              bottom: ResSize.h * 30,
                            ),
                            child: SizedBox(
                              child: Transform.scale(
                                scale: 1.2,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 1500),
                                  opacity: isImageAnimate ? 1.0 : 0.0,
                                  child: Image.asset(
                                    onBoardingList[index].image,
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: AppColor.black.withOpacity(0.12),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 20,
                  vertical: ResSize.h * 35,
                ),
                child: Column(
                  children: [
                    TextWidget(
                      text: currentTitle,
                      color: AppColor.title,
                      fontSize: ResSize.setSp(24),
                      fontWeight: fwBold,
                    ),
                    22.height,
                    TextWidget(
                      text: currentSubtitle,
                      color: AppColor.darkTitle,
                      fontSize: ResSize.setSp(14),
                      fontWeight: fwNormal,
                      textAlign: TextAlign.center,
                    ),

                    29.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: currentPageIndex == 1
                              ? () {
                                  Navigator.pushReplacement(
                                    context,
                                    BottomToTopTransition(Home()),
                                  );
                                }
                              : () {
                                  controller.animateToPage(
                                    currentPageIndex + 1,
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.linearToEaseOut,
                                  );
                                  isImageAnimate = false;
                                },
                          child: SizedBox(
                            height: ResSize.h * 60,
                            width: ResSize.w * 60,
                            child: CircleProgressBar(
                              strokeWidth: 3,
                              backgroundColor: Colors.transparent,
                              foregroundColor: Color(0xff98B1A7),
                              value:
                                  ((currentPageIndex + 1) *
                                  1.0 /
                                  onBoardingList.length),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppColor.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppColor.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
