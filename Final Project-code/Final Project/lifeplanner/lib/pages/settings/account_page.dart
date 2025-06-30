import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeplanner/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:lifeplanner/utils/network_status_service.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
    }
  }

  Future<void> _updateDisplayName() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_displayNameController.text.trim());
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
          'displayName': _displayNameController.text.trim(),
        }, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Display name updated')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text('Are you sure? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await _authService.deleteAccount();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<NetworkStatusNotifier>().isOnline;

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCD7D),
        elevation: 0,
        title: const Text('Account', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: AbsorbPointer(
                    absorbing: !isOnline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _displayNameController,
                                    enabled: isOnline,
                                    decoration: const InputDecoration(
                                      labelText: 'Display Name',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    validator: (val) {
                                      final trimmed = val?.trim() ?? '';
                                      if (trimmed.isEmpty) {
                                        return 'Enter a name';
                                      }
                                      if (trimmed.length < 3 ||
                                          trimmed.length > 30) {
                                        return 'Name must be 3–30 chars';
                                      }
                                      final regex = RegExp(
                                        r'^[a-zA-Z0-9 _.\-]+$',
                                      );
                                      if (!regex.hasMatch(trimmed)) {
                                        return 'Only letters, nums, spaces, . _ -';
                                      }
                                      final blocked = [
                                        'admin',
                                        'support',
                                        'moderator',
                                        'system',
                                        'noreply',
                                      ];
                                      if (blocked.contains(
                                        trimmed.toLowerCase(),
                                      )) {
                                        return 'Name not allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed:
                                        isOnline ? _updateDisplayName : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFCD7D),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                enabled: isOnline,
                                leading: const Icon(Icons.logout),
                                title: const Text('Log Out'),
                                onTap: isOnline ? _logout : null,
                              ),
                              const Divider(height: 1),
                              ListTile(
                                enabled: isOnline,
                                leading: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Delete Account',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: isOnline ? _deleteAccount : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
