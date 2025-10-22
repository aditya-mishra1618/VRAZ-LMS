import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../student_session_manager.dart';
import 'service/api_service.dart';
import 'app_drawer.dart';
import 'models/course_models.dart';

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

  YoutubePlayerController? _ytController;
  String? _currentPlayingVideoId;

  final ApiService _apiService = ApiService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchCurriculum();
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

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
      _ytController?.dispose();
      _ytController = null;
      _currentPlayingVideoId = null;
    });
  }

  void _selectTopic(TopicModel topic) {
    setState(() {
      _selectedTopic = topic;
      _currentView = CourseView.topicContent;
      _ytController?.dispose();
      _ytController = null;
      _currentPlayingVideoId = null;
    });
  }

  void _playVideo(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) {
      _showSnackBar('Invalid video URL', Colors.red);
      return;
    }

    final String? videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId == null) {
      _showSnackBar('Could not extract video ID from URL', Colors.red);
      return;
    }

    setState(() {
      if (_ytController != null) {
        _ytController!.load(videoId);
      } else {
        _ytController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
          ),
        )..addListener(_ytListener);
      }
      _currentPlayingVideoId = videoId;
    });
  }

  void _ytListener() {
    if (_ytController != null && _ytController!.value.hasError) {
      final errorCode = _ytController!.value.errorCode;
      _showSnackBar('YouTube Player Error: Code $errorCode', Colors.red);
    }
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
        _ytController?.dispose();
        _ytController = null;
        _currentPlayingVideoId = null;
      } else if (_currentView == CourseView.topicList) {
        _currentView = CourseView.subject;
        _selectedTopic = null;
      } else {
        _scaffoldKey.currentState?.openDrawer();
      }
    });
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

  Widget _buildTopicContentView() {
    if (_selectedTopic == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedTopic!.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildProgressCard(0.0),
          const SizedBox(height: 20),
          if (_ytController != null && _currentPlayingVideoId != null)
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: YoutubePlayer(
                  controller: _ytController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.blueAccent,
                ),
              ),
            ),
          const SizedBox(height: 20),
          _buildContentExpansionTile(_selectedTopic!),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue[100],
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child:
                const Text('Ask a Doubt', style: TextStyle(color: Colors.blue)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Next Lesson',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UPDATED WIDGET ---
  Widget _buildContentExpansionTile(TopicModel topic, {int depth = 0}) {
    // If a topic has sub-topics, it acts as a container/folder.
    // Otherwise, it's a leaf node that displays its content directly.
    bool isLeafTopic = topic.subTopics.isEmpty;

    IconData leadingIcon =
        isLeafTopic ? Icons.description_outlined : Icons.folder_open_outlined;
    Color iconColor = isLeafTopic ? Colors.orange[700]! : Colors.blue[700]!;

    // Determine the children for this tile.
    // If it's a leaf, the children are the LMS content items.
    // Otherwise, the children are the next level of recursive expansion tiles.
    final List<Widget> children = isLeafTopic
        ? topic.lmsContents
            .map((content) => _buildLMSContentTile(content))
            .toList()
        : topic.subTopics
            .map((subTopic) =>
                _buildContentExpansionTile(subTopic, depth: depth + 1))
            .toList();

    // The top-level item (selected topic) is not an ExpansionTile itself,
    // but a direct container for its children (either content or sub-topics).
    if (depth == 0) {
      // For the top level, we create a container that looks like a card
      // and then list its children directly without an ExpansionTile.
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: children,
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

  Widget _buildLMSContentTile(LMSContentModel content) {
    IconData contentIcon;
    Color iconColor;
    VoidCallback? onTapAction;

    switch (content.contentType) {
      case 'Video':
        contentIcon = Icons.play_circle_fill_outlined;
        iconColor = Colors.red[700]!;
        onTapAction = () => _playVideo(content.contentUrl);
        break;
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
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  Widget _buildProgressCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Course Progress',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}
