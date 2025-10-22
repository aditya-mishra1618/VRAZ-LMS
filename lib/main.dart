import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/student_profile_provider.dart';

import 'student_session_manager.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider creates and provides multiple providers
    // (SessionManager and StudentProfileProvider) to all descendant widgets,
    // making session data and profile data available globally.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionManager()),
        ChangeNotifierProvider(create: (context) => StudentProfileProvider()),
      ],
      child: MaterialApp(
        title: 'VRaZ Application',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        // The SplashScreen remains the entry point. It should be responsible for
        // navigating to the AuthCheckScreen after it completes.
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}