import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// A simple model for a chat message
class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.imageUrl,
  });
}

class DiscussDoubtScreen extends StatefulWidget {
  final String facultyName;
  final String doubtTopic;

  const DiscussDoubtScreen({
    super.key,
    required this.facultyName,
    required this.doubtTopic,
  });

  @override
  State<DiscussDoubtScreen> createState() => _DiscussDoubtScreenState();
}

class _DiscussDoubtScreenState extends State<DiscussDoubtScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add initial dummy messages to simulate a conversation
    _messages.addAll([
      ChatMessage(
        text:
            "Hello! I'm having trouble with question 5 on the latest assignment. Could you explain the concept of differentiation again?",
        isUser: true,
        time: "10:30 AM",
      ),
      ChatMessage(
        text:
            "Of course! Differentiation is the process of finding the derivative of a function. Let me send you a helpful video.",
        isUser: false,
        time: "10:32 AM",
      ),
    ]);
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        time: _formatTime(DateTime.now()),
      ));
    });

    // Scroll to the bottom after sending a message
    _scrollToBottom();

    // Simulate a delayed response from the faculty
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _messages.add(ChatMessage(
          text: "Thank you, that would be great!",
          isUser: true,
          time: _formatTime(DateTime.now()),
        ));
        _messages.add(ChatMessage(
            text: "Here's a video that explains the concept clearly.",
            isUser: false,
            time: _formatTime(DateTime.now()),
            imageUrl: 'assets/profile.png' // Placeholder image
            ));
      });
      _scrollToBottom();
    });
  }

  Future<void> _handleAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // For simplicity, we just send the file name as a message.
      String fileName = result.files.single.name;
      _handleSubmitted("File attached: $fileName");
    } else {
      // User canceled the picker
    }
  }

  void _handleVoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice messaging is not yet implemented.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _scrollToBottom() {
    // A short delay ensures the list has been rebuilt before scrolling
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
    // Simple time formatting (e.g., 10:35 AM)
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Doubt Discussion',
              style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Text(
              'With ${widget.facultyName} about ${widget.doubtTopic}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bubbleAlignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isUser ? Colors.white : Colors.blueAccent;
    final textColor = message.isUser ? Colors.black87 : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: bubbleAlignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: message.isUser
                  ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(message.imageUrl!, fit: BoxFit.cover),
                  ),
                if (message.imageUrl != null) const SizedBox(height: 8),
                Text(
                  message.text,
                  style: TextStyle(color: textColor, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              message.time,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                  suffixIcon: Icon(Icons.emoji_emotions_outlined,
                      color: Colors.grey[600]),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey[600]),
              onPressed: _handleAttachment,
            ),
            IconButton(
              icon: Icon(Icons.mic_none_outlined, color: Colors.grey[600]),
              onPressed: _handleVoice,
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}
