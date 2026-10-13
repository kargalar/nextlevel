import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Widgets/Notes/note_card.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Widgets/add_edit_item_bottom_sheet.dart';
import 'package:next_level/Widgets/Common/category_filter_widget.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Widgets/Common/standard_app_bar.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Page/Notes/note_description_editor.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

/// Notlar ana sayfası
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında notları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        context.read<NavbarProvider>().goToMainPage();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: StandardAppBar(
          title: LocaleKeys.MyNotes.tr(),
          isSearching: _isSearching,
          onSearchToggle: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                provider.clearSearchQuery();
              }
            });
            LogService.debug('🔍 Search toggled: $_isSearching');
          },
          showArchivedOnly: provider.showArchivedOnly,
          onArchiveToggle: () {
            provider.toggleArchivedFilter();
            LogService.debug(
                '📦 Archive filter toggled: ${provider.showArchivedOnly}');
          },
        ),
        body: Consumer<NotesProvider>(
          builder: (context, provider, _) {
            // Yükleniyor
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Hata
            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadNotes(),
                      icon: const Icon(Icons.refresh),
                      label: Text(LocaleKeys.Retry.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.main,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Inline arama barı (arama aktifse göster)
                if (_isSearching)
                  Container(
                    height: 40,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) {
                        provider.updateSearchQuery(value);
                        LogService.debug('🔍 Search query: $value');
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: LocaleKeys.SearchNotes.tr(),
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.text.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.text.withValues(alpha: 0.5),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: AppColors.text.withValues(alpha: 0.5),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.clearSearchQuery();
                                  LogService.debug('🔍 Search cleared');
                                },
                              )
                            : null,
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 0),
                        isDense: true,
                      ),
                    ),
                  ),

                // Kategori filtreleme
                CategoryFilterWidget(
                  categories: provider.categories,
                  selectedCategoryId: provider.selectedCategoryId,
                  onCategorySelected: (categoryId) =>
                      provider.selectCategory(categoryId as String?),
                  itemCounts: provider.noteCounts,
                  onCategoryLongPress: (context, category) async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      builder: (context) =>
                          CreateCategoryBottomSheet(categoryModel: category),
                    );

                    // Kategori güncellendiyse veya silindiyse, provider'ı güncelle
                    if (result != null && context.mounted) {
                      await provider.loadData();
                    }
                  },
                  onCategoryAdded: () async {
                    // Yeni kategori eklendikten sonra kategorileri yeniden yükle
                    await provider.loadData();
                  },
                  categoryType: CategoryType.note,
                  showEmptyCategories: true, // Boş kategorileri de göster
                ),
                const SizedBox(height: 8),
                // Notlar listesi
                Expanded(
                  child: _buildNotesList(context, provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, NotesProvider provider) {
    final pinnedNotes = provider.pinnedNotes;
    final unpinnedNotes = provider.unpinnedNotes;

    if (provider.filteredNotes.isEmpty) {
      final message = provider.showArchivedOnly
          ? LocaleKeys.NoArchivedNotes.tr()
          : LocaleKeys.NoteNotFound.tr();
      LogService.debug(
          '📝 NotesPage: No notes found. Archived filter: ${provider.showArchivedOnly}, Message: $message');
      return AppEmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: message,
        description: 'Create a note to keep your ideas close at hand.',
        color: AppColors.purple,
      );
    }

    return ListView(
      children: [
        // Sabitlenmiş notlar
        if (pinnedNotes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: AppColors.grey),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.Pinned.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          _buildReorderableNotesList(
            context,
            provider,
            pinnedNotes,
            isPinnedList: true,
          ),
        ],

        // Diğer notlar
        if (unpinnedNotes.isNotEmpty) ...[
          if (pinnedNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                LocaleKeys.OtherNotes.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey,
                ),
              ),
            ),
          _buildReorderableNotesList(
            context,
            provider,
            unpinnedNotes,
            isPinnedList: false,
          ),
        ],

        const SizedBox(height: 80), // FAB için boşluk
      ],
    );
  }

  /// Sürüklenebilir notlar listesi
  Widget _buildReorderableNotesList(
      BuildContext context, NotesProvider provider, List<NoteModel> notes,
      {required bool isPinnedList}) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false, // Varsayılan handle icon'unu kaldır
      proxyDecorator: (child, index, animation) {
        // Sürükleme sırasında kartın görünümünü özelleştir
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final animValue = Curves.easeInOut.transform(animation.value);
            final scale = 1.0 + (animValue * 0.05); // Hafif büyütme efekti
            final elevation = animValue * 8.0; // Hafif gölge efekti

            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: elevation,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      itemCount: notes.length,
      onReorderItem: (oldIndex, newIndex) async {
        LogService.debug('🔄 Reordering note from $oldIndex to $newIndex');

        await provider.reorderNotes(
          oldIndex: oldIndex,
          newIndex: newIndex,
          isPinnedList: isPinnedList,
        );
      },
      itemBuilder: (context, index) {
        final note = notes[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(note.id),
          index: index,
          child: _buildNoteCard(context, provider, note),
        );
      },
    );
  }

  Widget _buildNoteCard(
      BuildContext context, NotesProvider provider, NoteModel note) {
    return NoteCard(
      note: note,
      onTap: () => _navigateToNoteDescriptionEditor(context, note),
      onEdit: () => _navigateToEditNote(context, note),
      onDelete: () => _confirmDelete(context, provider, note),
    );
  }

  void _confirmDelete(
      BuildContext context, NotesProvider provider, NoteModel note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.DeleteNote.tr()),
          content: Text(LocaleKeys.DeleteNoteConfirmation.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.deleteNote(note.id);
                Helper().getMessage(
                  message: LocaleKeys.NoteDeleted.tr(),
                  status: StatusEnum.SUCCESS,
                );
                LogService.debug('✅ Note ${note.id} deleted');
              },
              child: Text(LocaleKeys.Delete.tr(),
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditNote(BuildContext context, NoteModel note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditItemBottomSheet(
        type: ItemType.note,
        item: note,
      ),
    );
  }

  void _navigateToNoteDescriptionEditor(BuildContext context, NoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDescriptionEditor(note: note),
      ),
    );
    LogService.debug(
        '📝 Navigating to note description editor for note: ${note.id}');
  }
}
