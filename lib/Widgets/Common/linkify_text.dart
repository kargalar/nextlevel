import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/logging_service.dart';

/// Reusable linkified text widget that makes URLs clickable
/// Can be used across the app for any text that might contain links
class LinkifyText extends StatelessWidget {
  const LinkifyText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  Future<void> _onLinkTap(LinkableElement link) async {
    final url = link.url;
    LogService.debug('🔗 Link tapped: $url');

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        LogService.debug('✅ Link opened successfully: $url');
      } else {
        LogService.error('❌ Could not launch URL: $url');
      }
    } catch (e) {
      LogService.error('❌ Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Linkify(
      onOpen: _onLinkTap,
      text: text,
      style: style,
      linkStyle: linkStyle ??
          TextStyle(
            color: AppColors.blue,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.blue,
          ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ?? TextAlign.start,
      options: const LinkifyOptions(
        humanize: true, // Removes http:// and https:// from display
        looseUrl: true,
        removeWww: true, // Also removes www. prefix
      ),
    );
  }
}
