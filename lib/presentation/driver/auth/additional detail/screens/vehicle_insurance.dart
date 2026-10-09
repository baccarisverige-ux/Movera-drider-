import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'vehicle_document_upload.dart';

class AdditionDetailVehicleInsurance extends StatelessWidget {
  const AdditionDetailVehicleInsurance({
    super.key,
    required this.circleProgress,
    this.selectFile,
    this.capturePhoto,
  });
  final Widget Function(int, int) circleProgress;
  final Future<PlatformFile?> Function()? selectFile;
  final Future<XFile?> Function()? capturePhoto;

  @override
  Widget build(BuildContext context) => VehicleDocumentUpload(
    title: 'Insurance',
    subtitle: 'Upload car insurance for verification',
    progressIndex: 2,
    circleProgress: circleProgress,
    selectFile: selectFile,
    capturePhoto: capturePhoto,
  );
}
