import 'package:flutter/material.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';
import 'package:lifeplanner/widgets/note_editor.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeplanner/services/note_service.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.read<NoteService>();

    return BaseScaffold(
      appBar: AppBar(title: const Text("My Notes")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditorPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: notes.streamNotes(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!;
          if (docs.isEmpty) {
            return const Center(child: Text('No notes yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final text = data['text'] as String;
              final ts = data['timestamp'] as Timestamp?;
              final colorValue = data['color'] as int? ?? 0xFFFFFFFF;
              final date =
                  ts != null
                      ? DateFormat.yMMMd().add_jm().format(ts.toDate())
                      : '';

              return Card(
                color: Color(colorValue),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => NoteEditorPage(
                              noteId: doc.id,
                              initialText: text,
                              initialColor: Color(colorValue),
                            ),
                      ),
                    );
                  },
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  subtitle:
                      date.isNotEmpty
                          ? Text(date, style: const TextStyle(fontSize: 12))
                          : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notes.deleteNote(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
