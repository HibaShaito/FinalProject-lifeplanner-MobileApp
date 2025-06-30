import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lifeplanner/services/notification_service.dart';
import 'package:lifeplanner/services/task_service.dart';
import '../home/home_page.dart';
import '../onboarding/welcome_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initNotificationsOnce();
  }

  Future<void> _initNotificationsOnce() async {
    // guard to ensure we only run this block once
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;

    // 1️⃣ Initialize plugin (channels, permissions, timezone)
    await NotificationService.instance.init();

    // 3️⃣ Pull down all future tasks & occurrences and schedule them
    await TaskService().rescheduleAllTasks();

    // 4️⃣ Start listening for live adds/updates/removals
    TaskService().startTaskChangeListener();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          // your existing email-verification check
          if (!user.emailVerified) {
            return const WelcomePage();
          }
          return const MyHomePage();
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}
