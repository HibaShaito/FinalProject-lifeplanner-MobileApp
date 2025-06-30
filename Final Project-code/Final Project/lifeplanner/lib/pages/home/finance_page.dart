// Imports
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';
import 'finance_history_page.dart';

// Enum for transaction type
enum TransactionType { income, expense }

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _editTitleCtrl = TextEditingController();
  final _editAmountCtrl = TextEditingController();

  double _startBalance = 0.0;
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  late final String _todayId;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayId = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final col = _firestore.collection('Users').doc(user.uid).collection('finance');

    final todayDoc = await col.doc(_todayId).get();

    if (todayDoc.exists) {
      final data = todayDoc.data()!;
      _startBalance = (data['startBalance'] as num?)?.toDouble() ?? 0.0;
      final raw = (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      _transactions = raw.map((e) => {
        'title': e['title'] ?? '',
        'amount': (e['amount'] as num).toDouble(),
        'type': e['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        'date': (e['date'] as Timestamp).toDate(),
      }).toList();
    } else {
      final now = DateTime.now();
      final todayTs = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
      final prevQ = await col.where('date', isLessThan: todayTs).orderBy('date', descending: true).limit(1).get();
      if (prevQ.docs.isNotEmpty) {
        _startBalance = (prevQ.docs.first.data()['endBalance'] as num?)?.toDouble() ?? 0.0;
      } else {
        _startBalance = 0.0;
      }
      _transactions = [];
    }

    setState(() {
      _balance = _startBalance + _computeNet(_transactions);
    });
  }

  double _computeNet(List<Map<String, dynamic>> txs) {
    double inc = 0, exp = 0;
    for (final t in txs) {
      final amt = (t['amount'] as num).toDouble();
      if (t['type'] == TransactionType.income) {
        inc += amt;
      } else {
        exp += amt;
      }
    }
    return inc - exp;
  }

  Future<void> _saveData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _firestore.collection('Users').doc(user.uid).collection('finance').doc(_todayId);

    final txList = _transactions.map((t) => {
      'title': t['title'],
      'amount': t['amount'],
      'type': t['type'] == TransactionType.income ? 'income' : 'expense',
      'date': Timestamp.fromDate((t['date'] as DateTime).toUtc()),
    }).toList();

    await ref.set({
      'date': Timestamp.fromDate(DateTime.now()),
      'startBalance': _startBalance,
      'endBalance': _balance,
      'transactions': txList,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _recomputeBalance() {
    setState(() => _balance = _startBalance + _computeNet(_transactions));
  }

  Future<void> _addTransaction(TransactionType type) async {
    final title = _titleCtrl.text.trim();
    final amt = double.tryParse(_amountCtrl.text);
    if (title.isEmpty || amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid title and amount')));
      return;
    }

    setState(() {
      _transactions.add({
        'title': title,
        'amount': amt,
        'type': type,
        'date': DateTime.now(),
      });
    });

    _titleCtrl.clear();
    _amountCtrl.clear();
    _recomputeBalance();
    await _saveData();
  }

  void _startEditing(int idx) {
    final t = _transactions[idx];
    _editTitleCtrl.text = t['title'];
    _editAmountCtrl.text = t['amount'].toString();
    setState(() => _editingIndex = idx);
  }

  Future<void> _finishEditing(int idx) async {
    final title = _editTitleCtrl.text.trim();
    final amt = double.tryParse(_editAmountCtrl.text);
    if (title.isEmpty || amt == null || amt <= 0) return;

    setState(() {
      _transactions[idx]['title'] = title;
      _transactions[idx]['amount'] = amt;
      _editingIndex = null;
    });

    _recomputeBalance();
    await _saveData();
  }

  Future<void> _deleteTransaction(int idx) async {
    setState(() => _transactions.removeAt(idx));
    _recomputeBalance();
    await _saveData();
  }

  Widget _buildTile(int idx) {
    final t = _transactions[idx];
    final isEdit = _editingIndex == idx;

    if (isEdit) {
      return ListTile(
        title: TextField(
          controller: _editTitleCtrl,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (_) => _finishEditing(idx),
        ),
        trailing: SizedBox(
          width: 100,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _editAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amt'),
                  onSubmitted: (_) => _finishEditing(idx),
                ),
              ),
              IconButton(icon: const Icon(Icons.check), onPressed: () => _finishEditing(idx)),
            ],
          ),
        ),
      );
    }

    final prefix = t['type'] == TransactionType.income ? '+ ' : '- ';
    return Dismissible(
      key: Key((t['date'] as DateTime).toIso8601String()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTransaction(idx),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: Icon(
          t['type'] == TransactionType.income ? Icons.arrow_upward : Icons.arrow_downward,
          color: t['type'] == TransactionType.income ? Colors.green : Colors.red,
        ),
        title: Text(t['title']),
        subtitle: Text((t['date'] as DateTime).toLocal().toString()),
        trailing: Text(
          '$prefix${(t['amount'] as double).toStringAsFixed(2)}',
          style: TextStyle(
            color: t['type'] == TransactionType.income ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onLongPress: () => _startEditing(idx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCD7D),
        title: const Text('My Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceHistoryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Tips',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('Tips'),
                content: Text('Long-press items to edit, swipe to delete. Tap ➕/➖.'),
              ),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Transaction", style: TextStyle(fontSize: 18)),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Amount'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: () => _addTransaction(TransactionType.income),
                ),
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.red),
                  onPressed: () => _addTransaction(TransactionType.expense),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Current Balance', style: TextStyle(fontSize: 18)),
            Text(
              '\$${_balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text("Today's Transactions", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (_, i) => _buildTile(i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _editTitleCtrl.dispose();
    _editAmountCtrl.dispose();
    super.dispose();
  }
}
