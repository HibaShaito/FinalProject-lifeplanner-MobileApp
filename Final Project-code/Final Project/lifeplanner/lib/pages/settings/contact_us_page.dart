import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lifeplanner/utils/network_status_service.dart';
import 'package:lifeplanner/widgets/base_scaffold.dart';
import 'package:provider/provider.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  /// Navigation route helper
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (_) => const ContactUsPage());

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  String deviceId = 'Unknown';
  bool isSubmitting = false;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
  }

  void _checkInitialConnectivity() async {
    final status = await Connectivity().checkConnectivity();
    setState(() {
      isOffline = status.contains(ConnectivityResult.none);
    });
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      setState(() {
        isOffline = results.contains(ConnectivityResult.none);
      });
    });
  }

  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    setState(() {
      deviceId = androidInfo.id;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    final now = DateTime.now();
    final messagesRef = FirebaseFirestore.instance
        .collection('Contact')
        .doc(deviceId)
        .collection('messages');

    try {
      // rate‑limit check on the same collection
      final lastQuery =
          await messagesRef
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (lastQuery.docs.isNotEmpty) {
        final lastSent = lastQuery.docs.first['timestamp'].toDate();
        if (now.difference(lastSent).inMinutes < 2) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please wait a few minutes before sending another message.',
              ),
            ),
          );
          setState(() => isSubmitting = false);
          return;
        }
      }

      // actually add the new message
      await messagesRef.add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'message': _messageController.text.trim(),
        'deviceId': deviceId,
        'timestamp': now,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully!')),
      );
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<NetworkStatusNotifier>().isOnline == false;

    return BaseScaffold(
      appBar: AppBar(
        title: const Text("Contact Us"),
        backgroundColor: const Color(0xFFFFC774),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOffline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: const [
                      Icon(Icons.wifi_off, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are currently offline. Please connect to the internet to send a message.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              const Text(
                'We’d love to hear from you!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'Your Name',
                hint: 'Enter your full name',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (val.trim().length > 100) return 'Name is too long';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Your Email',
                hint: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Enter a valid email';
                  }
                  if (val.trim().length > 254) return 'Email is too long';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _messageController,
                label: 'Message',
                hint: 'Write your message here...',
                maxLines: 5,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Message is required';
                  }
                  if (val.trim().length < 10) return 'Message is too short';
                  if (val.trim().length > 1000) {
                    return 'Message is too long (max 1000 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isSubmitting || isOffline) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isSubmitting
                        ? 'Sending...'
                        : isOffline
                        ? 'Offline'
                        : 'Send Message',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
