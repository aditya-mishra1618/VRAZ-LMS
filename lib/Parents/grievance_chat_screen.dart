import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/Parents/service/greivance_api.dart';

import 'models/grivance_model.dart';
import 'parent_app_drawer.dart';

class GrievanceChatScreen extends StatefulWidget {
  final String grievanceTitle;
  final String navigationSource;
  final int? grievanceId; // ✅ NEW: Optional grievance ID

  const GrievanceChatScreen({
    super.key,
    required this.grievanceTitle,
    required this.navigationSource,
    this.grievanceId,
  });

  @override
  State<GrievanceChatScreen> createState() => _GrievanceChatScreenState();
}

class _GrievanceChatScreenState extends State<GrievanceChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();

  Grievance? _grievance;
  bool _isLoading = true;
  String? _authToken;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadGrievanceDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadGrievanceDetails() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('parent_auth_token');

      print('[GrievanceChat] Auth Token: ${_authToken != null ? "Found" : "Missing"}');
      print('[GrievanceChat] Grievance ID: ${widget.grievanceId}');

      if (_authToken == null || _authToken!.isEmpty) {
        _showError('Session expired. Please login again.');
        return;
      }

      if (widget.grievanceId != null) {
        // Load real grievance details
        _grievance = await GrievanceApi.getGrievanceDetails(
          authToken: _authToken!,
          grievanceId: widget.grievanceId!,
        );

        if (_grievance != null) {
          print('[GrievanceChat] ✅ Grievance loaded: ${_grievance!.title}');
          _initializeMessages();
        } else {
          print('[GrievanceChat] ⚠️ Failed to load grievance');
          _showError('Failed to load grievance details.');
        }
      } else {
        // Demo mode (no grievance ID provided)
        print('[GrievanceChat] ℹ️ Demo mode - no grievance ID');
        _initializeDemoMessages();
      }
    } catch (e, stackTrace) {
      print('[GrievanceChat] ❌ Error: $e');
      print('[GrievanceChat] Stack trace: $stackTrace');
      _showError('Failed to load grievance. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeMessages() {
    if (_grievance == null) return;

    _messages.clear();

    // Add initial grievance message
    _messages.add({
      'sender': 'Parent',
      'text': _grievance!.description,
      'timestamp': _grievance!.createdAt,
      'isSystem': false,
    });

    // Add system acknowledgment
    _messages.add({
      'sender': 'Admin',
      'text': 'Hello! We have received your grievance regarding "${_grievance!.title}". Our team will review it and get back to you shortly.',
      'timestamp': _grievance!.createdAt.add(const Duration(minutes: 1)),
      'isSystem': true,
    });

    // TODO: Load actual chat messages from API when available
  }

  void _initializeDemoMessages() {
    _messages.add({
      'sender': 'Admin',
      'text': 'Hello! We have received your grievance. How can we assist you further?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'isSystem': true,
    });

    _messages.add({
      'sender': 'Parent',
      'text': 'Yes, I need help with this issue.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'isSystem': false,
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final messageText = _messageController.text.trim();

    setState(() {
      _messages.add({
        'sender': 'Parent',
        'text': messageText,
        'timestamp': DateTime.now(),
        'isSystem': false,
      });
      _messageController.clear();
    });

    // TODO: Send message to API when available
    print('[GrievanceChat] 📤 Message sent: $messageText');

    // Simulate admin response (remove this when real API is available)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'Admin',
            'text': 'Thank you for your message. Our team is looking into this.',
            'timestamp': DateTime.now(),
            'isSystem': true,
          });
        });
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.grievanceTitle.isNotEmpty
                  ? widget.grievanceTitle
                  : (_grievance?.title ?? 'Grievance Chat'),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (_grievance != null)
              Text(
                'Status: ${_grievance!.displayStatus}',
                style: TextStyle(
                  color: _grievance!.statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (_grievance != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _grievance!.statusBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _grievance!.displayStatus,
                  style: TextStyle(
                    color: _grievance!.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_grievance != null) _buildGrievanceInfoBanner(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isParent = message['sender'] == 'Parent';
                return _buildMessageBubble(
                  message['text']!,
                  isParent,
                  message['timestamp'] as DateTime?,
                );
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildGrievanceInfoBanner() {
    if (_grievance == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grievance ID: #${_grievance!.id}',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Created: ${_grievance!.formattedDate}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isParent, DateTime? timestamp) {
    return Align(
      alignment: isParent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isParent ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isParent ? 20 : 4),
            bottomRight: Radius.circular(isParent ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isParent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isParent ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(timestamp),
                style: TextStyle(
                  color: isParent ? Colors.white70 : Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildMessageInputField() {
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
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}