import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vraz_application/Teacher/models/teacher_doubt_model.dart';
import 'package:vraz_application/Teacher/services/teacher_doubt_service.dart';
import 'package:vraz_application/Student/service/media_upload_service.dart'; // Reusing student's service
import '../teacher_session_manager.dart';
import 'teacher_app_drawer.dart';

class TeacherDiscussDoubtScreen extends StatefulWidget {
  final TeacherDoubtModel doubt;

  const TeacherDiscussDoubtScreen({
    super.key,
    required this.doubt,
  });

  @override
  State<TeacherDiscussDoubtScreen> createState() =>
      _TeacherDiscussDoubtScreenState();
}

class _TeacherDiscussDoubtScreenState extends State<TeacherDiscussDoubtScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TeacherDoubtService _doubtService = TeacherDoubtService();
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final ImagePicker _picker = ImagePicker();

  // Audio recording
  late FlutterSoundRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  bool _recorderInitialized = false;
  String? _recordedAudioPath;

  // API Data
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _token;
  String? _currentTeacherId;

  // Real-time polling
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _audioPlayer = AudioPlayer();
    _initializeAndFetchChat();
    _startPolling();
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

  // ========== AUDIO INITIALIZATION ==========

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

  // ========== API METHODS ==========

  Future<void> _initializeAndFetchChat() async {
    final sessionManager =
    Provider.of<TeacherSessionManager>(context, listen: false);
    _token = await sessionManager.loadToken();
    _currentTeacherId = widget.doubt.teacherId;

    if (_token == null) {
      setState(() {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isLoading = false;
      });
      return;
    }

    await _fetchChat();
  }

  Future<void> _fetchChat() async {
    if (_token == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('💬 Fetching chat for doubt ID: ${widget.doubt.id}');

      final chatResponse =
      await _doubtService.getChat(_token!, widget.doubt.id);

      setState(() {
        _messages = chatResponse.messages;
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
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchChat,
            ),
          ),
        );
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (mounted && !_isLoading && !_isSending && !_isUploading && _token != null) {
        _refreshChat();
      }
    });
  }

  Future<void> _refreshChat() async {
    if (_token == null) return;

    try {
      final chatResponse =
      await _doubtService.getChat(_token!, widget.doubt.id);

      if (mounted && chatResponse.messages.length != _messages.length) {
        setState(() {
          _messages = chatResponse.messages;
        });
        print('🔄 Chat updated: ${_messages.length} messages');
        _scrollToBottom();
      }
    } catch (e) {
      print('⚠️ Error refreshing chat: $e');
    }
  }

  // ========== SEND MESSAGE ==========

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isSending || _token == null) return;

    final messageText = text.trim();
    _textController.clear();

    await _sendMessage(text: messageText);
  }

  Future<void> _sendMessage({
    String? text,
    String? imageUrl,
    String? voiceNoteUrl,
  }) async {
    if (_isSending || _token == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      print('📤 Sending message...');

      // Call the updated sendMessage with optional parameters
      final success = await _doubtService.sendMessage(
        _token!,
        widget.doubt.id,
        text: text,
        imageUrl: imageUrl,
        voiceNoteUrl: voiceNoteUrl,
      );

      if (success) {
        print('✅ Message sent, refreshing chat...');
        await _fetchChat();
      }

      setState(() {
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSending = false;
      });

      print('❌ Error sending message: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                        final sizeInKB =
                        (snapshot.data! / 1024).toStringAsFixed(2);
                        return Text(
                          'Size: $sizeInKB KB',
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
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

      if (_token == null) throw Exception('Authentication token not found.');

      print('📸 Uploading image: ${imageFile.path}');

      final imageUrl = await _mediaUploadService.uploadImage(_token!, imageFile);

      print('✅ Image uploaded: $imageUrl');

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await _sendMessage(imageUrl: imageUrl);
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
      final String fileName =
          'voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      final String filePath = '${appDir.path}/$fileName';

      print('🎤 Starting recording to: $filePath');

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Permission')
                  ? 'Microphone permission denied. Please enable it in Settings.'
                  : 'Failed to start recording: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
                    icon: const Icon(Icons.stop_circle,
                        color: Colors.red, size: 40),
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

      if (_token == null) throw Exception('Authentication token not found.');

      print('🎤 Uploading voice note: ${audioFile.path}');

      final voiceUrl = await _mediaUploadService.uploadAudio(_token!, audioFile);

      print('✅ Voice uploaded: $voiceUrl');

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (await audioFile.exists()) await audioFile.delete();

      await _sendMessage(voiceNoteUrl: voiceUrl);
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

  // ========== MARK AS RESOLVED ==========

  Future<void> _markAsResolved() async {
    if (_token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: const Text(
            'Are you sure you want to mark this doubt as resolved? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark as Resolved'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      print('✅ Marking doubt ${widget.doubt.id} as resolved');

      final success =
      await _doubtService.resolveDoubt(_token!, widget.doubt.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doubt marked as resolved!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error resolving doubt: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve doubt: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // ========== UI METHODS ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doubt.student.fullName,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(widget.doubt.subject.name,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchChat,
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : Column(
        children: [
          _buildDoubtInfoCard(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyWidget()
                : RefreshIndicator(
              onRefresh: _fetchChat,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageItem(_messages[index]);
                },
              ),
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
                    child:
                    CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isUploading ? 'Uploading...' : 'Sending...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildDoubtInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Topic: ${widget.doubt.topic.name}',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.doubt.initialQuestion,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              height: 1.4,
            ),
          ),
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
              onPressed: _fetchChat,
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the discussion by sending a message',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isTeacher = message.senderId == _currentTeacherId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
        isTeacher ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isTeacher)
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.blue[100],
              child: Text(
                message.sender.getInitials(),
                style: TextStyle(
                  color: Colors.blue[900],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!isTeacher) const SizedBox(width: 8),
          _buildMessageBubble(message, isTeacher),
          if (isTeacher) const SizedBox(width: 8),
          if (isTeacher)
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.green[100],
              child: Text(
                message.sender.getInitials(),
                style: TextStyle(
                  color: Colors.green[900],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isTeacher) {
    return Column(
      crossAxisAlignment:
      isTeacher ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isTeacher ? Colors.blueAccent : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (message.imageUrl != null) ...[
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
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[300]),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: isTeacher
                                    ? Colors.white70
                                    : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (message.text != null && message.text!.isNotEmpty)
                  const SizedBox(height: 8),
              ],
              // Voice Note
              if (message.voiceNoteUrl != null) ...[
                _buildAudioPlayer(message, isTeacher),
                if (message.text != null && message.text!.isNotEmpty)
                  const SizedBox(height: 8),
              ],
              // Text
              if (message.text != null && message.text!.isNotEmpty)
                Text(
                  message.text!,
                  style: TextStyle(
                    color: isTeacher ? Colors.white : Colors.black87,
                  ),
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
    );
  }

  Widget _buildAudioPlayer(ChatMessage message, bool isTeacher) {
    return GestureDetector(
      onTap: () async {
        try {
          await _audioPlayer.stop();
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_filled,
              color: isTeacher ? Colors.white : Colors.blueAccent[700],
              size: 32,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.graphic_eq,
              color: isTeacher ? Colors.white : Colors.blueAccent[700],
            ),
            const SizedBox(width: 8),
            Text(
              'Voice Note',
              style: TextStyle(
                color: isTeacher ? Colors.white : Colors.blueAccent[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isResolved = widget.doubt.isResolved;
    final bool isDisabled = _isSending || _isUploading || _isRecording || isResolved;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isResolved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: _markAsResolved,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[50],
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Mark Doubt as Resolved',
                    style: TextStyle(color: Colors.green)),
              ),
            ),
          if (isResolved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'This doubt has been resolved',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                            : isResolved
                            ? "Doubt is resolved"
                            : "Type your message...",
                        filled: true,
                        fillColor: isDisabled
                            ? Colors.grey[200]
                            : const Color(0xFFF0F4F8),
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
                      color: isDisabled && !_isRecording
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
                    onPressed: isDisabled
                        ? null
                        : () => _handleSubmitted(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}