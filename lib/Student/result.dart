import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/service/board_result_service.dart';
import '../student_session_manager.dart';
import 'app_drawer.dart';
import 'models/board_result_model.dart';

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
  final BoardResultService _boardResultService = BoardResultService();

  List<BoardResultResponse>? _results;
  Map<int, TestDetailResponse> _testDetails = {};
  PerformanceResponse? _overallPerformance;
  Map<String, SubjectPerformance>? _subjectPerformance;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _selectedExamType;

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
    print('🔧 DEBUG: Initializing BoardResultService with SessionManager');

    final sessionManager = Provider.of<SessionManager>(context, listen: false);

    if (!sessionManager.isLoggedIn) {
      print('❌ DEBUG: User is not logged in');
      setState(() {
        _errorMessage = 'Please login to view results';
        _isInitialized = false;
      });
      return;
    }

    final authToken = sessionManager.authToken;

    if (authToken == null || authToken.isEmpty) {
      print('❌ DEBUG: Auth token is null or empty');
      setState(() {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isInitialized = false;
      });
      return;
    }

    print('✅ DEBUG: Auth token retrieved from SessionManager');
    print('🔐 DEBUG: Token length: ${authToken.length}');

    _boardResultService.setAuthToken(authToken);

    setState(() {
      _isInitialized = true;
      _errorMessage = null;
    });

    print('✅ DEBUG: BoardResultService initialized successfully');
  }

  Future<void> _fetchBoardResults() async {
    // Check if service is initialized
    if (!_isInitialized) {
      print('⚠️ WARNING: Service not initialized, attempting to initialize first...');
      await _initializeWithSessionManager();

      if (!_isInitialized) {
        print('❌ ERROR: Failed to initialize service');
        setState(() {
          _errorMessage = 'Failed to initialize. Please try again.';
        });
        return;
      }
    }

    print('🔄 DEBUG: Starting to fetch board results from API');
    print('⏰ DEBUG: Fetch started at: ${DateTime.now().toUtc().toIso8601String()}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all results
      final results = await _boardResultService.getMyResults();
      print('✅ DEBUG: Successfully fetched ${results.length} results');

      // Fetch test details for each result
      Map<int, TestDetailResponse> testDetails = {};
      for (var result in results) {
        if (!testDetails.containsKey(result.testId)) {
          try {
            final detail = await _boardResultService.getTestDetail(result.testId);
            testDetails[result.testId] = detail;
          } catch (e) {
            print('⚠️ WARNING: Could not fetch test detail for testId ${result.testId}: $e');
          }
        }
      }

      // Fetch overall performance
      PerformanceResponse? performance;
      try {
        performance = await _boardResultService.getOverallPerformance();
      } catch (e) {
        print('⚠️ WARNING: Could not fetch overall performance: $e');
      }

      // Calculate subject-wise performance
      final subjectPerf = _boardResultService.getSubjectWisePerformance(results);

      setState(() {
        _results = results;
        _testDetails = testDetails;
        _overallPerformance = performance;
        _subjectPerformance = subjectPerf;
        _isLoading = false;
      });

      if (results.isEmpty) {
        print('ℹ️ DEBUG: No results found for this student');
      }
    } catch (e) {
      print('❌ DEBUG: Error fetching board results: $e');

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
              onPressed: _fetchBoardResults,
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

    // Fetch results when board view is selected
    if (view == ResultView.board && _results == null && _isInitialized) {
      _fetchBoardResults();
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
        actions: [
          if (_currentView == ResultView.board && _results != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: _fetchBoardResults,
              tooltip: 'Refresh Results',
            ),
        ],
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
        return 'Board Results';
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

  // --- SCREEN 2: COMPETITIVE RESULT (HARDCODED UI) ---
  Widget _buildCompetitiveView() {
    // Hardcoded dummy data
    final dummyResults = [
      {
        'testName': 'JEE Mains Mock Test 1',
        'date': '15 Oct 2024',
        'percentage': 85.5,
        'marksObtained': 256,
        'maxMarks': 300,
        'rank': 12,
        'subjects': ['Physics', 'Chemistry', 'Mathematics'],
      },
      {
        'testName': 'NEET Practice Test 2',
        'date': '22 Oct 2024',
        'percentage': 92.0,
        'marksObtained': 552,
        'maxMarks': 600,
        'rank': 5,
        'subjects': ['Physics', 'Chemistry', 'Biology'],
      },
      {
        'testName': 'CAT Mock Test',
        'date': '5 Nov 2024',
        'percentage': 78.3,
        'marksObtained': 235,
        'maxMarks': 300,
        'rank': 45,
        'subjects': ['Quantitative', 'Verbal', 'Logical Reasoning'],
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card (Hardcoded)
          _buildHardcodedStudentHeader(),
          const SizedBox(height: 24),

          // Overall Statistics (Hardcoded)
          _buildHardcodedOverallStats(),
          const SizedBox(height: 24),

          // Performance Section
          const Text('Subject Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Hardcoded subject performance
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildHardcodedPerformanceIndicator('Physics', 0.88, '8'),
              _buildHardcodedPerformanceIndicator('Chemistry', 0.91, '4'),
              _buildHardcodedPerformanceIndicator('Mathematics', 0.82, '15'),
            ],
          ),

          const SizedBox(height: 24),

          // Test Results List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Test Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${dummyResults.length} tests',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...dummyResults.map((result) => _buildHardcodedTestResultCard(result)),
        ],
      ),
    );
  }

  Widget _buildHardcodedStudentHeader() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '12th JEE Batch',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ID: STU123456',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardcodedOverallStats() {
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
            value: '3',
          ),
          _buildStatItem(
            icon: Icons.trending_up,
            label: 'Avg Score',
            value: '85.3%',
          ),
          _buildStatItem(
            icon: Icons.emoji_events,
            label: 'Best Rank',
            value: '5',
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

  Widget _buildHardcodedPerformanceIndicator(
      String subject, double percentage, String rank) {
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
              color: Color(0xFFEF6C00),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHardcodedTestResultCard(Map<String, dynamic> result) {
    final percentage = result['percentage'] as double;
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
                        result['testName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result['date'],
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
                  '${result['marksObtained']}/${result['maxMarks']}',
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.emoji_events,
                  'Rank ${result['rank']}',
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Subjects:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (result['subjects'] as List<String>).map((subject) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    subject,
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
        ),
      ),
    );
  }

  // --- SCREEN 3: BOARD RESULT (Dynamic with API) ---
  Widget _buildBoardView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading board results...'),
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
              onPressed: () async {
                await _initializeWithSessionManager();
                if (_isInitialized) {
                  _fetchBoardResults();
                }
              },
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
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any test results yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchBoardResults,
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

    // Get available exam types
    final examTypes = _boardResultService
        .groupByExamType(_results!, _testDetails)
        .keys
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card
          _buildStudentHeaderFromAPI(_results!.first),
          const SizedBox(height: 24),

          // Exam Type Filter (if multiple exam types exist)
          if (examTypes.length > 1) ...[
            _buildExamTypeFilter(examTypes),
            const SizedBox(height: 24),
          ],

          // Overall Statistics
          _buildOverallStatistics(),
          const SizedBox(height: 24),

          // Subject Performance Section
          if (_subjectPerformance != null && _subjectPerformance!.isNotEmpty) ...[
            const Text('Subject Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSubjectPerformanceGrid(),
            const SizedBox(height: 24),
          ],

          // Batch Analysis (if available)
          if (_overallPerformance != null) ...[
            _buildBatchAnalysis(),
            const SizedBox(height: 24),
          ],

          // Test Results List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Test Results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${_getFilteredResults().length} test${_getFilteredResults().length > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._getFilteredResults().map((result) => _buildTestResultCard(result)),
        ],
      ),
    );
  }

  List<BoardResultResponse> _getFilteredResults() {
    if (_selectedExamType == null || _selectedExamType == 'All') {
      return _results!;
    }

    return _results!.where((result) {
      final testDetail = _testDetails[result.testId];
      return testDetail?.testTemplate.examType == _selectedExamType;
    }).toList();
  }

  Widget _buildExamTypeFilter(List<String> examTypes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Exam Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All', null),
              ...examTypes.map((type) => _buildFilterChip(type, type)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedExamType == value ||
        (value == null && _selectedExamType == null);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedExamType = value;
        });
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade800,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade800 : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOverallStatistics() {
    if (_results == null || _results!.isEmpty) return const SizedBox.shrink();

    // Calculate overall statistics
    double totalPercentage = 0;
    int totalTests = _results!.length;
    int totalMarksObtained = 0;
    int totalMaxMarks = 0;

    for (var result in _results!) {
      totalPercentage += double.parse(result.percentage);
      totalMarksObtained += int.parse(result.totalMarksObtained);
      totalMaxMarks += int.parse(result.totalMaxMarks);
    }

    double avgPercentage = totalPercentage / totalTests;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.assessment,
                label: 'Tests',
                value: totalTests.toString(),
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                label: 'Avg Score',
                value: '${avgPercentage.toStringAsFixed(1)}%',
              ),
              _buildStatItem(
                icon: Icons.score,
                label: 'Total Marks',
                value: '$totalMarksObtained/$totalMaxMarks',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchAnalysis() {
    if (_overallPerformance == null) return const SizedBox.shrink();

    final analysis = _overallPerformance!.batchAnalysis;

    // Only show if there's meaningful data
    if (analysis.totalStudents == 0) return const SizedBox.shrink();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Batch Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAnalysisItem(
                icon: Icons.groups,
                label: 'Students',
                value: analysis.totalStudents.toString(),
                color: Colors.blue,
              ),
              _buildAnalysisItem(
                icon: Icons.bar_chart,
                label: 'Avg Score',
                value: '${analysis.average.toStringAsFixed(1)}%',
                color: Colors.orange,
              ),
              _buildAnalysisItem(
                icon: Icons.emoji_events,
                label: 'Top Score',
                value: '${analysis.topScore.toStringAsFixed(1)}%',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentHeaderFromAPI(BoardResultResponse result) {
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
                colors: [Colors.green.shade300, Colors.green.shade600],
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
                  'Student ID: ${result.studentId.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceGrid() {
    if (_subjectPerformance == null || _subjectPerformance!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _subjectPerformance!.entries.map((entry) {
        return _buildSubjectPerformanceCard(entry.value);
      }).toList(),
    );
  }

  Widget _buildSubjectPerformanceCard(SubjectPerformance performance) {
    final percentage = performance.averagePercentage;
    final color = _getGradeColor(percentage);

    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    performance.grade,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            performance.subjectName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${performance.totalTests} test${performance.totalTests > 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${performance.totalMarksObtained}/${performance.totalMaxMarks}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard(BoardResultResponse result) {
    final percentage = double.parse(result.percentage);
    final gradeColor = _getGradeColor(percentage);
    final testDetail = _testDetails[result.testId];

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
                      if (testDetail != null) ...[
                        Text(
                          testDetail.testTemplate.name,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
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
                if (testDetail != null)
                  _buildInfoChip(
                    Icons.category,
                    testDetail.testTemplate.examType,
                    Colors.purple,
                  ),
                if (result.rank != null) ...[
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.emoji_events,
                    'Rank ${result.rank}',
                    Colors.orange,
                  ),
                ],
              ],
            ),
            if (result.test.testStructure.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Subjects & Topics:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...result.test.testStructure.map((structure) {
                final marksObtained = result.marks[structure.id] ?? '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              structure.displayName,  // ✅ Using helper
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              structure.displayTopic,  // ✅ Using helper
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '$marksObtained/${structure.maxMarks}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}