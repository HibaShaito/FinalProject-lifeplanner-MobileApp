import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeplanner/services/cache_service.dart';
import 'package:lifeplanner/services/chat_service.dart';
import 'package:lifeplanner/services/groq_service.dart';
import 'package:lifeplanner/services/note_service.dart';
import 'package:lifeplanner/services/notification_service.dart';
import 'package:lifeplanner/services/open_router_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'firebase_options.dart';
import 'utils/network_status_service.dart';
import 'pages/auth/auth_wrapper.dart';

void main() async {
 Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Firebase init + offline persistence ───
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 200 * 1024 * 1024,
    );
    await CacheService.pruneOldCache(
      collectionPath: 'yourCollection',
      maxAge: const Duration(days: 7),
    );
  } catch (e) {
    if (kDebugMode) print('Firebase init failed: $e');
  }

  // ─── Local Notifications ───
  try {
    await requestPermissions();
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    await NotificationService.instance.init();
  } catch (e) {
    if (kDebugMode) print('NotificationService init failed: $e');
  }

  // ─── Secure Storage & OpenRouterService setup ───
  final secureStorage = FlutterSecureStorage();
  final secureStorage1 = FlutterSecureStorage();

  await secureStorage.write(
      key: 'openrouter_key',
      value: 'UR_API_KEY_HERE'
  );
  await secureStorage1.write(
      key: 'groq_api_key',
      value: 'UR_API_KEY_HERE'
  );


  // Read it back:
  final apiKey = await secureStorage.read(key: 'openrouter_key');
  if (apiKey == null) {
    throw Exception('OpenRouter API key not found in secure storage');
  }
  final apiKey1 = await secureStorage1.read(key: 'groq_api_key');
  if (apiKey1 == null) {
    throw Exception('Groq API key not found in secure storage');
  }

  final openRouterService = OpenRouterService(apiKey: apiKey);
  final groqService = GroqService(apiKey:apiKey1);




  // ─── Launch Flutter app with Providers ───
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NetworkStatusNotifier()),
          Provider<OpenRouterService>.value(value: openRouterService),
          Provider<GroqService>.value(value: groqService),
          Provider(create: (_) => ChatService()),
          Provider<NoteService>(create: (_) => NoteService()),
        ],
        child: const MyApp(),
      ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management',
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
