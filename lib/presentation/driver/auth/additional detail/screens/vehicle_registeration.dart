import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'vehicle_document_upload.dart';

class AdditionDetailVehicleRegisteration extends StatelessWidget {
  const AdditionDetailVehicleRegisteration({
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
    title: 'Vehicle Registration',
    subtitle: 'Upload vehicle registration document',
    progressIndex: 1,
    circleProgress: circleProgress,
    selectFile: selectFile,
    capturePhoto: capturePhoto,
  );
}
