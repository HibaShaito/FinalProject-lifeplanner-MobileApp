import 'package:flutter/material.dart';
import 'tutorial_page.dart';
import 'package:lifeplanner/pages/auth/login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double imageSize = size.width * 0.8; // Image size based on width
    final double buttonHeight =
        size.height * 0.07; // Button height based on height

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start, // Ensure the content doesn't get squeezed
          children: [
            // Orange Header Bar
            Container(
              height: size.height * 0.1,
              width: double.infinity,
              color: const Color(0xFFFFCD7D),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.06,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center the elements
                      children: [
                        // Image
                        Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/img/welcome.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.03), // Dynamic spacing
                        // Title Text
                        Text(
                          'Life Planner',
                          style: TextStyle(
                            fontSize:
                                size.width * 0.07, // Font size based on width
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFCD7D),
                          ),
                        ),
                        SizedBox(height: size.height * 0.01), // Dynamic spacing
                        // Subtitle Text
                        Text(
                          'Manage your life for free and save your time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize:
                                size.width * 0.04, // Font size based on width
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: size.height * 0.05), // Dynamic spacing
                        // Get Started Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TutorialPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            shape: const StadiumBorder(),
                            minimumSize: Size(double.infinity, buttonHeight),
                          ),
                          child: Text(
                            "GET STARTED",
                            style: TextStyle(
                              fontSize: size.width * 0.045,
                            ), // Font size based on width
                          ),
                        ),
                        SizedBox(height: size.height * 0.02), // Dynamic spacing
                        // Already have an account Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            shape: const StadiumBorder(),
                            minimumSize: Size(double.infinity, buttonHeight),
                          ),
                          child: Text(
                            "I ALREADY HAVE AN ACCOUNT",
                            style: TextStyle(
                              fontSize: size.width * 0.045,
                            ), // Font size based on width
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
