// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'dart:io';

import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class UploadVehiclePhotos extends StatefulWidget {
  const UploadVehiclePhotos({super.key});

  @override
  State<UploadVehiclePhotos> createState() => _UploadVehiclePhotosState();
}

class _UploadVehiclePhotosState extends State<UploadVehiclePhotos> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> interiorImages = [];
  List<XFile> exteriorImages = [];

  Future<void> _pickImages(bool isInterior) async {
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedImages.isNotEmpty) {
        setState(() {
          if (isInterior) {
            interiorImages.addAll(pickedImages);
          } else {
            exteriorImages.addAll(pickedImages);
          }
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index, bool isInterior) {
    setState(() {
      if (isInterior) {
        interiorImages.removeAt(index);
      } else {
        exteriorImages.removeAt(index);
      }
    });
  }

  Widget _buildUploadButton(String title, bool isInterior) {
    return GestureDetector(
      onTap: () => _pickImages(isInterior),
      child: Row(
        children: [
          Container(
            width: ResSize.w * 50,
            height: ResSize.h * 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xffD9D9D9), width: 1.5),
            ),
            child: Center(
              child: Icon(
                Icons.file_upload_outlined,
                color: Color(0xffD9D9D9),
                size: ResSize.w * 32,
              ),
            ),
          ),
          16.width,
          TextWidget(
            text: "Upload photo",
            fontSize: 12,
            fontWeight: fwMedium,
            color: AppColor.subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<XFile> images, bool isInterior) {
    if (images.isEmpty) {
      return _buildUploadButton("Upload photo", isInterior);
    }

    return Wrap(
      spacing: ResSize.w * 12,
      runSpacing: ResSize.h * 12,
      children: [
        // Upload button
        _buildUploadButton("Upload photo", isInterior),
        // Images
        ...images.asMap().entries.map((entry) {
          int index = entry.key;
          XFile image = entry.value;
          return _buildImageTile(image, index, isInterior);
        }).toList(),
      ],
    );
  }

  Widget _buildImageTile(XFile image, int index, bool isInterior) {
    return Stack(
      children: [
        Container(
          width: ResSize.w * 160,
          height: ResSize.h * 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ResSize.w * 12),
            image: DecorationImage(
              image: FileImage(File(image.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: ResSize.h * 8,
          right: ResSize.w * 8,
          child: InkWell(
            onTap: () => _removeImage(index, isInterior),
            child: Container(
              width: ResSize.w * 24,
              height: ResSize.h * 24,
              decoration: const BoxDecoration(
                color: AppColor.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppColor.black,
                size: ResSize.w * 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            45.height,
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColor.title,
                size: ResSize.h * 20,
              ),
            ),
            16.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: "Upload Photos",
                    fontSize: 24,
                    fontWeight: fwExtraBold,
                    color: AppColor.title,
                  ),
                  9.height,

                  TextWidget(
                    text: "Upload vehicle photos for verification",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.subtitle,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    16.height,
                    // Upload Interior Images Section
                    TextWidget(
                      text: "Upload Interior Images",
                      fontSize: 14,
                      fontWeight: fwSemiBold,
                      color: AppColor.title,
                    ),
                    16.height,
                    _buildImageGrid(interiorImages, true),
                    40.height,
                    // Upload Exterior Images Section
                    TextWidget(
                      text: "Upload Exterior Images",
                      fontSize: 14,
                      fontWeight: fwSemiBold,
                      color: AppColor.title,
                    ),
                    16.height,
                    _buildImageGrid(exteriorImages, false),
                    40.height,
                  ],
                ),
              ),
            ),
            // Continue Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: CustomButton(
                centerContent: "Continue",
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   RightToLeftTransition(
                  //     const VehicleAdditionalDetailsScreen(),
                  //   ),
                  // );
                },
              ),
            ),
            20.height,
          ],
        ),
      ),
    );
  }
}
