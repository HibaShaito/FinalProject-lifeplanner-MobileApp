import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';

class ViewTaskPage extends StatefulWidget {
  final String taskId;
  final bool isRepeated;
  final String? occurrenceId;

  const ViewTaskPage({
    super.key,
    required this.taskId,
    required this.isRepeated,
    this.occurrenceId,
  });

  @override
  State<ViewTaskPage> createState() => _ViewTaskPageState();
}

class _ViewTaskPageState extends State<ViewTaskPage> {
  late Future<Map<String, dynamic>?> _taskFuture;

  @override
  void initState() {
    super.initState();
    _taskFuture = _fetchTaskData();
  }

  Future<Map<String, dynamic>?> _fetchTaskData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final taskRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Tasks')
        .doc(widget.taskId);

    final parentSnap = await taskRef.get();
    if (!parentSnap.exists) return null;

    final parentData = parentSnap.data()!;
    if (!widget.isRepeated || widget.occurrenceId == null) {
      return parentData;
    }

    final occSnap =
        await taskRef.collection('Occurrences').doc(widget.occurrenceId).get();

    return {...parentData, 'occurrenceData': occSnap.data()};
  }

  Future<void> _toggleCompletion(bool currentlyComplete) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final taskRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Tasks')
        .doc(widget.taskId);

    if (widget.isRepeated && widget.occurrenceId != null) {
      await taskRef.collection('Occurrences').doc(widget.occurrenceId).update({
        'completed': !currentlyComplete,
      });
    } else {
      await taskRef.update({'isComplete': !currentlyComplete});
    }

    setState(() {
      _taskFuture = _fetchTaskData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD27F),
        title: const Text(
          'Task Details',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 2,
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Task not found.'));
          }

          final data = snapshot.data!;
          final title = data['title'] ?? 'No title';
          final description = data['description'] ?? 'No description';
          final category = data['category'] ?? 'No category';
          final colorHex = data['color'];
          final color =
              colorHex != null
                  ? Color(
                    int.parse(colorHex.substring(1), radix: 16) | 0xFF000000,
                  )
                  : Colors.grey;

          final occurrence = data['occurrenceData'] ?? {};
          final completed =
              widget.isRepeated
                  ? (occurrence['completed'] ?? false)
                  : (data['isComplete'] ?? false);
          final reminderDateRaw =
              widget.isRepeated
                  ? occurrence['reminderDate'] as Timestamp?
                  : data['reminderDate'] as Timestamp?;

          final reminderTimeMap =
              widget.isRepeated
                  ? occurrence['reminderTime'] as Map<String, dynamic>?
                  : data['reminderTime'] as Map<String, dynamic>?;

          DateTime? reminderDateTime;
          if (reminderDateRaw != null && reminderTimeMap != null) {
            final date = reminderDateRaw.toDate();
            final hour = reminderTimeMap['hour'] ?? 0;
            final minute = reminderTimeMap['minute'] ?? 0;
            reminderDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              hour,
              minute,
            );
          }

          String? formattedReminder;
          if (reminderDateTime != null) {
            formattedReminder =
                "${reminderDateTime.day.toString().padLeft(2, '0')}/${reminderDateTime.month.toString().padLeft(2, '0')}/${reminderDateTime.year} at ${reminderDateTime.hour.toString().padLeft(2, '0')}:${reminderDateTime.minute.toString().padLeft(2, '0')}";
          }

          // --- ADD START DATE & TIME PARSING HERE ---

          final startDateRaw =
              widget.isRepeated
                  ? occurrence['startDate'] as Timestamp?
                  : data['startDate'] as Timestamp?;

          String? formattedStart;

          if (startDateRaw != null) {
            final date = startDateRaw.toDate();

            if (widget.isRepeated) {
              // For repeated occurrences, startDate includes time too
              formattedStart =
                  "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
            } else {
              final startTimeMap = data['startTime'] as Map<String, dynamic>?;

              if (startTimeMap != null) {
                final hour = startTimeMap['hour'] ?? 0;
                final minute = startTimeMap['minute'] ?? 0;
                formattedStart =
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
              } else {
                formattedStart =
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoCard('📝 Title', title),
                _buildInfoCard('🗒 Description', description),
                _buildInfoCard('📂 Category', category),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: const Text(
                      '🎨 Color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: CircleAvatar(backgroundColor: color),
                  ),
                ),
                if (formattedReminder != null)
                  _buildInfoCard('⏰ Reminder', formattedReminder),
                if (formattedStart != null)
                  _buildInfoCard('📅 Start Date', formattedStart),
                _buildInfoCard('✅ Completed', completed ? 'Yes' : 'No'),
                const SizedBox(height: 20),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton.icon(
                    key: ValueKey(completed),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor:
                          completed ? Colors.grey[400] : Colors.green[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                    icon: Icon(completed ? Icons.undo : Icons.check),
                    label: Text(
                      completed ? 'Undo Completion' : 'Mark as Complete',
                    ),
                    onPressed: () => _toggleCompletion(completed),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
