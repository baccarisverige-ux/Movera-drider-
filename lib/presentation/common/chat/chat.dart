import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/common/chat/components/appbar.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/custom_textfield.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _messageController = TextEditingController();

  final List<Widget> _messages = [];
  bool showSendIcon = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        showSendIcon = _messageController.text.isNotEmpty;
      });
    });
  }

  // Function to send message
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return; // Don't send if text is empty
    }

    if (_messages.length.isEven) {
      _messages.add(SenderMessage(text: _messageController.text));
    } else {
      _messages.add(ReceiverMessage(text: _messageController.text));
    }
    setState(() {});
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResSize.h * 75),
        child: ChatAppBar(),
      ),
      body: SizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            12.height,
            Expanded(
              child: StatefulBuilder(
                builder: (context, i) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _messages,
                    ),
                  );
                },
              ),
            ),
            Container(
              height: ResSize.h * 100,
              width: double.infinity,
              color: AppColor.white,
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: ResSize.h * 48,
                    child: Row(
                      children: [
                        Expanded(
                          child: customTextfield(
                            borderColor: Colors.transparent,
                            borderWidth: 0,
                            textColor: AppColor.black,
                            controller: _messageController,
                            fontSize: 14,
                            hint: "send message...",
                            fillColor: Color(0xffF6F6F6),
                            borderRadius: 32,
                            hintTextColor: Color(0xff969696),
                            contentHorizPadding: 14,
                            contentVertPadding: 14,
                            // suffixWidget: InkWell(
                            //   onTap: showSendIcon
                            //       ? _sendMessage
                            //       : null, // Only work when showSendIcon is true
                            //   child: Container(
                            //     margin: EdgeInsets.only(right: ResSize.w * 8),
                            //     height: ResSize.h * 35,
                            //     width: ResSize.w * 42,
                            //     decoration: BoxDecoration(
                            //       borderRadius: BorderRadius.circular(8),
                            //       color: AppColor.primary,
                            //     ),
                            //     child: Center(
                            //       child: Padding(
                            //         padding: const EdgeInsets.all(12.0),
                            //         child: Image.asset(
                            //           AppAssets.send,
                            //           color: Colors.white,
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ),
                        ),
                        10.width,
                        Container(
                          height: ResSize.h * 48,
                          width: ResSize.w * 48,
                          decoration: BoxDecoration(
                            color: Color(0xffF6F6F6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: InkWell(
                              onTap: showSendIcon ? _sendMessage : null,
                              child: Padding(
                                padding: EdgeInsets.all(ResSize.w * 12),
                                child: Image.asset(AppAssets.send),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class SenderMessage extends StatefulWidget {
  late String text;

  SenderMessage({super.key, required this.text});

  @override
  State<SenderMessage> createState() => _SenderMessageState();
}

class _SenderMessageState extends State<SenderMessage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: ResSize.h * 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: ResSize.h * 32,
                width: ResSize.w * 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(AppAssets.chatProf1),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              8.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 80),
                      padding: EdgeInsets.only(
                        left: ResSize.w * 8,
                        right: ResSize.w * 8,
                        top: ResSize.h * 8,
                        bottom: ResSize.h * 16,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xffF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextWidget(
                        text: widget.text,
                        fontSize: 14,
                        color: AppColor.title,
                        fontWeight: fwNormal,
                      ),
                    ),
                    5.height,
                    TextWidget(
                      text: "10:00 AM",
                      color: Color(0xff858F94),
                      fontSize: 12,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReceiverMessage extends StatefulWidget {
  final String text;
  const ReceiverMessage({super.key, required this.text});

  @override
  State<ReceiverMessage> createState() => _ReceiverMessageState();
}

class _ReceiverMessageState extends State<ReceiverMessage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(top: ResSize.h * 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 80),
                      padding: EdgeInsets.only(
                        left: ResSize.w * 8,
                        right: ResSize.w * 8,
                        top: ResSize.h * 8,
                        bottom: ResSize.h * 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextWidget(
                        text: widget.text,
                        color: AppColor.whiteText,
                        fontSize: 14,
                        fontWeight: fwNormal,
                      ),
                    ),
                    5.height,
                    TextWidget(
                      text: "10:00 AM",
                      color: Color(0xff858F94),
                      fontSize: 12,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
              8.width,
              Container(
                height: ResSize.h * 32,
                width: ResSize.w * 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(AppAssets.chatProf2),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
