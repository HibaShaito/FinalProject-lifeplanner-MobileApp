import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lifeplanner/pages/settings/privacy_policy.dart';
import 'package:lifeplanner/pages/settings/weather_settings_page.dart';

import 'account_page.dart';
import 'terms_and_conditions_page.dart';
import 'contact_us_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showWeather = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  String getWeatherQuote(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('sunny')) {
      return 'Shine like the sun even on your toughest days.';
    } else if (condition.contains('rain')) {
      return 'Storms don’t last forever. Keep going.';
    } else if (condition.contains('cloud')) {
      return 'Behind every cloud is a silver lining.';
    } else if (condition.contains('snow')) {
      return 'Even the coldest days bring their own beauty.';
    } else if (condition.contains('wind')) {
      return 'Let the wind push you forward, not hold you back.';
    }
    return 'Embrace every season of life with courage.';
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('settings')
            .doc('preferences')
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _showWeather = data['showWeather'] ?? false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .set({key: value}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCD7D),
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Show Weather'),
                    subtitle: const Text(
                      'Display weather information on the home page',
                    ),
                    value: _showWeather,
                    onChanged: (val) async {
                      if (val) {
                        // Ask user to set location first
                        final ok =
                            await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WeatherSettingsPage(),
                              ),
                            ) ??
                            false;
                        if (!ok) return; // user canceled
                      }
                      setState(() => _showWeather = val);
                      await _updateSetting('showWeather', val);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Support & Legal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Account'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountPage()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('Terms & Conditions'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsAndConditionsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Contact Us'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContactUsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
