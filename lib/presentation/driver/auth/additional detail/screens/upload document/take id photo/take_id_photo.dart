// import 'package:card_scanner/card_scanner.dart';
import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/driver/home/home.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class TakeIdPhoto extends StatefulWidget {
  const TakeIdPhoto({super.key});

  @override
  State<TakeIdPhoto> createState() => _TakeIdPhotoState();
}

class _TakeIdPhotoState extends State<TakeIdPhoto> {
  // CardDetails? _cardDetails;
  // bool _isScanning = false;

  // // Scanner options
  // CardScanOptions scanOptions = CardScanOptions(
  //   scanCardHolderName: true,
  //   validCardsToScanBeforeFinishingScan: 1,
  //   possibleCardHolderNamePositions: [
  //     CardHolderNameScanPosition.aboveCardNumber,
  //     CardHolderNameScanPosition.belowCardNumber,
  //   ],
  // );

  // @override
  // void initState() {
  //   super.initState();
  //   // Start scanning immediately when widget is initialized
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     scanCard();
  //   });
  // }

  // Future<void> scanCard() async {
  //   if (_isScanning) return;

  //   setState(() {
  //     _isScanning = true;
  //   });

  //   try {
  //     var cardDetails = await CardScanner.scanCard(scanOptions: scanOptions);
  //     if (!mounted) return;
  //     setState(() {
  //       _cardDetails = cardDetails;
  //       _isScanning = false;
  //     });
  //   } catch (e) {
  //     debugPrint("Error scanning card: $e");
  //     if (mounted) {
  //       setState(() {
  //         _isScanning = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            46.height,
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
            16.height,
            TextWidget(
              text: "Take photo of your ID",
              color: AppColor.title,
              fontSize: 24,
              fontWeight: fwSemiBold,
            ),
            16.height,
            TextWidget(
              text:
                  "Please ensure that all details are clearly visible to facilitate a smooth verification process.",
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
            48.height,

            // Show scanning status or retry button
            Column(
              children: [
                Container(
                  height: ResSize.h * 226,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppAssets.id),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenHorizPadding,
          vertical: ResSize.h * 20,
        ),
        child: SizedBox(
          height: ResSize.h * 110,
          child: Column(
            children: [
              CustomButton(
                centerContent: "Submit",
                onPressed: () {
                  Navigator.push(context, BottomToTopTransition(DriverHome()));
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, BottomToTopTransition(DriverHome()));
                },
                child: TextWidget(
                  text: "Retake",
                  color: AppColor.title,
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
