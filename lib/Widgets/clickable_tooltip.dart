import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/General/app_colors.dart';

// Aktif tooltip'i takip etmek için statik değişken
_ClickableTooltipState? _activeTooltip;

class ClickableTooltip extends StatefulWidget {
  final String titleKey;
  final List<String> bulletPoints;
  final Widget child;

  const ClickableTooltip({
    super.key,
    required this.titleKey,
    required this.bulletPoints,
    required this.child,
  });

  @override
  State<ClickableTooltip> createState() => _ClickableTooltipState();
}

class _ClickableTooltipState extends State<ClickableTooltip> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isTooltipVisible = false;

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isTooltipVisible = false;

    // Eğer bu tooltip aktif tooltip ise, aktif tooltip'i null yap
    if (_activeTooltip == this) {
      _activeTooltip = null;
    }
  }

  void _showTooltip(BuildContext context) {
    if (_isTooltipVisible) {
      _removeOverlay();
      return;
    }

    // Eğer başka bir tooltip açıksa onu kapat
    if (_activeTooltip != null && _activeTooltip != this) {
      _activeTooltip!._removeOverlay();
    }

    // Bu tooltip'i aktif tooltip olarak ayarla
    _activeTooltip = this;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Görünmez arka plan katmanı - tıklandığında tooltip'i kapatır
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _removeOverlay();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Tooltip içeriği
              Positioned(
                width: 250,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, size.height + 5),
                  child: GestureDetector(
                    onTap: () {
                      // Tooltip'e tıklandığında kapanmasını sağla
                      _removeOverlay();
                    },
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.panelBackground,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title with close button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.titleKey.tr(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                // Close button
                                GestureDetector(
                                  onTap: () {
                                    // Çarpı butonuna tıklandığında tooltip'i kapat
                                    _removeOverlay();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppColors.text.withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: AppColors.text.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Bullet points
                            ...widget.bulletPoints.map((point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "• ",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.text.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isTooltipVisible = true;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          _showTooltip(context);
        },
        child: widget.child,
      ),
    );
  }
}
