import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'contact_us_page.dart';

/// A stateless widget that displays the Terms and Conditions for the Life Planner app.
class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  /// Navigation route helper for this page.
  static route() =>
      MaterialPageRoute(builder: (_) => const TermsAndConditionsPage());

  @override
  Widget build(BuildContext context) {
    // Capture device screen dimensions for responsive sizing.
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC774), // Custom yellow background
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.of(context).pop(), // Go back to previous screen
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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
            // Header illustration image
            Center(
              child: Image.asset(
                'assets/img/termsofservice.png',
                height: height * 0.55,
              ),
            ),
            const SizedBox(height: 16),

            // Section title and effective date
            const Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Effective Date: 19/5/2025',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Introductory paragraph
            const Text(
              'Welcome to Life Planner. These Terms and Conditions ("Terms") govern your use of our mobile application ("App"). By using the App, you agree to these Terms.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 20),

            // Section 1: User Responsibilities
            _sectionTitle('1. User Responsibilities'),
            _bulletText(
              'You agree to provide accurate and up-to-date information.',
            ),
            _bulletText(
              'You are responsible for maintaining the confidentiality of your login credentials.',
            ),
            const SizedBox(height: 16),

            // Section 2: App Usage
            _sectionTitle('2. App Usage'),
            _bulletText(
              'Do not misuse the App by attempting unauthorized access or distributing harmful content.',
            ),
            _bulletText(
              'You agree not to use the App for any illegal or prohibited activity.',
            ),
            const SizedBox(height: 16),

            // Section 3: Intellectual Property
            _sectionTitle('3. Intellectual Property'),
            _bulletText(
              'All content, features, and functionality in the App are owned by Life Planner.',
            ),
            _bulletText(
              'You may not copy, modify, or distribute any content without permission.',
            ),
            const SizedBox(height: 16),

            // Section 4: Termination
            _sectionTitle('4. Termination'),
            _bulletText(
              'We reserve the right to suspend or terminate your account if you violate these Terms.',
            ),
            _bulletText(
              'You can delete your account anytime by contacting us.',
            ),
            const SizedBox(height: 16),

            // Section 5: Modifications
            _sectionTitle('5. Modifications'),
            const Text(
              'We may update these Terms occasionally. Continued use of the App means you accept the updated Terms.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 16),

            // Section 6: Contact Us
            _sectionTitle('6. Contact Us'),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  height: 1.6,
                ),
                children: [
                  const TextSpan(
                    text: 'If you have questions or concerns, please ',
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

  /// Returns a styled section title widget.
  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  /// Returns a bullet point styled widget.
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
