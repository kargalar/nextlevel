import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

/// A horizontally scrolling 2-row grid of icons for picking a category icon.
class IconPickerGrid extends StatelessWidget {
  final IconData selectedIcon;
  final Color accentColor;
  final ValueChanged<IconData> onIconSelected;

  const IconPickerGrid({
    super.key,
    required this.selectedIcon,
    required this.accentColor,
    required this.onIconSelected,
  });

  static const List<IconData> _icons = [
    Icons.category,
    Icons.work,
    Icons.home,
    Icons.school,
    Icons.shopping_cart,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.flight,
    Icons.beach_access,
    Icons.music_note,
    Icons.movie,
    Icons.sports_soccer,
    Icons.pets,
    Icons.favorite,
    Icons.star,
    Icons.lightbulb,
    Icons.palette,
    Icons.code,
    Icons.computer,
    Icons.phone,
    Icons.email,
    Icons.chat,
    Icons.notifications,
    Icons.calendar_today,
    Icons.event,
    Icons.alarm,
    Icons.access_time,
    Icons.attach_money,
    Icons.account_balance,
    Icons.credit_card,
    Icons.local_hospital,
    Icons.medical_services,
    Icons.healing,
    Icons.directions_car,
    Icons.directions_bike,
    Icons.directions_bus,
    Icons.train,
    Icons.local_shipping,
    Icons.book,
    Icons.menu_book,
    Icons.library_books,
    Icons.article,
    Icons.description,
    Icons.folder,
    Icons.folder_open,
    Icons.insert_drive_file,
    Icons.cloud,
    Icons.cloud_upload,
    Icons.cloud_download,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          final icon = _icons[index];
          final isSelected = selectedIcon.codePoint == icon.codePoint;
          return _IconCell(
            icon: icon,
            isSelected: isSelected,
            accentColor: accentColor,
            onTap: () => onIconSelected(icon),
          );
        },
      ),
    );
  }
}

class _IconCell extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _IconCell({
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.25),
                    accentColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.panelBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor.withValues(alpha: 0.6) : AppColors.panelBackground2.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? accentColor : AppColors.text.withValues(alpha: 0.5),
          size: isSelected ? 24 : 20,
        ),
      ),
    );
  }
}
