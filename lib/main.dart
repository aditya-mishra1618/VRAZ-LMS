import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'session_manager.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The ChangeNotifierProvider creates and provides the SessionManager
    // instance to all descendant widgets, making session data available globally.
    return ChangeNotifierProvider(
      create: (context) => SessionManager(),
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
