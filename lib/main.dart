import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/student_profile_provider.dart';
import 'package:vraz_application/teacher_session_manager.dart';

import 'student_session_manager.dart';
import 'splash_screen.dart';

void main() {
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
        Provider(create: (context) => TeacherSessionManager()), // ✅ Changed here
      ],
      child: MaterialApp(
        title: 'VRaZ Application',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}