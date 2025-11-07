import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../parent_session_manager.dart';
import 'models/support_chat_model.dart';
import 'service/support_chat_service.dart';
import 'parents_dashboard.dart';
import 'support_ticket_screen.dart';

class SupportChatScreen extends StatefulWidget {
  final String? grievanceTitle;
  final String navigationSource;
  final int ticketId; // ✅ ADD THIS - Required for API calls

  const SupportChatScreen({
    super.key,
    this.grievanceTitle,
    required this.navigationSource,
    required this.ticketId, // ✅ ADD THIS
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SupportChatService _chatService = SupportChatService();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  ChatTicketDetails? _chatDetails;

  @override
  void initState() {
    super.initState();
    print('🔷 [CHAT_INIT] Support Chat Screen initialized');
    print('   ├─ Ticket ID: ${widget.ticketId}');
    print('   └─ Title: ${widget.grievanceTitle}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================
  // Load chat messages
  // ============================================
  Future<void> _loadChatMessages() async {
    final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);

    if (!sessionManager.isLoggedIn || sessionManager.token == null) {
      setState(() {
        _errorMessage = 'Please login to view chat.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _chatService.getChatMessages(
      token: sessionManager.token!,
      ticketId: widget.ticketId,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _chatDetails = response.data;
          _messages = response.data?.messages ?? [];
          print('✅ Loaded ${_messages.length} messages');
          _scrollToBottom();
        } else {
          _errorMessage = response.errorMessage;
          print('❌ Error loading chat: $_errorMessage');
        }
      });
    }
  }

  // ============================================
  // Send text message
  // ============================================
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);

    if (!sessionManager.isLoggedIn || sessionManager.token == null) {
      _showSnackBar('Please login to send messages', Colors.red);
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    final request = SendMessageRequest(text: messageText);

    final response = await _chatService.sendMessage(
      token: sessionManager.token!,
      ticketId: widget.ticketId,
      request: request,
    );

    if (mounted) {
      setState(() => _isSending = false);

      if (response.success) {
        // Add message to list
        setState(() {
          _messages.add(response.data!);
        });
        _scrollToBottom();
        print('✅ Message sent successfully');
      } else {
        _showSnackBar(response.errorMessage ?? 'Failed to send message', Colors.red);
      }
    }
  }

  // ============================================
  // Pick and send image
  // ============================================
  // ============================================
// Pick image and show confirmation
// ============================================
  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) {
        print('📷 [IMAGE] User cancelled image selection');
        return;
      }

      print('📷 [IMAGE] Image picked: ${pickedFile.path}');

      // Show preview and ask for confirmation
      final bool? confirmed = await _showImageConfirmationDialog(File(pickedFile.path));

      if (confirmed != true) {
        print('❌ [IMAGE] User cancelled sending image');
        return;
      }

      print('✅ [IMAGE] User confirmed - Proceeding to upload');

      final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);

      if (!sessionManager.isLoggedIn || sessionManager.token == null) {
        _showSnackBar('Please login to send images', Colors.red);
        return;
      }

      // Show uploading indicator
      setState(() => _isSending = true);

      // Upload image
      print('📤 [IMAGE] Uploading image to server...');
      final uploadResponse = await _chatService.uploadMedia(
        token: sessionManager.token!,
        file: File(pickedFile.path),
      );

      if (!uploadResponse.success) {
        setState(() => _isSending = false);
        _showSnackBar(uploadResponse.errorMessage ?? 'Failed to upload image', Colors.red);
        return;
      }

      print('✅ [IMAGE] Image uploaded successfully: ${uploadResponse.data}');

      // Send message with image URL
      final request = SendMessageRequest(imageUrl: uploadResponse.data);

      print('📤 [IMAGE] Sending message with image URL...');
      final response = await _chatService.sendMessage(
        token: sessionManager.token!,
        ticketId: widget.ticketId,
        request: request,
      );

      if (mounted) {
        setState(() => _isSending = false);

        if (response.success) {
          setState(() {
            _messages.add(response.data!);
          });
          _scrollToBottom();
          print('✅ [IMAGE] Image sent successfully');
          _showSnackBar('Image sent successfully', Colors.green);
        } else {
          _showSnackBar(response.errorMessage ?? 'Failed to send image', Colors.red);
        }
      }
    } catch (e) {
      setState(() => _isSending = false);
      print('❌ [IMAGE] Error: $e');
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

// ============================================
// Show image confirmation dialog
// ============================================
  Future<bool?> _showImageConfirmationDialog(File imageFile) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Send this image?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Image Preview
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          print('❌ [DIALOG] User clicked Cancel');
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          print('✅ [DIALOG] User clicked Send');
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // Scroll to bottom
  // ============================================
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ============================================
  // Show snackbar
  // ============================================
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================
  // Navigate back
  // ============================================
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Widget destinationScreen;
      if (widget.navigationSource == 'support_ticket_screen') {
        destinationScreen = const SupportTicketScreen();
      } else {
        destinationScreen = const ParentDashboardScreen();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destinationScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.grievanceTitle ?? 'Support Chat';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: _navigateBack,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadChatMessages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : Column(
        children: [
          Expanded(child: _buildMessagesList()),
          if (_isSending) _buildSendingIndicator(),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  // ============================================
  // Build error widget
  // ============================================
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChatMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Build messages list
  // ============================================
  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet. Start the conversation!',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return _buildMessageBubble(message);
      },
    );
  }

  // ============================================
  // Build message bubble
  // ============================================
  Widget _buildMessageBubble(ChatMessage message) {
    final bool isParent = message.isParent;

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
        child: Column(
          crossAxisAlignment:
          isParent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name (if not parent and sender exists)
            if (!isParent && message.sender != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  message.sender!.fullName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Text message
            if (message.hasText)
              Text(
                message.text!,
                style: TextStyle(
                  color: isParent ? Colors.white : Colors.black87,
                ),
              ),
            // Image message
            if (message.hasImage)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _formatTime(message.sentAt),
                style: TextStyle(
                  color: isParent
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade500,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================
  // Build sending indicator
  // ============================================
  Widget _buildSendingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Sending...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Build message input field
  // ============================================
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
            // Attachment button
            IconButton(
              icon: const Icon(Icons.image, color: Colors.blueAccent),
              onPressed: () {
                _showImageSourceDialog();
              },
            ),
            const SizedBox(width: 8),
            // Text field
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
            // Send button
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Show image source dialog
  // ============================================
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Format time
  // ============================================
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}