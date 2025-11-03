import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/service/result_service.dart';
import '../student_session_manager.dart';
import 'app_drawer.dart';
import 'models/result_model.dart';

// Enum to manage which view is currently visible
enum ResultView { typeSelection, competitive, board }

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ResultView _currentView = ResultView.typeSelection;
  final ResultService _resultService = ResultService();

  List<ResultResponse>? _results;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🎬 DEBUG: ResultsScreen initialized');
    print('📅 DEBUG: Current Date/Time: ${DateTime.now().toUtc().toIso8601String()}');

    // Initialize with SessionManager token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithSessionManager();
    });
  }

  Future<void> _initializeWithSessionManager() async {
    print('🔧 DEBUG: Initializing ResultService with SessionManager');

    final sessionManager = Provider.of<SessionManager>(context, listen: false);

    if (!sessionManager.isLoggedIn) {
      print('❌ DEBUG: User is not logged in');
      setState(() {
        _errorMessage = 'Please login to view results';
      });
      return;
    }

    final authToken = sessionManager.authToken;

    if (authToken == null || authToken.isEmpty) {
      print('❌ DEBUG: Auth token is null or empty');
      setState(() {
        _errorMessage = 'Authentication token not found. Please login again.';
      });
      return;
    }

    print('✅ DEBUG: Auth token retrieved from SessionManager');
    print('🔐 DEBUG: Token preview: ${authToken.substring(0, 20)}...');

    _resultService.setAuthToken(authToken);
  }

  Future<void> _fetchResults() async {
    print('🔄 DEBUG: Starting to fetch results from API');
    print('⏰ DEBUG: Fetch started at: ${DateTime.now().toUtc().toIso8601String()}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _resultService.getMyResults();

      print('✅ DEBUG: Successfully fetched ${results.length} results');

      setState(() {
        _results = results;
        _isLoading = false;
      });

      if (results.isEmpty) {
        print('ℹ️ DEBUG: No results found for this student');
      }
    } catch (e) {
      print('❌ DEBUG: Error fetching results: $e');

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchResults,
            ),
          ),
        );
      }
    }
  }

  void _setView(ResultView view) {
    setState(() {
      _currentView = view;
    });

    // Fetch results when competitive view is selected
    if (view == ResultView.competitive && _results == null) {
      _fetchResults();
    }
  }

  void _goBack() {
    if (_currentView != ResultView.typeSelection) {
      setState(() {
        _currentView = ResultView.typeSelection;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // Helper method to get darker color shades safely
  Color _getDarkerShade(Color color) {
    if (color == Colors.blue) return Colors.blue.shade800;
    if (color == Colors.orange) return Colors.orange.shade800;
    if (color == Colors.green) return Colors.green.shade800;
    if (color == Colors.red) return Colors.red.shade800;

    // Fallback: darken any color by 30%
    return Color.fromARGB(
      color.alpha,
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canGoBackInternally = _currentView != ResultView.typeSelection;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
              canGoBackInternally ? Icons.arrow_back : Icons.menu_rounded,
              color: Colors.black54),
          onPressed: canGoBackInternally
              ? _goBack
              : () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(_getAppBarTitle(),
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildCurrentView(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentView) {
      case ResultView.typeSelection:
        return 'Results';
      case ResultView.competitive:
        return 'Academic Performance';
      case ResultView.board:
        return 'Board Result';
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case ResultView.typeSelection:
        return _buildTypeSelectionView();
      case ResultView.competitive:
        return _buildCompetitiveView();
      case ResultView.board:
        return _buildBoardView();
    }
  }

  // --- SCREEN 1: CHOOSE RESULT TYPE ---
  Widget _buildTypeSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Result Type',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildResultTypeCard(
            title: 'Competitive Result',
            description:
            'View your results from competitive exams and assessments.',
            icon: Icons.emoji_events_outlined,
            color: Colors.blue,
            onTap: () => _setView(ResultView.competitive),
          ),
          const SizedBox(height: 20),
          _buildResultTypeCard(
            title: 'Board Result',
            description:
            'Access your official board exam results and transcripts.',
            icon: Icons.school_outlined,
            color: Colors.green,
            onTap: () => _setView(ResultView.board),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.3,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Results',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: color, size: 16),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- SCREEN 2: COMPETITIVE RESULT (ACADEMIC PERFORMANCE) ---
  Widget _buildCompetitiveView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading results...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error loading results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchResults,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_results == null || _results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any test results yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchResults,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Group results by subject for performance overview
    Map<String, List<ResultResponse>> subjectResults = {};
    for (var result in _results!) {
      for (var structure in result.test.testStructure) {
        if (!subjectResults.containsKey(structure.subjectName)) {
          subjectResults[structure.subjectName] = [];
        }
        // Only add if not already added (avoid duplicates)
        if (!subjectResults[structure.subjectName]!.contains(result)) {
          subjectResults[structure.subjectName]!.add(result);
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card with refresh button
          Row(
            children: [
              Expanded(
                child: _buildStudentHeaderFromAPI(_results!.first),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchResults,
                tooltip: 'Refresh Results',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overall Statistics
          _buildOverallStatistics(),
          const SizedBox(height: 24),

          // Performance Section
          const Text('Subject Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Display performance for each subject
          if (subjectResults.isNotEmpty)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: subjectResults.entries.map((entry) {
                final subjectName = entry.key;
                final results = entry.value;

                // Calculate average percentage for this subject
                double totalPercentage = 0;
                for (var result in results) {
                  totalPercentage += double.parse(result.percentage);
                }
                final avgPercentage = totalPercentage / results.length / 100;

                // Get best rank
                int? bestRank;
                for (var result in results) {
                  if (result.rank != null) {
                    if (bestRank == null || result.rank! < bestRank) {
                      bestRank = result.rank;
                    }
                  }
                }

                return _buildPerformanceIndicator(
                  subjectName,
                  avgPercentage,
                  bestRank?.toString() ?? 'N/A',
                );
              }).toList(),
            )
          else
            Center(
              child: Text(
                'No subject data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),

          const SizedBox(height: 24),

          // Test Results List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Test Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${_results!.length} test${_results!.length > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._results!.map((result) => _buildTestResultCard(result)),
        ],
      ),
    );
  }

  Widget _buildOverallStatistics() {
    if (_results == null || _results!.isEmpty) return const SizedBox.shrink();

    // Calculate overall statistics
    double totalPercentage = 0;
    int totalTests = _results!.length;
    int? bestRank;

    for (var result in _results!) {
      totalPercentage += double.parse(result.percentage);
      if (result.rank != null) {
        if (bestRank == null || result.rank! < bestRank) {
          bestRank = result.rank;
        }
      }
    }

    double avgPercentage = totalPercentage / totalTests;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.assessment,
            label: 'Tests Taken',
            value: totalTests.toString(),
          ),
          _buildStatItem(
            icon: Icons.trending_up,
            label: 'Avg Score',
            value: '${avgPercentage.toStringAsFixed(1)}%',
          ),
          if (bestRank != null)
            _buildStatItem(
              icon: Icons.emoji_events,
              label: 'Best Rank',
              value: bestRank.toString(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentHeaderFromAPI(ResultResponse result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue.shade600],
              ),
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.batch.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${result.studentId.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard(ResultResponse result) {
    final percentage = double.parse(result.percentage);
    final gradeColor = _getGradeColor(percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.test.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(result.test.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: gradeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  Icons.score,
                  '${result.totalMarksObtained}/${result.totalMaxMarks}',
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                if (result.rank != null)
                  _buildInfoChip(
                    Icons.emoji_events,
                    'Rank ${result.rank}',
                    Colors.orange,
                  ),
              ],
            ),
            if (result.test.testStructure.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Subjects:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.test.testStructure.map((structure) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      structure.subjectName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _getDarkerShade(color),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildPerformanceIndicator(String subject, double percentage, String rank) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage,
                strokeWidth: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    _getGradeColor(percentage * 100)),
              ),
              Center(
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subject,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Rank: $rank',
            style: const TextStyle(
              color: Color(0xFFEF6C00), // Orange 800
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // --- SCREEN 3: BOARD RESULT (Dummy Data) ---
  Widget _buildBoardView() {
    String? selectedBoard = 'CBSE';

    final subjects = [
      {'icon': Icons.book_outlined, 'name': 'English', 'code': 'ENG101', 'score': '85/100'},
      {'icon': Icons.calculate_outlined, 'name': 'Mathematics', 'code': 'MATH101', 'score': '92/100'},
      {'icon': Icons.science_outlined, 'name': 'Science', 'code': 'SCI101', 'score': '78/100'},
      {'icon': Icons.public_outlined, 'name': 'Social Studies', 'code': 'SOC101', 'score': '88/100'},
      {'icon': Icons.translate_outlined, 'name': 'Second Language', 'code': 'LANG101', 'score': '90/100'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF1565C0)), // Blue 800
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Board results will be available once published by the board',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade600],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 25),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Student Name",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("12th JEE • ID: 123456",
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Board Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonFormField(
              value: selectedBoard,
              items: ['CBSE', 'ICSE', 'State Board'].map((String board) {
                return DropdownMenuItem(value: board, child: Text(board));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedBoard = newValue;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Exam Board',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subject List
          ...subjects.map((subject) => _buildSubjectScoreTile(
              subject['icon'] as IconData,
              subject['name'] as String,
              subject['code'] as String,
              subject['score'] as String)),
          const SizedBox(height: 24),

          // Overall Performance
          const Text('Overall Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPerformanceSummaryCard('Total Marks', '433/500', Colors.blue),
              _buildPerformanceSummaryCard('Percentage', '86.6%', Colors.green),
              _buildPerformanceSummaryCard('Rank', '12/250', Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSubjectScoreTile(IconData icon, String name, String code, String score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(code),
        trailing: Text(score,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildPerformanceSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color.withOpacity(0.1),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 12)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}