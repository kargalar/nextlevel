import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

class StreakAnimationOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Shows a streak flame animation sliding from bottom to center with a longer haptic feedback.
  static void showStreakAnimation() {
    if (_isShowing) return;

    final overlayState = Get.key.currentState?.overlay;
    if (overlayState == null) return;

    _isShowing = true;

    // Trigger "dit dit" effect
    HapticFeedback.selectionClick();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.selectionClick();
    });

    // Create a sustained continuous heavy vibration (diiiiiiiiiiit)
    Future.delayed(const Duration(milliseconds: 300), () async {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 400); // 400ms duration block vibration
      }
    });

    _overlayEntry = OverlayEntry(
      builder: (context) => const _StreakAnimationWidget(),
    );

    overlayState.insert(_overlayEntry!);

    // Total visibility time is 0.7s, then remove overlay completely
    Future.delayed(const Duration(milliseconds: 700), () {
      hide();
    });
  }

  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }
}

class _StreakAnimationWidget extends StatefulWidget {
  const _StreakAnimationWidget();

  @override
  State<_StreakAnimationWidget> createState() => _StreakAnimationWidgetState();
}

class _StreakAnimationWidgetState extends State<_StreakAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Total duration: 0.7 seconds
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    // Slide from bottom (Takes 0.3s) using a "boing" effect (elasticOut)
    // 300ms is ~43% of the 700ms total duration
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 2.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.43, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10), // Ultra fast fade in at start
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45), // Stay visible (reaches center at ~w43)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 45), // Fade out in the last 0.4s
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Lottie.asset(
              'assets/animations/flame_streak.json',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              repeat: false,
            ),
          ),
        ),
      ),
    );
  }
}
