import 'package:flutter/material.dart';

import 'app_drawer.dart'; // Import the shared app drawer

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

  void _setView(ResultView view) {
    setState(() {
      _currentView = view;
    });
  }

  // Handles back navigation within this multi-part screen
  void _goBack() {
    if (_currentView != ResultView.typeSelection) {
      setState(() {
        _currentView = ResultView.typeSelection;
      });
    } else {
      // If on the first screen, default back action will be handled by drawer or system
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canGoBackInternally = _currentView != ResultView.typeSelection;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(), // Add the shared drawer here
      appBar: AppBar(
        // Conditionally show menu icon or back arrow
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
    return Padding(
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
            onTap: () => _setView(ResultView.competitive),
          ),
          const SizedBox(height: 20),
          _buildResultTypeCard(
            title: 'Board Result',
            description:
                'Access your official board exam results and transcripts.',
            onTap: () => _setView(ResultView.board),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTypeCard(
      {required String title,
      required String description,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder for the image background
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 5, color: Colors.black45)
                        ]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Results',
                    style: TextStyle(
                        color: Colors.blueAccent[700],
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward,
                      color: Colors.blueAccent[700], size: 18),
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
    return DefaultTabController(
      length: 3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info
            _buildStudentHeader('Aryan Sharma', '12th JEE', 'S12345'),
            const SizedBox(height: 24),
            // Performance Section
            const Text('Monthly Subject-Wise Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceIndicator('Physics', 0.85, '5/30'),
                _buildPerformanceIndicator('Chemistry', 0.92, '3/30'),
                _buildPerformanceIndicator('Math', 0.78, '10/30'),
              ],
            ),
            const SizedBox(height: 24),
            // Leaderboard Section
            const Text('Class Leaderboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const TabBar(
              tabs: [
                Tab(text: 'Physics'),
                Tab(text: 'Chemistry'),
                Tab(text: 'Math')
              ],
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
            ),
            SizedBox(
              height: 250, // Give the TabBarView a fixed height
              child: TabBarView(
                children: [
                  _buildLeaderboardList(),
                  _buildLeaderboardList(), // Using same list for demo
                  _buildLeaderboardList(), // Using same list for demo
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(String name, String className, String studentId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 30, backgroundImage: AssetImage('assets/profile.png')),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$className • Student ID: $studentId',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(
      String subject, double percentage, String rank) {
    return Column(
      children: [
        SizedBox(
          height: 90,
          width: 90,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage,
                strokeWidth: 8,
                backgroundColor: Colors.grey[200],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              Center(
                  child: Text('${(percentage * 100).toInt()}%',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Rank: $rank', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    // Dummy data for leaderboard with Indian names
    final leaders = [
      {'rank': 1, 'name': 'Priya Sharma', 'score': '95%'},
      {'rank': 2, 'name': 'Rohan Verma', 'score': '93%'},
      {'rank': 3, 'name': 'Aryan Sharma (You)', 'score': '92%'},
    ];
    return ListView.builder(
      itemCount: leaders.length,
      itemBuilder: (context, index) {
        final leader = leaders[index];
        bool isYou = (leader['name'] as String).contains('You');
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isYou ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isYou ? Border.all(color: Colors.blueAccent) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Text((leader['rank']).toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/profile.png')),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(leader['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500))),
              Text(leader['score'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Icon(Icons.star,
                  color: isYou ? Colors.blueAccent : Colors.orangeAccent,
                  size: 20)
            ],
          ),
        );
      },
    );
  }

  // --- SCREEN 3: BOARD RESULT ---
  Widget _buildBoardView() {
    String? selectedBoard = 'CBSE';
    // Dummy Data
    final subjects = [
      {
        'icon': Icons.book_outlined,
        'name': 'English',
        'code': 'ENG101',
        'score': '85/100'
      },
      {
        'icon': Icons.calculate_outlined,
        'name': 'Mathematics',
        'code': 'MATH101',
        'score': '92/100'
      },
      {
        'icon': Icons.science_outlined,
        'name': 'Science',
        'code': 'SCI101',
        'score': '78/100'
      },
      {
        'icon': Icons.public_outlined,
        'name': 'Social Studies',
        'code': 'SOC101',
        'score': '88/100'
      },
      {
        'icon': Icons.translate_outlined,
        'name': 'Second Language',
        'code': 'LANG101',
        'score': '90/100'
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Aryan Sharma",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("12th JEE • Unique ID: 123456",
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                const Spacer(),
                const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/profile.png')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Board Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
                  labelText: 'Exam Board', border: InputBorder.none),
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
              _buildPerformanceSummaryCard(
                  'Total Marks', '433/500', Colors.blue),
              _buildPerformanceSummaryCard('Percentage', '86.6%', Colors.green),
              _buildPerformanceSummaryCard('Rank', '12/250', Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSubjectScoreTile(
      IconData icon, String name, String code, String score) {
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
