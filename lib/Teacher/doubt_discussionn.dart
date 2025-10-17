import 'dart:async';

import 'package:flutter/material.dart';

import 'teacher_app_drawer.dart'; // Import your central drawer

// A model for a single chat message
class ChatMessage {
  final String text;
  final bool isSender; // true if the teacher is the sender
  final String time;
  final String? imageUrl;
  final String? audioPath;
  final String? audioDuration;

  ChatMessage({
    required this.text,
    required this.isSender,
    required this.time,
    this.imageUrl,
    this.audioPath,
    this.audioDuration,
  });
}

class TeacherDiscussDoubtScreen extends StatefulWidget {
  final String studentName;
  final String studentSubject;

  const TeacherDiscussDoubtScreen(
      {super.key, required this.studentName, required this.studentSubject});

  @override
  State<TeacherDiscussDoubtScreen> createState() =>
      _TeacherDiscussDoubtScreenState();
}

class _TeacherDiscussDoubtScreenState extends State<TeacherDiscussDoubtScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Initial dummy messages to populate the chat
    _messages.addAll([
      ChatMessage(
        text: "Hey, I'm having trouble with this problem. Can you help?",
        isSender: false,
        time: "10:30 AM",
        imageUrl: 'assets/profile.png', // Placeholder for the student's image
      ),
      ChatMessage(
        text: "Sure, I can help. Let's break it down step by step.",
        isSender: true,
        time: "10:31 AM",
      ),
      ChatMessage(
        text:
            "First, let's identify the key concepts involved in this problem.",
        isSender: true,
        time: "10:31 AM",
      ),
    ]);
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isSender: true,
        time: _formatTime(DateTime.now()),
      ));
    });

    _scrollToBottom();

    // Simulate a student response after a delay
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _messages.add(ChatMessage(
          text: "", // Voice notes don't need text
          isSender: false,
          time: _formatTime(DateTime.now()),
          audioPath: "dummy_path",
          audioDuration: "0:15",
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // --- ADDED THE DRAWER ---
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        // --- REMOVED THE LEADING BACK BUTTON ---
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.studentName,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(widget.studentSubject,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          )
        ],
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(_messages[index]);
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            message.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isSender)
            const CircleAvatar(
                radius: 15, backgroundImage: AssetImage('assets/profile.png')),
          if (!message.isSender) const SizedBox(width: 8),
          _buildMessageBubble(message),
          if (message.isSender) const SizedBox(width: 8),
          if (message.isSender)
            const CircleAvatar(
                radius: 15, backgroundImage: AssetImage('assets/profile.png')),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Column(
      crossAxisAlignment:
          message.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: message.isSender ? Colors.blueAccent : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(message.imageUrl!),
                ),
              if (message.audioPath != null)
                _buildAudioPlayer(message)
              else
                Text(
                  message.text,
                  style: TextStyle(
                      color: message.isSender ? Colors.white : Colors.black87),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(message.time,
              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        )
      ],
    );
  }

  Widget _buildAudioPlayer(ChatMessage message) {
    return Row(
      children: [
        Icon(Icons.play_circle_fill, color: Colors.blueAccent[700]),
        const SizedBox(width: 8),
        // This is a visual placeholder for the audio wave
        Container(
          height: 3,
          width: 100,
          color: Colors.blueAccent[700]?.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(message.audioDuration ?? '',
            style: TextStyle(color: Colors.blueAccent[700])),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Logic to mark doubt as resolved
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doubt marked as resolved!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Mark Doubt as Resolved',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add, color: Colors.grey[600]),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _handleSubmitted,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      filled: true,
                      fillColor: const Color(0xFFF0F4F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20.0),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.mic_none_outlined, color: Colors.grey[600]),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
