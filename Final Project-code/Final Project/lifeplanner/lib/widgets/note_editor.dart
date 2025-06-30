import 'package:flutter/material.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:lifeplanner/services/note_service.dart';

class NoteEditorPage extends StatefulWidget {
  final String? noteId;
  final String? initialText;
  final Color? initialColor;

  const NoteEditorPage({
    super.key,
    this.noteId,
    this.initialText,
    this.initialColor,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _controller;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _selectedColor = widget.initialColor ?? Colors.yellow.shade100;
  }

  void _saveNote() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final notes = context.read<NoteService>();
      if (widget.noteId != null) {
        notes.updateNote(widget.noteId!, text, _selectedColor.toARGB32());
      } else {
        notes.addNote(text, _selectedColor.toARGB32());
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppBar(
        title: Text(widget.noteId != null ? "Edit Note" : "New Note"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveNote),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type your note...',
                  border: InputBorder.none,
                ),
              ),
            ),
            Row(
              children: [
                const Text('Color:'),
                const SizedBox(width: 8),
                DropdownButton<Color>(
                  value: _selectedColor,
                  items:
                      [
                        Colors.yellow.shade100,
                        Colors.green.shade100,
                        Colors.pink.shade100,
                        Colors.blue.shade100,
                        Colors.white,
                      ].map((color) {
                        return DropdownMenuItem(
                          value: color,
                          child: Container(width: 24, height: 24, color: color),
                        );
                      }).toList(),
                  onChanged: (newColor) {
                    if (newColor != null) {
                      setState(() => _selectedColor = newColor);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
