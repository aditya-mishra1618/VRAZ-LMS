// 1. DART PACKAGES
import 'dart:io';

// 2. EXTERNAL PACKAGES
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

// 3. PROJECT FILES
import 'app_drawer.dart';
import 'discuss_doubt.dart';

// --- Data Models (Unchanged) ---
class Doubt {
  final String status;
  final String subject;
  final String topic;
  final String subTopic;
  final String submittedDate;
  final String imageUrl;
  final String professor;

  Doubt({
    required this.status,
    required this.subject,
    required this.topic,
    required this.subTopic,
    required this.submittedDate,
    required this.imageUrl,
    required this.professor,
  });
}

class SubjectData {
  final String name;
  final List<Topic> topics;
  SubjectData({required this.name, required this.topics});
}

class Topic {
  final String name;
  final List<String> subTopics;
  Topic({required this.name, required this.subTopics});
}

class Teacher {
  final String name;
  final String subject;
  final String imageUrl;
  Teacher({required this.name, required this.subject, required this.imageUrl});
}

enum DoubtView { list, form, upload }

// --- Main Screen Widget ---
class DoubtsScreen extends StatefulWidget {
  const DoubtsScreen({super.key});

  @override
  State<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtsScreenState extends State<DoubtsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DoubtView _currentView = DoubtView.list;
  int? _expandedDoubtIndex;

  String? _selectedSubject;
  String? _selectedTopic;
  String? _selectedSubTopic;
  String? _selectedTeacher;
  File? _attachedImage;

  final ImagePicker _picker = ImagePicker();

  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  String? _audioPath;

  final List<Doubt> _doubts = [
    Doubt(
        status: 'Pending',
        subject: 'Maths',
        topic: 'Integration',
        subTopic: 'Integration by parts',
        submittedDate: '2025-10-10 10:30 AM',
        imageUrl: 'assets/profile.png',
        professor: 'Prof. Ramswaroop Sir'),
    Doubt(
        status: 'Resolved',
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Second Law',
        submittedDate: '2025-10-08 02:15 PM',
        imageUrl: 'assets/profile.png',
        professor: 'Prof. Zeeshan Sir'),
    Doubt(
        status: 'Pending',
        subject: 'Chemistry',
        topic: 'Chemical Bonding',
        subTopic: 'Covalent Bonds',
        submittedDate: '2025-10-05 09:45 AM',
        imageUrl: 'assets/profile.png',
        professor: 'Prof. Ankit Sir'),
  ];
  final List<SubjectData> _subjects = [
    SubjectData(name: 'Physics', topics: [
      Topic(
          name: 'Kinematics', subTopics: ['Motion in 1D', 'Projectile Motion']),
      Topic(
          name: 'Laws of Motion',
          subTopics: ['First Law', 'Second Law', 'Third Law']),
    ]),
    SubjectData(name: 'Chemistry', topics: [
      Topic(
          name: 'Chemical Bonding',
          subTopics: ['Ionic Bonds', 'Covalent Bonds']),
      Topic(name: 'Organic Chemistry', subTopics: ['Alkanes', 'Alkenes']),
    ]),
    SubjectData(name: 'Maths', topics: [
      Topic(name: 'Calculus', subTopics: ['Limits', 'Derivatives']),
      Topic(
          name: 'Integration',
          subTopics: ['Indefinite Integral', 'Definite Integral']),
    ]),
  ];
  final List<Teacher> _teachers = [
    Teacher(
        name: 'Prof. Zeeshan Sir',
        subject: 'Physics',
        imageUrl: 'assets/profile.png'),
    Teacher(
        name: 'Prof. Ankit Sir',
        subject: 'Chemistry',
        imageUrl: 'assets/profile.png'),
    Teacher(
        name: 'Prof. Ramswaroop Sir',
        subject: 'Maths',
        imageUrl: 'assets/profile.png'),
  ];

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _changeView(DoubtView newView) {
    if (newView == DoubtView.upload) {
      setState(() {
        _attachedImage = null;
        _audioPath = null;
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
        _audioPath = null;
      });
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Microphone permission is required to record audio.')),
      );
      return;
    }

    try {
      final directory = Directory.systemTemp;
      final path = '${directory.path}/audio_doubt.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error Starting Recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
        _attachedImage = null;
      });
    } catch (e) {
      print('Error Stopping Recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_audioPath != null) {
      try {
        await _audioPlayer.setFilePath(_audioPath!);
        _audioPlayer.play();
      } catch (e) {
        print("Error playing audio: $e");
      }
    }
  }

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
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _doubts.length,
        itemBuilder: (context, index) => _buildDoubtCard(_doubts[index], index),
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

  Widget _buildDoubtCard(Doubt doubt, int index) {
    final bool isPending = doubt.status == 'Pending';
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
                        Text(doubt.status,
                            style: TextStyle(
                                color: isPending ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Doubt Topic: ${doubt.topic}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('Sub-topic: ${doubt.subTopic}',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('Submitted: ${doubt.submittedDate}',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(doubt.subject,
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
                                      facultyName: doubt.professor,
                                      doubtTopic: doubt.topic,
                                    )),
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

  Widget _buildDoubtFormView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => _changeView(DoubtView.list),
        ),
        title: const Text('Ask a Doubt',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(
                'Subject',
                _subjects.map((s) => s.name).toList(),
                _selectedSubject,
                (val) => setState(() {
                      _selectedSubject = val;
                      _selectedTopic = null;
                      _selectedSubTopic = null;
                    })),
            const SizedBox(height: 16),
            _buildDropdown(
                'Topic',
                _selectedSubject != null
                    ? _subjects
                        .firstWhere((s) => s.name == _selectedSubject!)
                        .topics
                        .map((t) => t.name)
                        .toList()
                    : [],
                _selectedTopic,
                (val) => setState(() {
                      _selectedTopic = val;
                      _selectedSubTopic = null;
                    })),
            const SizedBox(height: 16),
            _buildDropdown(
                'Sub-topic',
                _selectedTopic != null
                    ? _subjects
                        .firstWhere((s) => s.name == _selectedSubject!)
                        .topics
                        .firstWhere((t) => t.name == _selectedTopic!)
                        .subTopics
                    : [],
                _selectedSubTopic,
                (val) => setState(() {
                      _selectedSubTopic = val;
                    })),
            const SizedBox(height: 24),
            const Text('Select Teacher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._teachers.map((teacher) => _buildTeacherTile(teacher)),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: () => _changeView(DoubtView.upload),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Confirm Selection',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherTile(Teacher teacher) {
    bool isSelected = _selectedTeacher == teacher.name;
    return GestureDetector(
      onTap: () => setState(() => _selectedTeacher = teacher.name),
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
            CircleAvatar(backgroundImage: AssetImage(teacher.imageUrl)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teacher.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(teacher.subject,
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const Spacer(),
            Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Colors.blueAccent)
          ],
        ),
      ),
    );
  }

  Widget _buildDoubtUploadView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => _changeView(DoubtView.form),
        ),
        title: const Text('Upload Doubt',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe your doubt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your doubt here...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            if (_attachedImage != null) _buildImagePreview(),
            if (_audioPath != null) _buildAudioPlayerTile(),
            const Text('Attach a file',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildAttachmentButton(Icons.image_outlined, 'Image',
                    () => _pickImage(ImageSource.gallery)),
                _buildAttachmentButton(
                  _isRecording ? Icons.stop : Icons.mic_none_outlined,
                  _isRecording ? 'Stop Recording' : 'Voice Note',
                  _isRecording ? _stopRecording : _startRecording,
                  isActive: _isRecording,
                ),
                _buildAttachmentButton(
                    Icons.description_outlined, 'Document', () {}),
                _buildAttachmentButton(Icons.camera_alt_outlined, 'Camera',
                    () => _pickImage(ImageSource.camera)),
              ],
            )
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: () => _changeView(DoubtView.list),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Submit Doubt',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

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
                // --- THIS IS THE FIX ---
                backgroundColor: Colors.black54,
                // --- END OF FIX ---
                radius: 12,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.blueAccent),
            onPressed: _playRecording,
          ),
          const Expanded(
            child: Text('Your recorded doubt',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => setState(() => _audioPath = null),
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
