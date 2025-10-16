import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // 1. Import the audio player package

import 'doubt_discussionn.dart';
import 'teacher_app_drawer.dart';

// Data model now includes a path for the audio asset
class StudentDoubt {
  final String studentName;
  final String studentImage;
  final String subject;
  final String doubtText;
  final String timeAgo;
  final String status;
  final String? attachmentType;
  final String? voiceDuration;
  final String? audioAssetPath; // New field

  const StudentDoubt({
    required this.studentName,
    required this.studentImage,
    required this.subject,
    required this.doubtText,
    required this.timeAgo,
    required this.status,
    this.attachmentType,
    this.voiceDuration,
    this.audioAssetPath, // Add to constructor
  });
}

class TeacherDoubtsScreen extends StatefulWidget {
  const TeacherDoubtsScreen({super.key});

  @override
  State<TeacherDoubtsScreen> createState() => _TeacherDoubtsScreenState();
}

class _TeacherDoubtsScreenState extends State<TeacherDoubtsScreen> {
  // 2. Create an instance of the audio player
  late AudioPlayer _audioPlayer;

  // Dummy data updated with the audio asset path
  final List<StudentDoubt> _doubts = const [
    StudentDoubt(
      studentName: 'Aryan Sharma',
      studentImage: 'assets/profile.png',
      subject: 'Physics',
      doubtText: 'Can you explain the concept of derivatives again?',
      timeAgo: '2 min ago',
      status: 'New',
    ),
    StudentDoubt(
      studentName: 'Priya Verma',
      studentImage: 'assets/profile.png',
      subject: 'Chemistry',
      doubtText: 'I\'m having trouble understanding the periodic table.',
      timeAgo: '15 min ago',
      status: 'In Progress',
      attachmentType: 'image',
    ),
    StudentDoubt(
      studentName: 'Rohan Mehta',
      studentImage: 'assets/profile.png',
      subject: 'Maths',
      doubtText: 'I need help with solving quadratic equations.',
      timeAgo: '1 hour ago',
      status: 'Resolved',
    ),
    StudentDoubt(
      studentName: 'Anjali Singh',
      studentImage: 'assets/profile.png',
      subject: 'English',
      doubtText: 'Can you help me with my essay on Shakespeare?',
      timeAgo: '3 hours ago',
      status: 'New',
      attachmentType: 'voice',
      voiceDuration: '0:42',
      audioAssetPath: 'assets/audio/dummy_note.mp3', // Path to your audio file
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 3. Initialize the player
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    // 4. Dispose of the player to free up resources
    _audioPlayer.dispose();
    super.dispose();
  }

  // 5. Function to handle audio playback
  void _handleAudioPlayback(String assetPath) async {
    // Stop any currently playing audio before starting a new one
    if (_audioPlayer.playing) {
      await _audioPlayer.stop();
    }
    try {
      // Load the new audio from assets and play it
      await _audioPlayer.setAsset(assetPath);
      _audioPlayer.play();
    } catch (e) {
      print("Error loading or playing audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        title: const Text('Student Doubts',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _doubts.length,
        itemBuilder: (context, index) {
          return _buildDoubtCard(context, _doubts[index]);
        },
      ),
    );
  }

  Widget _buildDoubtCard(BuildContext context, StudentDoubt doubt) {
    Color statusColor;
    Color statusBgColor;
    switch (doubt.status) {
      case 'New':
        statusColor = Colors.green;
        statusBgColor = Colors.green.shade50;
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.shade50;
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade200;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDiscussDoubtScreen(
                  studentName: doubt.studentName,
                  studentSubject: doubt.subject),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(backgroundImage: AssetImage(doubt.studentImage)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doubt.studentName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(doubt.subject,
                              style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  Text(doubt.timeAgo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 52.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doubt.doubtText,
                        style: TextStyle(color: Colors.grey[700], height: 1.4)),
                    if (doubt.attachmentType == 'image')
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Icon(Icons.image,
                            color: Colors.blueAccent, size: 40),
                      ),
                    if (doubt.attachmentType == 'voice')
                      _buildVoiceNotePlayer(
                          doubt), // Pass the full doubt object
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doubt.status,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. This is now a fully functional audio player widget
  Widget _buildVoiceNotePlayer(StudentDoubt doubt) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // StreamBuilder listens to the player's state
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;

                // Show a loading spinner while buffering
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 24.0,
                    height: 24.0,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                // Show a Play button if not playing
                else if (playing != true) {
                  return IconButton(
                    icon:
                        const Icon(Icons.play_arrow, color: Colors.blueAccent),
                    onPressed: () =>
                        _handleAudioPlayback(doubt.audioAssetPath!),
                  );
                }
                // Show a Pause button if playing
                else if (processingState != ProcessingState.completed) {
                  return IconButton(
                    icon: const Icon(Icons.pause, color: Colors.blueAccent),
                    onPressed: _audioPlayer.pause,
                  );
                }
                // Show a Replay button when completed
                else {
                  return IconButton(
                    icon: const Icon(Icons.replay, color: Colors.blueAccent),
                    onPressed: () => _audioPlayer.seek(Duration.zero),
                  );
                }
              },
            ),
            const Text("Voice Note", style: TextStyle(color: Colors.black54)),
            const Spacer(),
            Text(doubt.voiceDuration ?? '',
                style: const TextStyle(
                    color: Colors.blueAccent, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
