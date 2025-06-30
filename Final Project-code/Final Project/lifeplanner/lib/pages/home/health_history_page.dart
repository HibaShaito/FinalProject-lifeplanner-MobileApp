import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';

class HealthHistoryPage extends StatelessWidget {
  const HealthHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return BaseScaffold(
        appBar: AppBar(
          title: const Text('History'),
          backgroundColor: const Color(0xFFFFD27F),
        ),
        child: const Center(
          child: Text('You must be signed in to see history.'),
        ),
      );
    }

    final col = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('healthData')
        .orderBy('timestamp', descending: true);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text('Health History'),
        backgroundColor: const Color(0xFFFFD27F),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: col.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No entries yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final ts = (d['timestamp'] as Timestamp).toDate();
              final dateStr = DateFormat.yMMMd().add_jm().format(ts);
              final water = d['waterIntake'] as int? ?? 0;
              final mood = d['mood'] as String? ?? '';
              final notes = d['notes'] as String? ?? '';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  dateStr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('💧 Water: $water'),
                    Text('😃 Mood: $mood'),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('📝 Notes: $notes'),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
