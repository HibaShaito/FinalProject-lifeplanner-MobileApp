import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';

class FinanceHistoryPage extends StatelessWidget {
  const FinanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const BaseScaffold(child: Center(child: Text('Not signed in')));
    }

    final financeColl = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('finance')
        .orderBy('date', descending: true);

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCD7D),
        title: const Text('Finance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'History Tips',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('History Tips'),
                      content: const Text(
                        '💡 Tips for Finance History:\n\n'
                        '- Tap any entry to see that day’s transactions.\n'
                        '- Offline‑first enabled: changes sync when back online.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: financeColl.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No finance history available.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data()! as Map<String, dynamic>;

              // Convert Timestamp → DateTime if needed
              final rawDate = data['date'];
              final date =
                  (rawDate is Timestamp)
                      ? rawDate.toDate()
                      : rawDate as DateTime;
              final formattedDate = DateFormat(
                'yyyy-MM-dd',
              ).format(date.toLocal());

              final startBalance =
                  (data['startBalance'] as num?)?.toDouble() ?? 0.0;
              final endBalance =
                  (data['endBalance'] as num?)?.toDouble() ?? startBalance;

              final transactions = List<Map<String, dynamic>>.from(
                data['transactions'] ?? [],
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Start: \$${startBalance.toStringAsFixed(2)} → End: \$${endBalance.toStringAsFixed(2)}',
                  ),
                  trailing: Text('${transactions.length} transactions'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: Text('Transactions for $formattedDate'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView(
                              shrinkWrap: true,
                              children:
                                  transactions.map((t) {
                                    final tDateRaw = t['date'];
                                    final tDate =
                                        (tDateRaw is Timestamp)
                                            ? tDateRaw.toDate()
                                            : tDateRaw as DateTime;
                                    final formattedTDate = DateFormat(
                                      'yyyy-MM-dd HH:mm',
                                    ).format(tDate.toLocal());

                                    return ListTile(
                                      title: Text(t['title']),
                                      subtitle: Text(formattedTDate),
                                      trailing: Text(
                                        '${t['type'] == 'income' ? '+' : '-'}\$${(t['amount'] as num).toStringAsFixed(2)}',
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
