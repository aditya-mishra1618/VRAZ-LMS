import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../student_session_manager.dart';
import 'app_drawer.dart';
import 'models/board_result_model.dart';
import 'service/board_result_service.dart';

// --- UPDATED: New views for navigation ---
enum ResultView {
  typeSelection,
  competitive,
  boardList, // The list of tests
  boardPerformance, // The details of one test
  subjectPerformance // The details of one subject
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ResultView _currentView = ResultView.typeSelection;
  final BoardResultService _boardResultService = BoardResultService();

  // --- STATE FOR NEW SCREENS ---
  BoardResultResponse? _selectedResult;
  TestStructure? _selectedSubject;
  PerformanceResponse? _testPerformance;
  SubjectPerformanceResponse? _subjectPerformance;
  SubjectPerformanceResponse? _overallCompetitivePerformance;

  // --- RENAMED CLASSES TO MATCH YOUR FILES ---
  List<BoardResultResponse>? _results;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🎬 DEBUG: ResultsScreen initialized');
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

    _boardResultService.setAuthToken(authToken);
    setState(() {
      _isInitialized = true;
      _errorMessage = null;
    });
    print('✅ DEBUG: BoardResultService initialized successfully');
  }

  // --- Renamed to fetchBoardResultsList ---
  Future<void> _fetchBoardResultsList() async {
    if (!_isInitialized) {
      print('⚠️ WARNING: Service not initialized, skipping fetch.');
      await _initializeWithSessionManager(); // Try to init again
      if (!_isInitialized) return;
    }

    print('🔄 DEBUG: Starting to fetch board results from API');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _boardResultService.getMyResults();
      print('✅ DEBUG: Successfully fetched ${results.length} results');

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }

      if (results.isEmpty) {
        print('ℹ️ DEBUG: No results found for this student');
      }
    } catch (e) {
      print('❌ DEBUG: Error fetching board results: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchBoardResultsList,
            ),
          ),
        );
      }
    }
  }

  // --- NEW: Function to load data for the performance screen ---
  Future<void> _fetchPerformanceDetails(BoardResultResponse result) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedResult = result; // Store the selected result
      _currentView = ResultView.boardPerformance;
    });

    try {
      // Fetch test performance (includes leaderboard)
      final performance =
          await _boardResultService.getTestPerformance(result.testId);

      if (mounted) {
        setState(() {
          _testPerformance = performance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // --- NEW: Function to load data for the subject screen ---
  Future<void> _fetchSubjectDetails(TestStructure subject) async {
    if (_selectedResult == null || subject.subjectId == null) {
      _showSnackBar("This subject has no detailed data.", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedSubject = subject;
      _currentView = ResultView.subjectPerformance;
    });

    try {
      final performance =
          await _boardResultService.getSubjectPerformance(subject.subjectId!);

      if (mounted) {
        setState(() {
          _subjectPerformance = performance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // --- NEW: Function to load data for competitive view ---
  Future<void> _fetchCompetitiveResults() async {
    if (!_isInitialized) {
      await _initializeWithSessionManager();
      if (!_isInitialized) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentView = ResultView.competitive;
    });

    try {
      // Use the overall performance API for this screen
      final performance = await _boardResultService.getOverallPerformance();
      if (mounted) {
        setState(() {
          _overallCompetitivePerformance = performance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _setView(ResultView view) {
    if (view == ResultView.boardList) {
      setState(() {
        _currentView = ResultView.boardList;
      });
      if (_results == null && _isInitialized) {
        _fetchBoardResultsList();
      }
    } else if (view == ResultView.competitive) {
      _fetchCompetitiveResults();
    } else {
      setState(() {
        _currentView = view;
      });
    }
  }

  // --- UPDATED: New back navigation logic ---
  void _goBack() {
    if (_currentView == ResultView.subjectPerformance) {
      setState(() {
        _currentView = ResultView.boardPerformance;
        _selectedSubject = null; // Clear subject selection
        _subjectPerformance = null;
      });
    } else if (_currentView == ResultView.boardPerformance) {
      setState(() {
        _currentView = ResultView.boardList;
        _selectedResult = null; // Clear result selection
        _testPerformance = null;
      });
    } else if (_currentView == ResultView.boardList ||
        _currentView == ResultView.competitive) {
      setState(() {
        _currentView = ResultView.typeSelection;
        _errorMessage = null; // Clear errors when going back to selection
      });
    } else {
      // If we are on the main selection screen, pop the route
      Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ));
    }
  }

  // --- UI Building ---

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
          if (_currentView == ResultView.boardList && _results != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: _fetchBoardResultsList,
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
      case ResultView.boardList:
        return 'Board Results';
      case ResultView.boardPerformance:
        return _selectedResult?.test.name ?? 'Performance';
      case ResultView.subjectPerformance:
        return _selectedSubject?.displayName ?? 'Subject';
    }
  }

  Widget _buildCurrentView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: () {
                // Retry logic based on the current view
                if (_currentView == ResultView.boardList) {
                  _fetchBoardResultsList();
                } else if (_currentView == ResultView.boardPerformance &&
                    _selectedResult != null) {
                  _fetchPerformanceDetails(_selectedResult!);
                } else if (_currentView == ResultView.subjectPerformance &&
                    _selectedSubject != null) {
                  _fetchSubjectDetails(_selectedSubject!);
                } else if (_currentView == ResultView.competitive) {
                  _fetchCompetitiveResults();
                } else {
                  _initializeWithSessionManager();
                }
              },
              child: const Text('Retry'))
        ]),
      ));
    }

    switch (_currentView) {
      case ResultView.typeSelection:
        return _buildTypeSelectionView();
      case ResultView.competitive:
        return _buildCompetitiveView();
      case ResultView.boardList:
        return _buildBoardTestListView();
      case ResultView.boardPerformance:
        return _buildBoardPerformanceView();
      case ResultView.subjectPerformance:
        return _buildSubjectPerformanceView();
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
            onTap: () => _setView(ResultView.boardList), // Go to list first
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

  // --- SCREEN 2: COMPETITIVE RESULT (NOW DYNAMIC) ---
  Widget _buildCompetitiveView() {
    if (_overallCompetitivePerformance == null) {
      return const Center(
          child: Text("No competitive performance data found."));
    }

    final performance = _overallCompetitivePerformance!;
    final myPerformance = performance.myPerformance;
    final batchAnalysis = performance.batchAnalysis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Statistics
          _buildOverallStatisticsCard(
            BoardResultResponse(
              // Create a dummy response to reuse the widget
              id: 0,
              testId: 0,
              studentId: '',
              batchId: 0,
              marks: {},
              totalMarksObtained: myPerformance.score.toString(),
              totalMaxMarks: myPerformance.total.toString(),
              percentage: myPerformance.percentage.toString(),
              rank: myPerformance.rank,
              test: Test(name: '', date: '', testStructure: []),
              batch: Batch(name: ''),
            ),
          ),
          const SizedBox(height: 24),

          // Batch Analysis
          _buildBatchAnalysisCard(batchAnalysis),
          const SizedBox(height: 24),

          // Leaderboard
          _buildLeaderboardCard(performance.leaderboard,
              title: "Overall Leaderboard"),
          const SizedBox(height: 24),

          // Test Results List
          const Text('Recent Test Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...performance.myScoresList.map((test) => _buildSimpleTestCard(test)),
        ],
      ),
    );
  }

  // --- SCREEN 3: BOARD RESULT LIST (MODIFIED) ---
  Widget _buildBoardTestListView() {
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
              onPressed: _fetchBoardResultsList,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // The Board View is now just a list of tests.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final result = _results![index];
        final percentage = double.tryParse(result.percentage) ?? 0.0;
        final gradeColor = _getGradeColor(percentage);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: gradeColor,
              child: Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              result.test.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _formatDate(result.test.date),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to the performance view
              _fetchPerformanceDetails(result);
            },
          ),
        );
      },
    );
  }

  // --- NEW WIDGET: SCREEN 4 (PERFORMANCE DETAILS) ---
  Widget _buildBoardPerformanceView() {
    if (_selectedResult == null || _testPerformance == null) {
      return const Center(child: Text('No result selected.'));
    }

    final result = _selectedResult!;
    final performance = _testPerformance!;
    final subjects = result.test.testStructure;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallStatisticsCard(result),
          const SizedBox(height: 24),
          _buildBatchAnalysisCard(performance.batchAnalysis),
          const SizedBox(height: 24),
          _buildSubjectPerformanceList(subjects),
          const SizedBox(height: 24),
          _buildLeaderboardCard(performance.leaderboard),
        ],
      ),
    );
  }

  // --- NEW WIDGET: SCREEN 5 (SUBJECT DETAILS) ---
  Widget _buildSubjectPerformanceView() {
    if (_selectedSubject == null ||
        _selectedResult == null ||
        _subjectPerformance == null) {
      return const Center(child: Text('No subject selected.'));
    }
    final subject = _selectedSubject!;
    final result = _selectedResult!;
    final performance = _subjectPerformance!;
    final marks = result.marks[subject.id] ?? 'N/A';
    final percentage = (int.tryParse(marks) ?? 0) / subject.maxMarks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Performance Card
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    subject.displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (subject.displayTopic != 'Unnamed Topic')
                    Text(
                      subject.displayTopic,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    width: 120,
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
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$marks / ${subject.maxMarks}',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text('Marks Obtained (in this test)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildBatchAnalysisCard(performance.batchAnalysis),
          const SizedBox(height: 24),
          _buildLeaderboardCard(performance.leaderboard,
              title: "Subject Leaderboard (Overall)"),
        ],
      ),
    );
  }

  // --- WIDGETS FOR PERFORMANCE SCREEN ---

  Widget _buildOverallStatisticsCard(BoardResultResponse result) {
    double percentage = double.tryParse(result.percentage) ?? 0.0;
    Color gradeColor = _getGradeColor(percentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradeColor.withOpacity(0.7), gradeColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradeColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Performance',
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
                icon: Icons.check_circle_outline,
                label: 'Percentage',
                value: '${percentage.toStringAsFixed(1)}%',
              ),
              _buildStatItem(
                icon: Icons.score,
                label: 'Marks',
                value: '${result.totalMarksObtained}/${result.totalMaxMarks}',
              ),
              _buildStatItem(
                icon: Icons.emoji_events,
                label: 'Rank',
                value: result.rank?.toString() ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchAnalysisCard(BatchAnalysis analysis) {
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

  Widget _buildSubjectPerformanceList(List<TestStructure> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            final marks = _selectedResult!.marks[subject.id] ?? '0';
            final percentage = (int.tryParse(marks) ?? 0) / subject.maxMarks;
            final color = _getGradeColor(percentage * 100);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                title: Text(subject.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Marks: $marks / ${subject.maxMarks}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to subject detail view
                  _fetchSubjectDetails(subject);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(List<LeaderboardEntry>? leaderboard,
      {String title = "Batch Leaderboard"}) {
    if (leaderboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (leaderboard.isEmpty) {
      return const Center(child: Text("No leaderboard data available."));
    }

    // Find "you" in the leaderboard (mock logic)
    final myEntry = leaderboard.firstWhere(
      (entry) =>
          entry.studentName == "Kumar Kalani", // This is you from the API
      orElse: () => LeaderboardEntry(rank: 0, studentName: '', score: 0),
    );
    final bool isYouInTopList = leaderboard.contains(myEntry);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                final bool isYou = entry.rank == myEntry.rank;
                return ListTile(
                  dense: true,
                  leading: Text(
                    '#${entry.rank}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isYou ? Colors.blueAccent : Colors.black87),
                  ),
                  title: Text(
                    isYou ? 'You (${entry.studentName})' : entry.studentName,
                    style: TextStyle(
                        fontWeight:
                            isYou ? FontWeight.bold : FontWeight.normal),
                  ),
                  trailing: Text(
                    '${entry.score} Marks',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isYou ? Colors.blueAccent : Colors.black87),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            )
          ],
        ),
      ),
    );
  }

  /// Helper for the competitive screen's test list
  Widget _buildSimpleTestCard(MyScoresListEntry test) {
    final percentage = double.tryParse(test.percentage) ?? 0.0;
    final gradeColor = _getGradeColor(percentage);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: gradeColor,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          test.testName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _formatDate(test.testDate),
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Find the full result object to navigate
          final fullResult =
              _results?.firstWhere((r) => r.testId == test.testId);
          if (fullResult != null) {
            _fetchPerformanceDetails(fullResult);
          } else {
            _showSnackBar("Could not find details for this test.",
                isError: true);
          }
        },
      ),
    );
  }

  // --- HELPER WIDGETS ---
  // --- MOVED _buildStatItem to be a class method ---
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
      return DateFormat('d MMM yyyY').format(date); // Use intl
    } catch (e) {
      return dateString;
    }
  }

  Color? _getDarkerShade(Color color) {}
}
