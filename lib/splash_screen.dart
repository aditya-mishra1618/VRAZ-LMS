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
  // Controller to manage video playback
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the video controller with your video asset
    // IMPORTANT: Make sure you have a video file at this path in your project.
    _controller = VideoPlayerController.asset('assets/videos/splash_video.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        setState(() {});
        // Start playing the video
        _controller.play();
        // Set the video to loop for a continuous effect
        _controller.setLooping(true);
      });

    // This timer will navigate to the HomeScreen after 5 seconds, regardless of video length.
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    // It's important to dispose of the controller to free up resources.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A black background is often best for video splash screens
      backgroundColor: Colors.black,
      body: Center(
        // Use a ternary operator to check if the video has been initialized.
        child: _controller.value.isInitialized
            ?
            // If initialized, display the video in an AspectRatio widget to maintain its shape.
            AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            :
            // While the video is loading, show a loading indicator or a static image.
            const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
