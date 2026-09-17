import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobkit_dashed_border/mobkit_dashed_border.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AdditionDetailVehicleRegisteration extends StatefulWidget {
  final Widget Function(int, int) circleProgress;
  const AdditionDetailVehicleRegisteration({
    super.key,
    required this.circleProgress,
  });

  @override
  State<AdditionDetailVehicleRegisteration> createState() =>
      _AdditionDetailVehicleRegisterationState();
}

class _AdditionDetailVehicleRegisterationState
    extends State<AdditionDetailVehicleRegisteration> {
  File? selectedFile;
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Vehicle Registration",
                      color: AppColor.title,
                      fontSize: 24,
                      fontWeight: fwExtraBold,
                    ),
                    TextWidget(
                      text: "Upload vehicle registration document",
                      color: AppColor.subtitle,
                      fontSize: 16,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
              ),
              widget.circleProgress(1, 4),
            ],
          ),
          30.height,
          selectedFile != null ? _buildFilePreview() : _buildUploadArea(),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResSize.w * 32),
      decoration: BoxDecoration(
        border: DashedBorder.fromBorderSide(
          dashLength: ResSize.w * 4,
          spaceLength: ResSize.w * 7,
          side: BorderSide(color: AppColor.border, width: ResSize.w * 2),
        ),
        borderRadius: BorderRadius.circular(ResSize.w * 12),
      ),
      child: Column(
        children: [
          // Upload icon
          Container(
            width: ResSize.w * 80,
            height: ResSize.h * 80,
            decoration: BoxDecoration(
              color: AppColor.liteBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              color: AppColor.primary,
              size: ResSize.w * 32,
            ),
          ),

          24.height,

          // Tap to upload text
          GestureDetector(
            onTap: _pickAnyFile,
            child: TextWidget(
              text: "Tap to upload",
              color: Color(0xff30A1F7),
              fontSize: 16,
              fontWeight: fwMedium,
            ),
          ),

          7.height,

          // File format info
          TextWidget(
            text: "PNG, JPG, PDF (max 800 x 400px)",
            color: AppColor.subtitle,
            fontSize: 16,
            fontWeight: fwMedium,
            textAlign: TextAlign.center,
          ),
          14.height,
          // OR divider
          Row(
            children: [
              Expanded(child: Container(height: 0.5, color: AppColor.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 16),
                child: TextWidget(
                  text: "OR",
                  color: AppColor.title,
                  fontSize: 16,
                  fontWeight: fwMedium,
                ),
              ),
              Expanded(child: Container(height: 0.5, color: AppColor.border)),
            ],
          ),
          14.height,

          // Open Camera button
          GestureDetector(
            onTap: _isPicking ? null : _openCamera,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResSize.w * 32,
                vertical: ResSize.h * 12,
              ),
              decoration: BoxDecoration(
                color: _isPicking ? Colors.grey[300] : Color(0xffD9D9D9),
                borderRadius: BorderRadius.circular(ResSize.w * 8),
              ),
              child: Center(
                child: TextWidget(
                  text: _isPicking ? "Opening..." : "Open Camera",
                  color: AppColor.title,
                  fontSize: 14,
                  fontWeight: fwMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    String fileName = selectedFile!.path.split('/').last;
    String extension = fileName.split('.').last.toLowerCase();

    bool isImage = ['png', 'jpg', 'jpeg'].contains(extension);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // File preview
          isImage
              ? Image.file(
                  selectedFile!,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),

          const SizedBox(width: 12),

          // File name
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Remove button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                selectedFile = null; // Reset back to upload area
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAnyFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'], // ⬅️ allow both
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
        });
        _showSuccessMessage("File selected successfully!");
      }
    } catch (e) {
      _showErrorMessage("Error selecting file: $e");
      print("---------------------$e---------------------");
    }
  }

  Future<void> _openCamera() async {
    if (_isPicking) return; // 🚫 Prevent multiple calls
    setState(() => _isPicking = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 400,
      );

      if (image != null && mounted) {
        setState(() {
          selectedFile = File(image.path);
        });
        _showSuccessMessage("Photo captured successfully!");
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage("Error capturing photo: $e");
      }
      debugPrint("---------------------$e---------------------");
    } finally {
      if (mounted) {
        setState(() => _isPicking = false); // ✅ Reset state properly
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
