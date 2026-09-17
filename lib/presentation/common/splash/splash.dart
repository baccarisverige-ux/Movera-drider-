import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/presentation/common/onboarding/onboarding.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    startFadeAnimation();
    navigateToNextScreen();
  }

  void navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        RightToLeftTransition(const OnboardingScreen()),
      );
    });
  }

  startFadeAnimation() async {
    await Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        animate = false;
      });
    });
  }

  bool animate = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1200),
                opacity: animate ? 0 : 1,
                child: Image.asset(AppAssets.logo, height: ResSize.h * 104),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
