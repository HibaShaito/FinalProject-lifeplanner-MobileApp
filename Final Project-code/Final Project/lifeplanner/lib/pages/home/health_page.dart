import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeplanner/pages/home/health_history_page.dart';
import 'package:lifeplanner/utils/network_status_service.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';
import 'package:provider/provider.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  bool _isSaving = false;
  int waterIntake = 0;
  String mood = "😊";
  final _notesController = TextEditingController();
  final List<String> moods = ["😊", "😐", "😢", "😡"];

  @override
  void initState() {
    super.initState();
    _loadTodayEntry();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final docId = "${now.year}-${now.month}-${now.day}";

    final doc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('healthData')
            .doc(docId)
            .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          waterIntake = data['waterIntake'] as int? ?? 0;
          mood = data['mood'] as String? ?? mood;
          _notesController.text = data['notes'] as String? ?? "";
        });
      }
    }
  }

  Future<void> _saveHealthData() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    final isOnline =
        Provider.of<NetworkStatusNotifier>(context, listen: false).isOnline;
    final now = DateTime.now();
    final docId = "${now.year}-${now.month}-${now.day}";

    final data = {
      'waterIntake': waterIntake,
      'mood': mood,
      'notes': _notesController.text.trim(),
      'timestamp': Timestamp.fromDate(now),
    };

    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('healthData')
        .doc(docId);

    try {
      await docRef.set(data, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline
                  ? 'Health data saved!'
                  : 'Saved offline. Will sync when online.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppBar(
        title: const Text("My Health"),
        backgroundColor: const Color(0xFFFFD27F),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Health Tracker Help'),
                        content: const Text(
                          'Adjust your water intake with the – and + buttons.\n'
                          'Tap an emoji to set your mood.\n'
                          'Use “Notes” to jot anything extra.\n'
                          'Save once per day; edits overwrite today’s entry.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                ),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCard(
                      title: "Water Intake",
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed:
                                () => setState(() {
                                  if (waterIntake > 0) waterIntake--;
                                }),
                          ),
                          Text(
                            "$waterIntake",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => waterIntake++),
                          ),
                          const SizedBox(width: 12),
                          const Text("glasses", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: "Mood",
                      child: Wrap(
                        spacing: 10,
                        children:
                            moods.map((m) {
                              final selected = m == mood;
                              return ChoiceChip(
                                label: Text(
                                  m,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                selected: selected,
                                onSelected: (_) => setState(() => mood = m),
                                selectedColor: Colors.orange.shade200,
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: "Notes",
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Any extra thoughts for today…",
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveHealthData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isSaving ? Colors.grey.shade400 : Colors.black87,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save),
                                  SizedBox(width: 8),
                                  Text("Save Today’s Entry"),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCard({required String title, required Widget child}) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
