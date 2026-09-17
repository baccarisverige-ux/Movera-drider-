import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/color_picker.dart';
import 'package:movera/widgets/dropdown.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/custom_textfield.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AdditionDetailAddVehicle extends StatefulWidget {
  final Widget Function(int, int) circleProgress;
  const AdditionDetailAddVehicle({super.key, required this.circleProgress});

  @override
  State<AdditionDetailAddVehicle> createState() =>
      _AdditionDetailAddVehicleState();
}

class _AdditionDetailAddVehicleState extends State<AdditionDetailAddVehicle> {
  final TextEditingController _makeController = TextEditingController(
    text: 'Toyota',
  );
  final TextEditingController _modelController = TextEditingController(
    text: 'Mark X',
  );
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _plateController = TextEditingController(
    text: 'AQS - 140',
  );
  final TextEditingController _vehicleTypePrimaryController =
      TextEditingController(text: 'Luxury');
  final TextEditingController _vehicleTypeSecondaryController =
      TextEditingController(text: 'Luxury');
  final TextEditingController _colorController = TextEditingController();

  // Example dropdown data; replace with your real lists if needed.
  final List<String> vehicleTypes = const [
    'Luxury',
    'Standard',
    'Economy',
    'SUV',
  ];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _vehicleTypePrimaryController.dispose();
    _vehicleTypeSecondaryController.dispose();
    _colorController.dispose();
    super.dispose();
  }

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
                      text: 'Add Vehicle',
                      color: AppColor.title,
                      fontSize: 22,
                      fontWeight: fwExtraBold,
                    ),
                    9.height,
                    TextWidget(
                      text: 'Add Vehicle details for verification',
                      color: AppColor.subtitle,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
              ),
              widget.circleProgress(0, 4),
            ],
          ),
          28.height,
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Vehicle make'),
                  8.height,
                  customTextfield(
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    fillColor: Color(0xffF6F8FA),
                    controller: _makeController,
                    hint: 'Toyota',
                    suffixWidget: Padding(
                      padding: EdgeInsets.all(12),
                      child: Transform.scale(
                        scale: 0.7,
                        child: Image.asset(
                          AppAssets.vehicle,
                          height: ResSize.h * 18,
                        ),
                      ),
                    ),
                  ),
                  16.height,
                  _buildLabel('Vehicle model'),
                  8.height,
                  customTextfield(
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    fillColor: Color(0xffF6F8FA),
                    controller: _modelController,
                    hint: 'Mark X',
                    suffixWidget: Padding(
                      padding: EdgeInsets.all(12),
                      child: Transform.scale(
                        scale: 0.7,
                        child: Image.asset(
                          AppAssets.vehicle,
                          height: ResSize.h * 18,
                        ),
                      ),
                    ),
                  ),
                  16.height,
                  _buildLabel('Vehicle year'),
                  8.height,
                  customTextfield(
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    fillColor: Color(0xffF6F8FA),
                    controller: _yearController,
                    hint: 'select model year',
                    keyboardType: TextInputType.number,
                    ontap: () {},
                    suffixWidget: Padding(
                      padding: EdgeInsets.all(12),
                      child: Transform.scale(
                        scale: 0.8,
                        child: Image.asset(
                          AppAssets.model,
                          height: ResSize.h * 22,
                        ),
                      ),
                    ),
                  ),
                  16.height,
                  _buildLabel('License plate number'),
                  8.height,
                  customTextfield(
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    fillColor: Color(0xffF6F8FA),
                    keyboardType: TextInputType.number,
                    controller: _plateController,
                    hint: 'AQS - 140',
                  ),
                  16.height,
                  _buildLabel('Vehicle type'),
                  8.height,
                  AppDropdownField(
                    controller: _vehicleTypePrimaryController,
                    hint: 'Luxury',
                    items: vehicleTypes,
                  ),
                  16.height,
                  _buildLabel('Vehicle type'),
                  8.height,
                  AppDropdownField(
                    controller: _vehicleTypeSecondaryController,
                    hint: 'Luxury',
                    items: vehicleTypes,
                  ),
                  16.height,
                  _buildLabel('Color'),
                  8.height,
                  customTextfield(
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    fillColor: Color(0xffF6F8FA),
                    controller: _colorController,
                    hint: 'Select color',
                    readOnly: true,
                    ontap: () {
                      ColorPickerDialog.show((selectedColor) {
                        _colorController.text = selectedColor;
                      });
                    },
                    suffixWidget: Padding(
                      padding: EdgeInsets.only(right: ResSize.w * 12),
                      child: Icon(
                        Icons.color_lens_outlined,
                        size: ResSize.h * 22,
                        color: AppColor.hintText,
                      ),
                    ),
                  ),
                  50.height,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return TextWidget(
      text: text,
      color: AppColor.title,
      fontSize: 16,
      fontWeight: fwMedium,
    );
  }
}

// Reusable dropdown field styled to match customTextfield
