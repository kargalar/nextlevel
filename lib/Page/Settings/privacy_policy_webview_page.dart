import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/logging_service.dart';

class PrivacyPolicyWebViewPage extends StatefulWidget {
  const PrivacyPolicyWebViewPage({super.key});

  @override
  State<PrivacyPolicyWebViewPage> createState() =>
      _PrivacyPolicyWebViewPageState();
}

class _PrivacyPolicyWebViewPageState extends State<PrivacyPolicyWebViewPage> {
  late final WebViewController controller;

  final String privacyPolicyUrl =
      'https://kargalar.github.io/nextlevel_privacy2/privacy-policy/';

  @override
  void initState() {
    super.initState();
    LogService.debug('Privacy Policy WebView: Initializing controller');
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            LogService.debug(
                'Privacy Policy WebView: Loading progress: $progress%');
          },
          onPageStarted: (String url) {
            LogService.debug('Privacy Policy WebView: Started loading $url');
          },
          onPageFinished: (String url) {
            LogService.debug('Privacy Policy WebView: Finished loading $url');
          },
          onWebResourceError: (WebResourceError error) {
            LogService.error(
                'Privacy Policy WebView: Error loading page: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              LogService.debug(
                  'Privacy Policy WebView: Blocked navigation to YouTube');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(privacyPolicyUrl));
    LogService.debug(
        'Privacy Policy WebView: Controller initialized successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.PrivacyPolicy.tr()),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            NavigatorService().back();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
