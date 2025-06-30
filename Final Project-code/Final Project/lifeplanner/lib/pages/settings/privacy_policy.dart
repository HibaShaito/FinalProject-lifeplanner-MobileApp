import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'contact_us_page.dart';

/// A stateless widget that displays the Privacy Policy for the Life Planner app.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  /// Route helper method for navigation to this page.
  static route() =>
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage());

  @override
  Widget build(BuildContext context) {
    // Get the width and height of the screen to apply responsive layout.
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFFFC774,
        ), // Light yellow background for brand consistency
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed:
              () => Navigator.pop(
                context,
              ), // Navigate back to the previous screen
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.06,
          vertical: height * 0.015,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top illustration image
            Center(
              child: Image.asset(
                'assets/img/privacypolicy.png',
                height: height * 0.45,
              ),
            ),
            const SizedBox(height: 16),

            // Page heading and effective date
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Effective Date: 19/5/2025',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Introductory paragraph describing the purpose of the privacy policy
            const Text(
              'Welcome to Life Planner ("we," "our," or "us"). Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our mobile application ("App").',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 20),

            // Section 1: What information is collected from users
            _sectionTitle('1. Information We Collect'),
            _bulletText(
              'Personal Information: Name, email address, and other details you provide during sign-up.',
            ),
            _bulletText(
              'Usage Data: Information about how you use the app, including task entries, schedules, and health tracking data.',
            ),
            _bulletText(
              'Device Information: Information about your device, such as model, operating system, and unique identifiers.',
            ),

            const SizedBox(height: 16),

            // Section 2: How the collected data is used
            _sectionTitle('2. How We Use Your Information'),
            _bulletText('Provide, maintain, and improve the app\'s features.'),
            _bulletText(
              'Store and sync your schedule, health tracking, and financial records.',
            ),
            _bulletText(
              'Send reminders and notifications as per your preferences.',
            ),
            _bulletText('Enhance user experience with AI-powered insights.'),

            const SizedBox(height: 16),

            // Section 3: Data security and sharing policy
            _sectionTitle('3. Data Sharing & Security'),
            _bulletText(
              'We do not sell or rent your personal information to third parties.',
            ),
            _bulletText(
              'Your data is stored securely using encryption and authentication measures.',
            ),
            _bulletText(
              'We may share anonymized usage data for app improvement purposes.',
            ),

            const SizedBox(height: 16),

            // Section 4: Third-party services used and their implications
            _sectionTitle('4. Third-Party Services'),
            _bulletText(
              'We use third-party services like Firebase for authentication and data storage.',
            ),
            _bulletText(
              'These services have their own privacy policies. Please review them for more information.',
            ),

            const SizedBox(height: 16),

            // Section 5: User control over their own data
            _sectionTitle('5. Your Rights & Control'),
            _bulletText(
              'You can update or delete your personal data anytime through app settings.',
            ),
            _bulletText(
              'You can disable notifications and tracking features via device settings.',
            ),

            const SizedBox(height: 16),

            // Section 6: Policy update notice
            _sectionTitle('6. Changes to This Policy'),
            const Text(
              'We may update this Privacy Policy occasionally. Continued use of the app means you accept the updated policy.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),

            const SizedBox(height: 16),

            // Section 7: Contact method for any concerns
            _sectionTitle('7. Contact Us'),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  height: 1.6,
                ),
                children: [
                  const TextSpan(
                    text:
                        'If you have any questions about this Privacy Policy, please ',
                  ),
                  TextSpan(
                    text: 'contact us.',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer:
                        TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to the Contact Us page
                            Navigator.push(context, ContactUsPage.route());
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Returns a styled section title widget for each section heading.
  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  /// Returns a bullet point styled widget for each point under a section.
  static Widget _bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
