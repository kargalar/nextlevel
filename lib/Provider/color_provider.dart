import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';

class ColorProvider extends ChangeNotifier {
  // Available colors for selection
  static const List<Color> availableColors = [
    Color(0xFF6C7CFF), // Indigo
    Color(0xFF3D9BE9), // Blue
    Color(0xFF10A883), // Teal
    Color(0xFF4BAA4F), // Green
    Color(0xFFE28743), // Orange
    Color(0xFFE65369), // Red
    Color(0xFFD657A5), // Pink
    Color(0xFF9A72E8), // Purple
  ];

  Color _currentColor = availableColors[0];

  Color get currentColor => _currentColor;

  // Load saved color from SharedPreferences
  Future<void> loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColorValue = prefs.getInt('main_color');

    if (savedColorValue != null) {
      final savedColor = Color(savedColorValue);
      // Check if the saved color is in our available colors
      if (availableColors.contains(savedColor)) {
        _currentColor = savedColor;
        AppColors.main = _currentColor;
        AppColors.lightMain = _getLightVariant(_currentColor);
        AppColors.deepMain = _getDarkVariant(_currentColor);
        AppColors.dirtyMain = _getDirtyVariant(_currentColor);
        notifyListeners();
      }
    }
  }

  Future<void> changeColor(Color newColor) async {
    _currentColor = newColor;

    // Update all main color variants in AppColors
    AppColors.main = newColor;
    AppColors.lightMain = _getLightVariant(newColor);
    AppColors.deepMain = _getDarkVariant(newColor);
    AppColors.dirtyMain = _getDirtyVariant(newColor);

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // ignore: deprecated_member_use
    await prefs.setInt('main_color', newColor.value);

    LogService.debug('ColorProvider: Color changed successfully. New color value: ${newColor.toARGB32}');
    notifyListeners();
  }

  // Generate lighter variant of the color
  Color _getLightVariant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
  }

  // Generate darker variant of the color
  Color _getDarkVariant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }

  // Generate dirty variant of the color
  Color _getDirtyVariant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation((hsl.saturation - 0.1).clamp(0.0, 1.0)).withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  String getColorName(Color color) {
    if (color == availableColors[0]) return 'Indigo';
    if (color == availableColors[1]) return 'Blue';
    if (color == availableColors[2]) return 'Teal';
    if (color == availableColors[3]) return 'Green';
    if (color == availableColors[4]) return 'Orange';
    if (color == availableColors[5]) return 'Red';
    if (color == availableColors[6]) return 'Pink';
    if (color == availableColors[7]) return 'Purple';
    return 'Custom';
  }
}
