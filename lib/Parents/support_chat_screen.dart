import 'package:flutter/material.dart';

import 'Grievance_screen.dart';
// Import the screens we might navigate back to
import 'parents_dashboard.dart';

// Removed 'parent_app_drawer.dart' import

class GrievanceChatScreen extends StatefulWidget {
  final String? grievanceTitle;
  // --- NEW: Parameter to track the source screen ---
  final String navigationSource; // e.g., 'dashboard' or 'grievance'

  const GrievanceChatScreen({
    super.key,
    this.grievanceTitle,
    required this.navigationSource, // Make it required
  });

  @override
  State<GrievanceChatScreen> createState() => _GrievanceChatScreenState();
}

class _GrievanceChatScreenState extends State<GrievanceChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'Admin',
      'text':
          'Hello! We have received your grievance. How can we assist you further?'
    },
    {
      'sender': 'Parent',
      'text': 'Yes, I noticed a discrepancy in my child\'s attendance record.'
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _messages.add({
        'sender': 'Parent',
        'text': _messageController.text.trim(),
      });
      _messageController.clear();
      // TODO: Send message to backend
    });
  }

  // --- NEW: Back navigation logic ---
  void _navigateBack() {
    Widget destinationScreen;
    // Determine where to go based on the source
    if (widget.navigationSource == 'grievance') {
      destinationScreen = const GrievanceScreen();
    } else {
      // Default to dashboard if source is 'dashboard' or unknown
      destinationScreen = const ParentDashboardScreen();
    }

    // Use pushReplacement to avoid stacking screens when going "back"
    // to a main navigation point.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.grievanceTitle ?? 'Support Chat';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        // --- UPDATED: Use the new _navigateBack function ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: _navigateBack, // Call the custom back logic
        ),
        title: Text(
          appBarTitle,
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isParent = message['sender'] == 'Parent';
                return _buildMessageBubble(
                  message['text']!,
                  isParent,
                );
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isParent) {
    // ... (This widget remains the same)
    return Align(
      alignment: isParent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isParent ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft:
                isParent ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight:
                isParent ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isParent ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    // ... (This widget remains the same)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  fillColor: const Color(0xFFF0F4F8),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
