import 'package:flutter/material.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Widgets/Common/description_editor.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';

/// Note description editor page
/// Opens when user taps on a note card
class NoteDescriptionEditor extends StatefulWidget {
  const NoteDescriptionEditor({
    super.key,
    required this.note,
  });

  final NoteModel note;

  @override
  State<NoteDescriptionEditor> createState() => _NoteDescriptionEditorState();
}

class _NoteDescriptionEditorState extends State<NoteDescriptionEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.content);
    _focusNode = FocusNode();

    LogService.debug('📝 Note description editor opened for note: ${widget.note.id}');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _autoSave(String text) {
    // Update the note's content
    final updatedNote = widget.note.copyWith(
      content: text.isNotEmpty ? text : null,
    );

    // Update provider (this will also save to database via NotesService)
    context.read<NotesProvider>().updateNote(updatedNote);

    LogService.debug('✅ Note content auto-saved: ${text.length} characters');
  }

  @override
  Widget build(BuildContext context) {
    return DescriptionEditor(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _autoSave,
      title: widget.note.title,
    );
  }
}
