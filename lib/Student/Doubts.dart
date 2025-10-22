// 1. DART PACKAGES
import 'dart:io';

// 2. EXTERNAL PACKAGES
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
// ❌ REMOVE these lines:
// import 'package:permission_handler/permission_handler.dart';
// import 'package:record/record.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/service/create_doubt_service.dart';
import 'package:vraz_application/Student/service/get_all_doubt_service.dart';

// 3. PROJECT FILES
import '../student_session_manager.dart';
import 'app_drawer.dart';
import 'discuss_doubt.dart';
import 'package:vraz_application/Student/models/get_all_model.dart' hide SubjectModel;
import 'package:vraz_application/Student/service/api_service.dart';
import 'package:vraz_application/Student/models/course_models.dart';
import 'package:vraz_application/Student/models/faculty_model.dart';
import 'package:vraz_application/Student/service/faculty_service.dart';
import 'package:vraz_application/Student/models/create_doubt_model.dart';

// --- Enum ---
enum DoubtView { list, form, upload }

// --- Main Screen Widget ---
class DoubtsScreen extends StatefulWidget {
  const DoubtsScreen({super.key});

  @override
  State<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtsScreenState extends State<DoubtsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GetAllDoubtService _doubtService = GetAllDoubtService();

  // API Service and Data
  final ApiService _apiService = ApiService();
  final FacultyService _facultyService = FacultyService();
  final CreateDoubtService _createDoubtService = CreateDoubtService();

  List<SubjectModel> _subjects = [];
  bool _isLoadingSubjects = false;

  List<FacultyModel> _faculties = [];
  bool _isLoadingFaculties = false;

  DoubtView _currentView = DoubtView.list;
  int? _expandedDoubtIndex;

  // Selection IDs for API integration
  int? _selectedSubjectId;
  int? _selectedTopicId;
  int? _selectedSubTopicId;
  String? _selectedTeacherId; // Stores faculty ID for API submission

  // Question controller and submission state
  final TextEditingController _questionController = TextEditingController();
  bool _isSubmittingDoubt = false;

  // Old variables (can be removed later if not needed)
  File? _attachedImage;
  final ImagePicker _picker = ImagePicker();
  // late AudioRecorder _audioRecorder;
  // late AudioPlayer _audioPlayer;
  // bool _isRecording = false;
  // String? _audioPath;

  // API Data
  List<GetAllDoubtModel> _apiDoubts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // _audioRecorder = AudioRecorder();
    // _audioPlayer = AudioPlayer();
    _fetchDoubts(); // Fetch doubts on init
    _fetchCurriculum(); // Fetch subjects/topics on init
    _fetchFaculties(); // Fetch faculties on init
  }

  @override
  void dispose() {
    // _audioRecorder.dispose();
    // _audioPlayer.dispose();
    _questionController.dispose();
    super.dispose();
  }

  // ========== API METHODS ==========

  /// Submit doubt to API
  Future<void> _submitDoubt() async {
    // Validate question
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all required fields
    if (_selectedSubjectId == null ||
        _selectedTopicId == null ||
        _selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all selections'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingDoubt = true;
    });

    try {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Create doubt model with collected data
      // IDs come from:
      // - _selectedSubjectId: from _buildSubjectDropdown() selection
      // - _selectedTopicId: from _buildTopicDropdown() selection
      // - _selectedTeacherId: from _buildTeacherTile() selection
      // - initialQuestion: from _questionController text field
      final doubtData = CreateDoubtModel(
        teacherId: _selectedTeacherId!,
        subjectId: _selectedSubjectId!,
        topicId: _selectedTopicId!, // Using main topic ID as per API requirement
        initialQuestion: _questionController.text.trim(),
      );

      print('📤 Submitting doubt: ${doubtData.toString()}');

      // Call API to create doubt
      final success = await _createDoubtService.createDoubt(token, doubtData);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Doubt submitted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Clear form data
          _questionController.clear();
          _selectedSubjectId = null;
          _selectedTopicId = null;
          _selectedSubTopicId = null;
          _selectedTeacherId = null;

          // Refresh doubts list
          await _fetchDoubts();

          // Navigate back to list view
          _changeView(DoubtView.list);
        }
      }
    } catch (e) {
      print('❌ Error submitting doubt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit doubt: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingDoubt = false;
        });
      }
    }
  }

  /// Fetch doubts from API using SessionManager token
  Future<void> _fetchDoubts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      print('Fetching doubts with token: ${token.substring(0, 20)}...');

      final doubts = await _doubtService.getAllDoubt(token);

      setState(() {
        _apiDoubts = doubts;
        _isLoading = false;
      });

      print('Successfully loaded ${doubts.length} doubts');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading doubts: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load doubts: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchDoubts,
            ),
          ),
        );
      }
    }
  }

  /// Fetch curriculum (subjects and topics) from API
  Future<void> _fetchCurriculum() async {
    setState(() {
      _isLoadingSubjects = true;
    });

    try {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
          _isLoadingSubjects = false;
        });
        return;
      }

      print('Fetching curriculum (subjects and topics)...');

      final subjects = await _apiService.fetchCurriculum(token);

      setState(() {
        _subjects = subjects;
        _isLoadingSubjects = false;
      });

      print('Successfully loaded ${subjects.length} subjects');
    } catch (e) {
      setState(() {
        _isLoadingSubjects = false;
      });
      print('Error loading curriculum: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load subjects: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchCurriculum,
            ),
          ),
        );
      }
    }
  }

  /// Fetch faculties from API
  Future<void> _fetchFaculties() async {
    setState(() {
      _isLoadingFaculties = true;
    });

    try {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final token = await sessionManager.loadToken();

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
          _isLoadingFaculties = false;
        });
        return;
      }

      print('Fetching faculties...');

      final faculties = await _facultyService.fetchAllFaculty(token);
      setState(() {
        _faculties = faculties;
        _isLoadingFaculties = false;
      });

      print('Successfully loaded ${faculties.length} faculties');
    } catch (e) {
      setState(() {
        _isLoadingFaculties = false;
      });
      print('Error loading faculties: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load teachers: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchFaculties,
            ),
          ),
        );
      }
    }
  }

  // ========== UI HELPER METHODS ==========

  void _changeView(DoubtView newView) {
    if (newView == DoubtView.upload) {
      setState(() {
        _attachedImage = null;

      });
    }
    setState(() {
      _currentView = newView;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _attachedImage = File(pickedFile.path);

      });
    }
  }



  // ========== MAIN BUILD METHOD ==========

  @override
  Widget build(BuildContext context) {
    switch (_currentView) {
      case DoubtView.list:
        return _buildDoubtListView();
      case DoubtView.form:
        return _buildDoubtFormView();
      case DoubtView.upload:
        return _buildDoubtUploadView();
    }
  }

  // ========== DOUBT LIST VIEW ==========

  Widget _buildDoubtListView() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('My Doubts',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchDoubts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : _apiDoubts.isEmpty
          ? _buildEmptyWidget()
          : RefreshIndicator(
        onRefresh: _fetchDoubts,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _apiDoubts.length,
          itemBuilder: (context, index) =>
              _buildApiDoubtCard(_apiDoubts[index], index),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _changeView(DoubtView.form),
        label: const Text('Upload Doubt'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
              'Failed to load doubts',
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
              onPressed: _fetchDoubts,
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
          Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No doubts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first doubt to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildApiDoubtCard(GetAllDoubtModel doubt, int index) {
    final bool isPending = doubt.status.toLowerCase() == 'open' ||
        doubt.status.toLowerCase() == 'pending';
    final bool isExpanded = _expandedDoubtIndex == index;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: isPending
            ? () {
          setState(() {
            _expandedDoubtIndex = isExpanded ? null : index;
          });
        }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(isPending ? Icons.hourglass_top : Icons.check_circle,
                      color: isPending ? Colors.orange : Colors.green),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isPending ? 'PENDING' : doubt.status,
                            style: TextStyle(
                                color: isPending ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Doubt Topic: ${doubt.topic.name}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('Question: ${doubt.initialQuestion}',
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Submitted ${doubt.getRelativeTime()}',
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(doubt.subject.name,
                        style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (isPending && isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiscussDoubtScreen(
                                doubtId: doubt.id, // ✅ Add this
                                facultyName: doubt.teacher.fullName,
                                doubtTopic: doubt.topic.name,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Discuss Doubt'),
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

  // ========== DOUBT FORM VIEW (Selection Screen) ==========

  Widget _buildDoubtFormView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => _changeView(DoubtView.list),
        ),
        title: const Text('Ask a Doubt',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: (_isLoadingSubjects || _isLoadingFaculties)
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      )
          : (_subjects.isEmpty || _faculties.isEmpty)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_subjects.isEmpty
                ? 'No subjects found'
                : 'No teachers found'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                if (_subjects.isEmpty) _fetchCurriculum();
                if (_faculties.isEmpty) _fetchFaculties();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Dropdown - stores ID in _selectedSubjectId
            _buildSubjectDropdown(),
            const SizedBox(height: 16),

            // Topic Dropdown (only show if subject is selected) - stores ID in _selectedTopicId
            if (_selectedSubjectId != null) _buildTopicDropdown(),
            if (_selectedSubjectId != null) const SizedBox(height: 16),

            // SubTopic Dropdown (only show if topic is selected) - stores ID in _selectedSubTopicId
            if (_selectedTopicId != null) _buildSubTopicDropdown(),
            if (_selectedTopicId != null) const SizedBox(height: 24),

            // Teacher Selection - stores ID in _selectedTeacherId
            const Text('Select Teacher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._faculties.map((faculty) => _buildTeacherTile(faculty)),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: (_selectedSubjectId != null &&
              _selectedTopicId != null &&
              _selectedSubTopicId != null &&
              _selectedTeacherId != null)
              ? () => _changeView(DoubtView.upload)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            disabledBackgroundColor: Colors.grey[300],
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Confirm Selection',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  // Subject Dropdown - User selects subject, stores ID in _selectedSubjectId
  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedSubjectId,
          hint: const Text('Select a subject'),
          items: _subjects.map((subject) {
            return DropdownMenuItem<int>(
              value: subject.id,
              child: Text(subject.name),
            );
          }).toList(),
          onChanged: (subjectId) {
            setState(() {
              _selectedSubjectId = subjectId;
              _selectedTopicId = null;
              _selectedSubTopicId = null;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Topic Dropdown - User selects topic, stores ID in _selectedTopicId
  Widget _buildTopicDropdown() {
    final selectedSubject =
    _subjects.firstWhere((s) => s.id == _selectedSubjectId);
    final mainTopics = selectedSubject.getMainTopics();

    if (mainTopics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No topics available for this subject',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Topic',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedTopicId,
          hint: const Text('Select a topic'),
          items: mainTopics.map((topic) {
            return DropdownMenuItem<int>(
              value: topic.id,
              child: Text(topic.name),
            );
          }).toList(),
          onChanged: (topicId) {
            setState(() {
              _selectedTopicId = topicId;
              _selectedSubTopicId = null;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // SubTopic Dropdown - User selects subtopic, stores ID in _selectedSubTopicId
  Widget _buildSubTopicDropdown() {
    final selectedSubject =
    _subjects.firstWhere((s) => s.id == _selectedSubjectId);
    final selectedTopic = selectedSubject.findTopicById(_selectedTopicId!);

    if (selectedTopic == null || selectedTopic.subTopics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No sub-topics available for this topic',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sub-topic',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedSubTopicId,
          hint: const Text('Select a sub-topic'),
          items: selectedTopic.subTopics.map((subTopic) {
            return DropdownMenuItem<int>(
              value: subTopic.id,
              child: Text(subTopic.name),
            );
          }).toList(),
          onChanged: (subTopicId) {
            setState(() {
              _selectedSubTopicId = subTopicId;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Teacher Tile - User selects teacher, stores ID in _selectedTeacherId
  Widget _buildTeacherTile(FacultyModel faculty) {
    bool isSelected = _selectedTeacherId == faculty.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedTeacherId = faculty.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            // Show photo or initials
            faculty.hasPhoto()
                ? CircleAvatar(
              backgroundImage: NetworkImage(faculty.photoUrl),
              radius: 24,
            )
                : CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 24,
              child: Text(
                faculty.getInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                faculty.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: Colors.blueAccent,
            )
          ],
        ),
      ),
    );
  }

  // ========== DOUBT UPLOAD VIEW (Question Entry Screen) ==========

  Widget _buildDoubtUploadView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => _changeView(DoubtView.form),
        ),
        title: const Text('Upload Doubt',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
      ),
      body: _isSubmittingDoubt
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Submitting your doubt...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show selected information summary
            _buildSelectionSummary(),
            const SizedBox(height: 24),

            // Question input field
            const Text('Describe your doubt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _questionController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText:
                'Write your question here...\n\nExample: What is the difference between speed and velocity?',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: _isSubmittingDoubt ? null : _submitDoubt,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            disabledBackgroundColor: Colors.grey[300],
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmittingDoubt
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text('Submit Doubt',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  // Shows summary of selected subject, topic, and teacher before question entry
  Widget _buildSelectionSummary() {
    final subject = _subjects.firstWhere((s) => s.id == _selectedSubjectId);
    final topic = subject.findTopicById(_selectedTopicId!);
    final teacher = _faculties.firstWhere((f) => f.id == _selectedTeacherId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selected Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.book, 'Subject', subject.name),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.topic, 'Topic', topic?.name ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person, 'Teacher', teacher.fullName),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ========== OLD METHODS (can be removed if not needed) ==========

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_attachedImage!),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _attachedImage = null),
              child: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 12,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAttachmentButton(
      IconData icon, String label, VoidCallback onPressed,
      {bool isActive = false}) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: isActive ? Colors.white : Colors.grey[700]),
      label: Text(label,
          style: TextStyle(color: isActive ? Colors.white : Colors.grey[800])),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.redAccent : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }
}