import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

/// Notlar ve Projeler sayfaları için standart AppBar
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSearching;
  final VoidCallback onSearchToggle;
  final bool showArchivedOnly;
  final VoidCallback onArchiveToggle;

  const StandardAppBar({
    super.key,
    required this.title,
    required this.isSearching,
    required this.onSearchToggle,
    required this.showArchivedOnly,
    required this.onArchiveToggle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      elevation: 0,
      toolbarHeight: preferredSize.height,
      actions: [
        // Arama butonu
        IconButton(
          icon: Icon(
            isSearching ? Icons.search_off : Icons.search,
          ),
          tooltip: isSearching ? 'Close search' : 'Search',
          onPressed: onSearchToggle,
        ),
        // Arşiv butonu
        IconButton(
          icon: Icon(
            showArchivedOnly ? Icons.unarchive : Icons.archive,
            color: showArchivedOnly ? AppColors.orange : null,
          ),
          tooltip: showArchivedOnly ? 'Show active' : 'Show archived',
          onPressed: onArchiveToggle,
        ),
      ],
    );
  }
}
