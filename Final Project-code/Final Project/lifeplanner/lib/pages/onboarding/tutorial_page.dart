import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lifeplanner/pages/auth/signup_page.dart';
import 'welcome_page.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  final List<_StepData> _steps = [
    _StepData(
      title: 'Welcome to Life Planner!',
      description: 'Plan and organize your day with ease.',
      icon: Icons.home,
      color: Colors.blue,
    ),
    _StepData(
      title: 'Create New Tasks',
      description: 'Add new tasks quickly and stay on schedule.',
      icon: Icons.add_task,
      color: Colors.green,
    ),
    _StepData(
      title: 'Set Reminders',
      description: 'Never forget important tasks with reminders.',
      icon: Icons.alarm,
      color: Colors.orange,
    ),
    _StepData(
      title: 'Track Progress',
      description: 'Mark tasks as done and boost productivity.',
      icon: Icons.check_circle,
      color: Colors.purple,
    ),
    _StepData(
      title: 'AI Assistance',
      description: 'Get AI-powered suggestions for priorities and deadlines.',
      icon: Icons.lightbulb,
      color: Colors.teal,
    ),
  ];

  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final isPortrait = height >= width;
            // Calculate sizes adaptively
            final iconSize = min(width * 0.4, height * 0.4);
            final titleFontSize = isPortrait ? width * 0.07 : height * 0.07;
            final descFontSize = isPortrait ? width * 0.045 : height * 0.045;
            final buttonHeight = min(height * 0.07, 50.0);
            final buttonFontSize = isPortrait ? width * 0.045 : height * 0.045;

            return Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, size: width * 0.08),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomePage()),
                    ),
                  ),
                ),

                // Tutorial Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _steps.length,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemBuilder: (context, idx) {
                      final step = _steps[idx];
                      return SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.05,
                          vertical: height * 0.02,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isPortrait ? height * 0.05 : height * 0.02),
                            Icon(step.icon, size: iconSize, color: step.color),
                            SizedBox(height: height * 0.03),
                            Text(
                              step.title,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: height * 0.02),
                            Text(
                              step.description,
                              style: TextStyle(
                                fontSize: descFontSize,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isPortrait ? height * 0.1 : height * 0.05),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    final selected = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.symmetric(horizontal: width * 0.015),
                      width: selected ? width * 0.03 : width * 0.02,
                      height: selected ? width * 0.03 : width * 0.02,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? Colors.black : Colors.grey[400],
                      ),
                    );
                  }),
                ),
                SizedBox(height: height * 0.02),

                // Navigation Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentIndex > 0)
                        SizedBox(
                          width: width * 0.35,
                          height: buttonHeight,
                          child: OutlinedButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: Text('PREV', style: TextStyle(fontSize: buttonFontSize)),
                          ),
                        ),
                      SizedBox(
                        width: width * 0.35,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentIndex == _steps.length - 1) {
                              Navigator.pushReplacement(context, SignUpPage.route());
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            _currentIndex == _steps.length - 1 ? 'GET STARTED' : 'NEXT',
                            style: TextStyle(fontSize: buttonFontSize),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.03),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _StepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}