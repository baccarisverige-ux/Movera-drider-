// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class AccountActivationDialog extends StatefulWidget {
  final VoidCallback onAccountActivated;
  final VoidCallback? onCancel;
  final int delaySeconds;
  const AccountActivationDialog({
    super.key,
    required this.onAccountActivated,
    this.onCancel,
    this.delaySeconds = 3,
  });

  @override
  State<AccountActivationDialog> createState() =>
      _AccountActivationDialogState();

  /// Static method to show the dialog
  static Future<bool?> show(
    BuildContext context, {
    required VoidCallback onAccountActivated,
    VoidCallback? onCancel,
    int delaySeconds = 3,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AccountActivationDialog(
          onAccountActivated: onAccountActivated,
          onCancel: onCancel,
          delaySeconds: delaySeconds,
        );
      },
    );
  }
}

class _AccountActivationDialogState extends State<AccountActivationDialog> {
  bool isContacting = false;

  Future<void> _contactSupport() async {
    setState(() {
      isContacting = true;
    });

    // Simulate API call delay
    await Future.delayed(Duration(seconds: widget.delaySeconds));

    setState(() {
      isContacting = false;
    });

    // Close dialog and trigger callback
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop(true);
    widget.onAccountActivated();
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(ResSize.w * 24),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              height: ResSize.h * 80,
              width: ResSize.w * 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.1),
              ),
              child: Icon(
                Icons.pending_actions_rounded,
                size: ResSize.h * 40,
                color: Colors.orange,
              ),
            ),

            20.height,

            // Title
            TextWidget(
              text: "Account Activation Required",
              fontSize: 20,
              fontWeight: fwBold,
              color: AppColor.title,
              textAlign: TextAlign.center,
            ),

            12.height,

            // Description
            TextWidget(
              text:
                  "Your driver account is currently under review. Please contact our support team to complete the activation process.",
              fontSize: 14,
              fontWeight: fwNormal,
              color: AppColor.subtitle,
              textAlign: TextAlign.center,
            ),
            30.height,
            // Contact Support Button
            SizedBox(
              width: double.infinity,
              height: ResSize.h * 50,
              child: ElevatedButton(
                onPressed: isContacting ? null : _contactSupport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.title,
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isContacting
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColor.white,
                              ),
                            ),
                          ),
                          12.width,
                          TextWidget(
                            text: "Contacting Support...",
                            fontSize: 16,
                            fontWeight: fwMedium,
                            color: AppColor.white,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.support_agent_rounded,
                            size: 20,
                            color: AppColor.white,
                          ),
                          8.width,
                          TextWidget(
                            text: "Contact Support",
                            fontSize: 16,
                            fontWeight: fwMedium,
                            color: AppColor.white,
                          ),
                        ],
                      ),
              ),
            ),

            12.height,

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: ResSize.h * 50,
              child: TextButton(
                onPressed: isContacting ? null : _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.subtitle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColor.subtitle.withOpacity(0.3)),
                  ),
                ),
                child: TextWidget(
                  text: "Cancel",
                  fontSize: 16,
                  fontWeight: fwMedium,
                  color: AppColor.subtitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
