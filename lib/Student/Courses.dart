import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for rotation
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// --- FIX: Corrected import paths based on your project structure ---
import '../student_session_manager.dart';
// --- FIX: Import your actual doubt screen and the notes screen ---
import 'Discuss_Doubt.dart';
import 'app_drawer.dart';
import 'models/course_models.dart';
import 'notes_view_screen.dart';
import 'service/api_service.dart';

enum CourseView { subject, topicList, topicContent }

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CourseView _currentView = CourseView.subject;

  List<SubjectModel> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  SubjectModel? _selectedSubject;
  TopicModel? _selectedTopic;

  final ApiService _apiService = ApiService();
  bool _isDataFetched = false; // Prevents multiple fetches

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      _fetchCurriculum();
      _isDataFetched = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- NO CHANGES to _fetchCurriculum ---
  Future<void> _fetchCurriculum() async {
    final sessionManager = Provider.of<SessionManager>(context, listen: false);
    final token = sessionManager.authToken;

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Authentication error. Please log in again.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedSubjects = await _apiService.fetchCurriculum(token);
      if (!mounted) return;
      setState(() {
        _subjects = fetchedSubjects;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
      _showSnackBar(_errorMessage ?? 'An unknown error occurred', Colors.red);
    }
  }

  void _selectSubject(SubjectModel subject) {
    setState(() {
      _selectedSubject = subject;
      _currentView = CourseView.topicList;
    });
  }

  void _selectTopic(TopicModel topic) {
    setState(() {
      _selectedTopic = topic;
      _currentView = CourseView.topicContent;
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _goBack() {
    setState(() {
      if (_currentView == CourseView.topicContent) {
        _currentView = CourseView.topicList;
      } else if (_currentView == CourseView.topicList) {
        _currentView = CourseView.subject;
        _selectedTopic = null;
      } else {
        _scaffoldKey.currentState?.openDrawer();
      }
    });
  }

  // --- NEW: Helper function to mock teacher data ---
  Future<Map<String, String>> _getTeacherForSubject(String subjectName) async {
    // In a real app, you'd fetch this from your API.
    await Future.delayed(
        const Duration(milliseconds: 300)); // Mock network call
    if (subjectName == 'Physics') {
      return {'id': 'T-001', 'name': 'Prof. Physics'};
    } else if (subjectName == 'Chemistry') {
      return {'id': 'T-002', 'name': 'Prof. Chemistry'};
    } else {
      return {'id': 'T-003', 'name': 'Prof. Maths'};
    }
  }

  // --- NEW: Helper to get notes for the current video's topic ---
  List<LMSContentModel> _getNotesForContent(LMSContentModel content) {
    if (_selectedTopic == null) return [];
    TopicModel? parentTopic = _selectedTopic!.findParentTopicOf(content);
    if (parentTopic != null) {
      return parentTopic.lmsContents
          .where((item) => item.contentType != 'Video')
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _currentView == CourseView.subject
          ? Colors.white
          : const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
              _currentView == CourseView.subject
                  ? Icons.menu_rounded
                  : Icons.arrow_back,
              color: Colors.black54),
          onPressed: _goBack,
        ),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _currentView == CourseView.subject
            ? Colors.white
            : const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: $_errorMessage',
                      textAlign: TextAlign.center),
                ))
              : _buildCurrentView(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentView) {
      case CourseView.subject:
        return 'Courses';
      case CourseView.topicList:
        return _selectedSubject?.name ?? 'My Courses';
      case CourseView.topicContent:
        return _selectedTopic?.name ?? 'Course Materials';
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CourseView.subject:
        return _buildSubjectSelectionView();
      case CourseView.topicList:
        return _buildTopicListView();
      case CourseView.topicContent:
        return _buildTopicContentView();
    }
  }

  Widget _buildSubjectSelectionView() {
    // ... This function remains unchanged ...
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your subject',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.separated(
              itemCount: _subjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                return _buildSubjectCard(
                  subject,
                  subject.name == 'Physics'
                      ? Colors.blue
                      : subject.name == 'Chemistry'
                          ? Colors.lightBlue
                          : Colors.purple,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(SubjectModel subject, Color color) {
    // ... This function remains unchanged ...
    IconData icon;
    switch (subject.name) {
      case 'Physics':
        icon = Icons.rocket_launch_outlined;
        break;
      case 'Chemistry':
        icon = Icons.science_outlined;
        break;
      case 'Maths':
        icon = Icons.calculate_outlined;
        break;
      default:
        icon = Icons.book_outlined;
    }

    return GestureDetector(
      onTap: () => _selectSubject(subject),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 20),
            Text(subject.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicListView() {
    // ... This function remains unchanged ...
    if (_selectedSubject == null) {
      return const Center(child: Text('No subject selected.'));
    }

    final topLevelTopics = _selectedSubject!.topics;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topLevelTopics.length,
      itemBuilder: (context, index) {
        final topic = topLevelTopics[index];
        return _buildTopicCard(topic);
      },
    );
  }

  Widget _buildTopicCard(TopicModel topic) {
    // ... This function remains unchanged ...
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => _selectTopic(topic),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.folder_open_outlined, color: Colors.blue[700]),
        ),
        title: Text(topic.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('View Content'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  // --- REBUILT WIDGET ---
  Widget _buildTopicContentView() {
    if (_selectedTopic == null) return const SizedBox.shrink();

    // This view is now a simple list, no common player.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          _selectedTopic!.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lectures & Resources',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        // Build the content list
        _buildContentExpansionTile(_selectedTopic!),
      ],
    );
  }

  // --- UPDATED WIDGET ---
  Widget _buildContentExpansionTile(TopicModel topic, {int depth = 0}) {
    bool isLeafTopic = topic.subTopics.isEmpty;

    IconData leadingIcon =
        isLeafTopic ? Icons.description_outlined : Icons.folder_open_outlined;
    Color iconColor = isLeafTopic ? Colors.orange[700]! : Colors.blue[700]!;

    // --- FIX: Get ALL content (videos, PDFs, etc.) ---
    final List<Widget> children = isLeafTopic
        ? topic.lmsContents
            .map((content) =>
                _buildLMSContentTile(content, topic)) // Pass parent
            .toList()
        : topic.subTopics
            .map((subTopic) =>
                _buildContentExpansionTile(subTopic, depth: depth + 1))
            .toList();
    // --- END FIX ---

    // The top-level item (selected topic) is not an ExpansionTile itself,
    // but a direct container for its children (either content or sub-topics).
    if (depth == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: children.isEmpty
              ? [
                  const ListTile(
                    title: Text('No content available for this topic.'),
                  )
                ]
              : children,
        ),
      );
    }

    // For nested topics, render an expandable card.
    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        key: PageStorageKey(topic.id),
        title: Text(
          topic.name,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16 - (depth * 1.0)),
        ),
        leading: Icon(leadingIcon, color: iconColor),
        children: children,
      ),
    );
  }

  // --- UPDATED WIDGET (Re-added PDF/Link logic) ---
  Widget _buildLMSContentTile(LMSContentModel content, TopicModel parentTopic) {
    // --- THIS IS THE MAIN CHANGE ---
    // If it's a video, return the new lazy-loading card.
    if (content.contentType == 'Video') {
      return _VideoContentCard(
        content: content,
        subject: _selectedSubject!,
        parentTopic: parentTopic,
        onAskDoubt: (subjectName) async {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Finding your teacher...'),
            duration: Duration(milliseconds: 700),
          ));
          return await _getTeacherForSubject(subjectName);
        },
        onGetNotes: (videoContent) {
          return _getNotesForContent(videoContent);
        },
      );
    }
    // --- END OF CHANGE ---

    // Otherwise, build a simple ListTile for PDFs, Links, etc.
    IconData contentIcon;
    Color iconColor;
    VoidCallback? onTapAction;

    switch (content.contentType) {
      case 'PDF':
        contentIcon = Icons.picture_as_pdf_outlined;
        iconColor = Colors.purple[700]!;
        onTapAction = () {
          _showSnackBar('Opening PDF: ${content.title}', Colors.blue);
        };
        break;
      case 'Link':
        contentIcon = Icons.link_outlined;
        iconColor = Colors.green[700]!;
        onTapAction = () {
          _showSnackBar('Opening Link: ${content.title}', Colors.blue);
        };
        break;
      default:
        contentIcon = Icons.help_outline;
        iconColor = Colors.grey[700]!;
        onTapAction = () {
          _showSnackBar('Unsupported content type', Colors.orange);
        };
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(contentIcon, color: iconColor),
      title: Text(content.title),
      onTap: onTapAction,
      trailing: const Icon(Icons.chevron_right, size: 16),
    );
  }
}

// --- NEW STATEFUL WIDGET FOR INDIVIDUAL VIDEO CARDS (LAZY LOADING) ---
class _VideoContentCard extends StatefulWidget {
  final LMSContentModel content;
  final SubjectModel subject;
  final TopicModel parentTopic;
  final Future<Map<String, String>> Function(String subjectName) onAskDoubt;
  final List<LMSContentModel> Function(LMSContentModel content) onGetNotes;

  const _VideoContentCard({
    required this.content,
    required this.subject,
    required this.parentTopic,
    required this.onAskDoubt,
    required this.onGetNotes,
  });

  @override
  State<_VideoContentCard> createState() => _VideoContentCardState();
}

class _VideoContentCardState extends State<_VideoContentCard> {
  YoutubePlayerController? _ytController;
  String? _videoId;
  bool _isPlaying = false; // Tracks if the player is initialized

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.content.contentUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _videoId = YoutubePlayer.convertUrlToId(videoUrl);
    }
  }

  @override
  void dispose() {
    // --- ROTATION FIX: Ensure orientation is reset when widget is disposed ---
    _ytController?.removeListener(_onPlayerStateChange);
    _ytController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  // --- ROTATION FIX: Listener to handle fullscreen changes ---
  void _onPlayerStateChange() {
    if (_ytController == null) return;
    if (_ytController!.value.isFullScreen) {
      // When player goes fullscreen, allow landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // When player exits fullscreen, lock back to portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  // --- LAG FIX: Initialize player only when play is pressed ---
  void _initializeAndPlay() {
    if (_videoId == null) return;
    // This check prevents re-initializing if already playing
    if (_ytController != null && _isPlaying) return;

    setState(() {
      _ytController = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true, // Auto-play when initialized
          mute: false,
        ),
      )..addListener(_onPlayerStateChange); // Add rotation listener
      _isPlaying = true; // Set playing state
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      // Handle invalid video URL
      return ListTile(
        leading: Icon(Icons.error, color: Colors.grey[400]),
        title: Text(widget.content.title,
            style: const TextStyle(decoration: TextDecoration.lineThrough)),
        subtitle: const Text('Invalid video URL'),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Video Player (Lazy Loaded)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isPlaying && _ytController != null
                ? YoutubePlayer(
                    controller: _ytController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.blueAccent,
                  )
                : _buildThumbnail(), // Show thumbnail
          ),

          // 2. Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              widget.content.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 3. Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ask Doubt Button (Left)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Ask Doubt'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      backgroundColor: Colors.blue[50],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final teacherInfo =
                          await widget.onAskDoubt(widget.subject.name);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiscussDoubtScreen(
                              doubtId: widget.content.id,
                              facultyName: teacherInfo['name']!,
                              doubtTopic: widget.parentTopic.name,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // View Notes Button (Right)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('View Notes'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final notes = widget.onGetNotes(widget.content);
                      if (notes.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('No notes found for this topic.'),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotesViewScreen(notes: notes),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Thumbnail Widget for Lazy Loading ---
  Widget _buildThumbnail() {
    return InkWell(
      onTap: _initializeAndPlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Use the provided thumbnail or a fallback
          Image.network(
            widget.content.thumbnailUrl ??
                YoutubePlayer.getThumbnail(videoId: _videoId!),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stack) {
              return Container(
                color: Colors.black,
                child: const Icon(Icons.error, color: Colors.white),
              );
            },
          ),
          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          // Play button
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 60,
            ),
          ),
        ],
      ),
    );
  }
}
