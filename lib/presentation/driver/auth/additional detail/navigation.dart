import 'package:circle_progress_bar/circle_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/screens/add_vehicle.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/screens/upload%20document/select%20document%20type/select_doc_typ.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/screens/upload%20document/upload_id.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/screens/vehicle_insurance.dart';
import 'package:movera/presentation/driver/auth/additional%20detail/screens/vehicle_registeration.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AdditionalInfoNavigationController extends GetxController {
  final RxInt currentPageIndex = 0.obs;
  final PageController pageController = PageController();

  final List<Widget> pages = [
    AdditionDetailAddVehicle(
      circleProgress: (index, total) =>
          ProgressWidget(currentPageIndex: index, totalPages: total),
    ),
    AdditionDetailVehicleRegisteration(
      circleProgress: (index, total) =>
          ProgressWidget(currentPageIndex: index, totalPages: total),
    ),
    AdditionDetailVehicleInsurance(
      circleProgress: (index, total) =>
          ProgressWidget(currentPageIndex: index, totalPages: total),
    ),
    AdditionDetailUploadId(
      circleProgress: (index, total) =>
          ProgressWidget(currentPageIndex: index, totalPages: total),
    ),
  ];

  void moveToNextStep(BuildContext context) {
    if (currentPageIndex.value < pages.length - 1) {
      currentPageIndex.value++;
      pageController.animateToPage(
        currentPageIndex.value,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(context, TopToBottomTransition(SelectDocumentType()));
      // Last step reached
      // Handle navigation to next screen
    }
  }

  void moveToPreviousStep() {
    if (currentPageIndex.value > 0) {
      currentPageIndex.value--;
      pageController.animateToPage(
        currentPageIndex.value,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back(); // GetX navigation
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

// Updated main widget using GetX
class AdditionalInfoNavigation extends StatelessWidget {
  const AdditionalInfoNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdditionalInfoNavigationController());

    return Scaffold(
      body: SizedBox(
        child: Column(
          children: [
            46.height,
            Row(
              children: [
                IconButton(
                  onPressed: controller.moveToPreviousStep,
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColor.title,
                    size: ResSize.h * 22,
                  ),
                ),
              ],
            ),
            16.height,
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: PageView.builder(
                  controller: controller.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.pages.length,
                  itemBuilder: (BuildContext context, int index) {
                    return controller.pages[index];
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Obx(
                () => CustomButton(
                  centerContent:
                      controller.currentPageIndex.value <
                          controller.pages.length - 1
                      ? "Continue"
                      : "Verify",
                  onPressed: () {
                    controller.moveToNextStep(context);
                  },
                ),
              ),
            ),
            20.height,
          ],
        ),
      ),
    );
  }
}

class CircularProgressController extends GetxController
    with GetTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> progressAnimation;

  final RxDouble _currentProgress = 0.0.obs;
  final RxInt _currentPageIndex = 0.obs;
  final RxInt _totalPages = 4.obs;

  double get currentProgress => _currentProgress.value;
  int get currentPageIndex => _currentPageIndex.value;
  int get totalPages => _totalPages.value;

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
      duration: const Duration(
        milliseconds: 1500,
      ), // ✅ Slower animation (1.5 seconds)
      vsync: this,
    );

    // Initialize animation with current progress
    progressAnimation = Tween<double>(begin: 0.0, end: _currentProgress.value)
        .animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeInOutCubic,
          ),
        );
  }

  void updateProgress(int pageIndex, int total) {
    final newProgress = (pageIndex + 1) / total;

    // Create new animation from current progress to new progress
    progressAnimation =
        Tween<double>(
          begin: _currentProgress.value,
          end: newProgress, // Animate to new value
        ).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    // Update observable values
    _currentProgress.value = newProgress;
    _currentPageIndex.value = pageIndex;
    _totalPages.value = total;

    // Start animation
    animationController.reset();
    animationController.forward();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}

class ProgressWidget extends StatelessWidget {
  final int currentPageIndex;
  final int totalPages;

  const ProgressWidget({
    super.key,
    required this.currentPageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    // Get or create the controller
    final CircularProgressController controller = Get.put(
      CircularProgressController(),
    );

    // Update progress when widget rebuilds with new values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateProgress(currentPageIndex, totalPages);
    });

    return GetBuilder<CircularProgressController>(
      builder: (controller) {
        return AnimatedBuilder(
          animation: controller.progressAnimation,
          builder: (context, child) {
            return SizedBox(
              height: ResSize.h * 65,
              width: ResSize.w * 65,
              child: CircleProgressBar(
                animationDuration: Duration.zero, // Disable internal animation
                strokeWidth: 6,
                backgroundColor: const Color(0xffECECEC),
                foregroundColor: AppColor.primary,
                value: controller.progressAnimation.value,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Center(
                      child: TextWidget(
                        text: "${currentPageIndex + 1} of $totalPages",
                        fontSize: 12,
                        fontWeight: fwSemiBold,
                        color: AppColor.title,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
