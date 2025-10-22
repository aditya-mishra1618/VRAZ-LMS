import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vraz_application/Student/service/chat_service.dart';
import 'package:vraz_application/Student/service/media_upload_service.dart';
import '../student_session_manager.dart';
import 'models/chat_model.dart';

class DiscussDoubtScreen extends StatefulWidget {
  final int doubtId;
  final String facultyName;
  final String doubtTopic;

  const DiscussDoubtScreen({
    super.key,
    required this.doubtId,
    required this.facultyName,
    required this.doubtTopic,
  });

  @override
  State<DiscussDoubtScreen> createState() => _DiscussDoubtScreenState();
}

class _DiscussDoubtScreenState extends State<DiscussDoubtScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final ImagePicker _picker = ImagePicker();

  // Audio recording
  late FlutterSoundRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  bool _recorderInitialized = false;
  String? _recordedAudioPath;

  // Chat data
  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _currentUserId;

  // Real-time polling
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _audioPlayer = AudioPlayer();
    _loadChat();
    _startPolling();
  }

  Future<void> _initializeRecorder() async {
    try {
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder.openRecorder();
      _recorderInitialized = true;
      print('✅ Recorder initialized');
    } catch (e) {
      print('❌ Recorder init failed: $e');
      _recorderInitialized = false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    if (_recorderInitialized) {
      _audioRecorder.closeRecorder();
    }
    _audioPlayer.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========== CHAT LOADING ==========

  Future<void> _loadChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      print('📥 Loading chat for doubt ID: ${widget.doubtId}');

      final chatData = await _chatService.getChat(token, widget.doubtId);

      setState(() {
        _messages = chatData.messages;
        _currentUserId = chatData.studentId;
        _isLoading = false;
      });

      print('✅ Loaded ${_messages.length} messages');
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading chat: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========== REAL-TIME POLLING ==========

  void _startPolling() {
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (mounted && !_isLoading && !_isSending && !_isUploading) {
        _refreshMessages();
      }
    });
  }

  Future<void> _refreshMessages() async {
    try {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) return;

      final chatData = await _chatService.getChat(token, widget.doubtId);

      if (mounted && chatData.messages.length != _messages.length) {
        setState(() {
          final oldLength = _messages.length;
          _messages = chatData.messages;

          if (chatData.messages.length > oldLength) {
            _scrollToBottom();
          }
        });
        print('🔄 Chat updated: ${_messages.length} messages');
      }
    } catch (e) {
      print('⚠️ Error refreshing messages: $e');
    }
  }

  // ========== SEND MESSAGE ==========

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    await _sendMessage(SendMessageRequest(text: text.trim()));
  }

  Future<void> _sendMessage(SendMessageRequest message) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) {
        throw Exception('Authentication token not found.');
      }

      print('📤 Sending message...');

      final success = await _chatService.sendMessage(token, widget.doubtId, message);

      if (success) {
        print('✅ Message sent successfully');
        await _loadChat();
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ========== IMAGE HANDLING ==========

  // ========== IMAGE HANDLING ==========

  Future<void> _handleImagePicker(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // ✅ Show preview confirmation BEFORE uploading
      if (mounted) {
        _showImagePreviewConfirmation(File(pickedFile.path));
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePreviewConfirmation(File imageFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Preview Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Image preview with zoom
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // File info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'File: ${imageFile.path.split('/').last}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: imageFile.length(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final sizeInKB = (snapshot.data! / 1024).toStringAsFixed(2);
                        return Text(
                          'Size: $sizeInKB KB',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _uploadAndSendImage(imageFile);
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    try {
      setState(() => _isUploading = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Uploading image...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) throw Exception('Authentication token not found.');

      print('📸 Uploading image: ${imageFile.path}');

      final imageUrl = await _mediaUploadService.uploadImage(token, imageFile);

      print('✅ Image uploaded: $imageUrl');

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await _sendMessage(SendMessageRequest(imageUrl: imageUrl));
    } catch (e) {
      print('❌ Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

// ========== VOICE RECORDING ==========

  Future<void> _startRecording() async {
    if (!_recorderInitialized) {
      await _initializeRecorder();
      if (!_recorderInitialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initialize recorder'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      final String filePath = '${appDir.path}/$fileName';

      print('🎤 Starting recording to: $filePath');

      // ✅ FlutterSoundRecorder will automatically request permission when startRecorder is called
      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordedAudioPath = filePath;
      });

      print('✅ Recording started successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.red),
                SizedBox(width: 8),
                Text('Recording...'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      print('❌ Error starting recording: $e');

      setState(() {
        _isRecording = false;
      });

      if (mounted) {
        // Show user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Permission')
                  ? 'Microphone permission denied. Please enable it in Settings.'
                  : 'Failed to start recording: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                // User can manually go to settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Go to: Settings → Apps → Your App → Permissions → Microphone'),
                    duration: Duration(seconds: 5),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      print('🛑 Stopping recording...');

      final path = await _audioRecorder.stopRecorder();

      setState(() => _isRecording = false);

      if (path == null || path.isEmpty) {
        print('⚠️ No audio path returned');
        return;
      }

      print('✅ Recording stopped: $path');

      final file = File(path);
      if (!await file.exists()) {
        print('❌ File not found');
        return;
      }

      final fileSize = await file.length();
      print('📁 File size: $fileSize bytes');

      if (fileSize < 1000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording too short'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        _showVoiceUploadConfirmation(file);
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      setState(() => _isRecording = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVoiceUploadConfirmation(File audioFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Voice Note Recorded'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your voice note has been recorded successfully!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled,
                        color: Colors.blueAccent, size: 40),
                    onPressed: () async {
                      try {
                        print('▶️ Playing preview: ${audioFile.path}');
                        await _audioPlayer.stop();
                        await _audioPlayer.setFilePath(audioFile.path);
                        await _audioPlayer.play();
                      } catch (e) {
                        print("❌ Error playing audio preview: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to play: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop_circle, color: Colors.red, size: 40),
                    onPressed: () async {
                      await _audioPlayer.stop();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'File: ${audioFile.path.split('/').last}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              print('🗑️ Deleting recorded file');
              try {
                await _audioPlayer.stop();
                if (audioFile.existsSync()) {
                  audioFile.deleteSync();
                }
              } catch (e) {
                print('⚠️ Error deleting file: $e');
              }
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await _audioPlayer.stop();
              Navigator.pop(context);
              _uploadAndSendVoiceNote(audioFile);
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAndSendVoiceNote(File audioFile) async {
    try {
      setState(() => _isUploading = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Uploading voice note...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) throw Exception('Authentication token not found.');

      print('🎤 Uploading voice note: ${audioFile.path}');

      final voiceUrl = await _mediaUploadService.uploadAudio(token, audioFile);

      print('✅ Voice uploaded: $voiceUrl');

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (await audioFile.exists()) await audioFile.delete();

      await _sendMessage(SendMessageRequest(voiceNoteUrl: voiceUrl));
    } catch (e) {
      print('❌ Error uploading voice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload voice note: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
  // ========== UI HELPERS ==========

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

  bool _isCurrentUser(ChatMessageModel message) {
    return message.senderId == _currentUserId;
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _handleImagePicker(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _handleImagePicker(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== BUILD METHODS ==========

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadChat,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : Column(
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
          if (_isSending || _isUploading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isUploading ? 'Uploading...' : 'Sending...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load chat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChat,
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

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = _isCurrentUser(message);
    final bubbleAlignment =
    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? Colors.white : Colors.blueAccent;
    final textColor = isUser ? Colors.black87 : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: bubbleAlignment,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message.sender.fullName,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isUser
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
                if (message.hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      message.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: const Column(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(height: 8),
                              Text('Failed to load image'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (message.hasVoice)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_arrow,
                              color: isUser ? Colors.blueAccent : Colors.white),
                          onPressed: () async {
                            try {
                              await _audioPlayer.setUrl(message.voiceNoteUrl!);
                              _audioPlayer.play();
                            } catch (e) {
                              print("Error playing audio: $e");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to play audio: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        Icon(Icons.graphic_eq,
                            color: isUser ? Colors.blueAccent : Colors.white),
                        const SizedBox(width: 8),
                        Text('Voice Note', style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                if (message.hasText)
                  Text(
                    message.text!,
                    style: TextStyle(color: textColor, height: 1.4),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              message.getFormattedTime(),
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    final bool isDisabled = _isSending || _isUploading || _isRecording;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: isDisabled ? null : _handleSubmitted,
                enabled: !isDisabled,
                decoration: InputDecoration(
                  hintText: _isRecording
                      ? "Recording..."
                      : _isUploading
                      ? "Uploading..."
                      : "Type your message...",
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
              icon: Icon(Icons.image,
                  color: isDisabled ? Colors.grey[300] : Colors.grey[600]),
              onPressed: isDisabled ? null : _showImageOptions,
            ),
            IconButton(
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic_none_outlined,
                color: isDisabled
                    ? Colors.grey[300]
                    : (_isRecording ? Colors.red : Colors.grey[600]),
              ),
              onPressed: isDisabled && !_isRecording
                  ? null
                  : (_isRecording ? _stopRecording : _startRecording),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: isDisabled ? Colors.grey[300] : Colors.blueAccent,
              ),
              onPressed:
              isDisabled ? null : () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}