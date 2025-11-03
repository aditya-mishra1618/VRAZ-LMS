import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // Import the video player package

import 'home_screen.dart'; // The screen to navigate to after the splash

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // NEW: Change from 'late' to a nullable type. This is much safer.
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    // Assign the controller
    _controller = VideoPlayerController.asset('assets/videos/splash_video.mp4');

    // Use the '!' operator because we *just* assigned it.
    _controller!.initialize().then((_) {
      // We must check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {}); // Trigger rebuild once video is initialized
        _controller!.play();
        _controller!.setLooping(true);
      }
    }).catchError((error) {
      // If initialization fails, print the error.
      print("Error initializing video player: $error");
      // The build method will just keep showing the spinner, which is safe.
    });

    // This timer will navigate to the HomeScreen after 8.2 seconds.
    Timer(const Duration(milliseconds: 8200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    // NEW: Use the null-aware operator '?' to safely call dispose.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // ********** KEY CHANGE **********
        // We add two checks:
        // 1. Is the controller itself null?
        // 2. Is the controller's value initialized?
        // Only if BOTH are true do we show the video.
        child: (_controller != null && _controller!.value.isInitialized)
            ?
            // If video is ready, show it
            FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  // Use '!' because we've already checked for null
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            :
            // Otherwise, show the loading spinner. This is the safe fallback.
            const CircularProgressIndicator(color: Colors.blue),
      ),
    );
  }
}
