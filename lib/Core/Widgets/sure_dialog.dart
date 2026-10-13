import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class CustomDialogWidget extends StatefulWidget {
  final String? title;
  final String contentText;
  final bool withTimer;
  final Function? onAccept;
  final String? acceptButtonText;

  const CustomDialogWidget({
    super.key,
    this.title,
    required this.contentText,
    this.withTimer = false,
    required this.onAccept,
    this.acceptButtonText,
  });

  @override
  State<CustomDialogWidget> createState() => _CustomDialogWidgetState();
}

class _CustomDialogWidgetState extends State<CustomDialogWidget> {
  // Texts
  final String _acceptButton = LocaleKeys.Okay.tr();
  final String _title = LocaleKeys.Warning.tr();
  final String _declineButton = LocaleKeys.No.tr();

  int count = 2;
  late bool withTimer = widget.withTimer;
  // default accept button text
  late String acceptButtonText = widget.acceptButtonText ?? _acceptButton;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    while (count > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          count--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? _title),
      content: Text(widget.contentText),
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: AppColors.grey,
        ),
        borderRadius: AppColors.borderRadiusAll,
      ),
      actions: [
        if (widget.onAccept == null) ...[
          okeyButton(),
        ] else ...[
          cancelButton(),
          withTimer && count > 0 ? timer() : acceptButton()
        ]
      ],
    );
  }

  Text timer() {
    return Text(
      '$_acceptButton $count',
      style: const TextStyle(
        color: AppColors.dirtyWhite,
      ),
    );
  }

  TextButton okeyButton() {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: AppColors.transparent,
      ),
      onPressed: () {
        Get.back();
      },
      child: Text(LocaleKeys.Okay.tr()),
    );
  }

  TextButton cancelButton() {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: AppColors.transparent,
      ),
      onPressed: () {
        Get.back();
      },
      child: Text(_declineButton),
    );
  }

  ElevatedButton acceptButton() {
    return ElevatedButton(
      onPressed: () {
        Get.back();

        if (widget.onAccept != null) {
          widget.onAccept!();
        }
      },
      child: Text(
        acceptButtonText,
        style: const TextStyle(
          color: AppColors.white,
        ),
      ),
    );
  }
}
