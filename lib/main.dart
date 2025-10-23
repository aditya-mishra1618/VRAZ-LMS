import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vraz_application/student_profile_provider.dart';
import 'package:vraz_application/teacher_session_manager.dart';

import 'Student/service/firebase_notification_service.dart';
import 'firebase_options.dart';
import 'student_session_manager.dart';
import 'splash_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase ONCE here
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase Core initialized in main()');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionManager()),
        ChangeNotifierProvider(create: (context) => StudentProfileProvider()),
        Provider(create: (context) => TeacherSessionManager()),
      ],
      child: MaterialApp(
        title: 'VRaZ Application',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Wait for providers to be ready
      await Future.delayed(const Duration(milliseconds: 200));

      // Get SessionManager
      final sessionManager = Provider.of<SessionManager>(context, listen: false);

      // Initialize Firebase Messaging (NOT Firebase Core - already done in main)
      await FirebaseNotificationService().initializeMessaging(sessionManager);

      print('✅ All services initialized');
    } catch (e) {
      print('❌ Error initializing services: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }

    return const SplashScreen();
  }
}