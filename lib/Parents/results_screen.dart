import 'dart:math';

import 'package:flutter/material.dart';

import 'parent_app_drawer.dart';

// --- 1. Main Results Selection Screen ---
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Results',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const ParentAppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Result Type',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 20),
            _buildResultCard(
              context,
              title: 'Competitive Result',
              description:
                  'View your results from competitive exams and assessments.',
              screen: const CompetitiveResultScreen(),
              imagePath: 'assets/competitive.jpg',
            ),
            const SizedBox(height: 20),
            _buildResultCard(
              context,
              title: 'Board Result',
              description:
                  'Access your official board exam results and transcripts.',
              screen: const BoardResultScreen(),
              imagePath: 'assets/board.jpg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context,
      {required String title,
      required String description,
      required Widget screen,
      required String imagePath}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => screen),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Results',
                    style: TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.blueAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. Competitive Result Screen (Academic Performance) ---
class CompetitiveResultScreen extends StatelessWidget {
  const CompetitiveResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Academic Performance',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentInfo(),
            const SizedBox(height: 24),
            const Text('Monthly Subject-Wise Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSubjectPerformance(),
            const SizedBox(height: 24),
            const Text('Class Leaderboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildLeaderboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile.png'),
            backgroundColor: Colors.blueGrey,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Aryan Sharma',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Text(
                '11th JEE',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              Text(
                'Student ID: S12345',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformance() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCircularIndicator('Physics', 0.85, '85%', 'Rank: 5/30'),
        _buildCircularIndicator('Chemistry', 0.92, '92%', 'Rank: 3/30'),
        _buildCircularIndicator('Math', 0.78, '78%', 'Rank: 10/30'),
      ],
    );
  }

  Widget _buildCircularIndicator(
      String subject, double percentage, String label, String rank) {
    return Column(
      children: [
        Text(subject,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: CircleProgressPainter(percentage: percentage),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(rank, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildLeaderboard() {
    final List<Map<String, dynamic>> leaderboardData = [
      {'rank': 1, 'name': 'Abhishek Singh', 'score': '95%', 'isUser': false},
      {'rank': 2, 'name': 'Aniket PAtil', 'score': '93%', 'isUser': false},
      {'rank': 3, 'name': 'Aryan Sharma (You)', 'score': '92%', 'isUser': true},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text('Physics', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 20),
              Text('Chemistry'),
              SizedBox(width: 20),
              Text('Math'),
            ],
          ),
          const Divider(height: 20),
          ...leaderboardData.map((data) => _buildLeaderboardItem(data)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: data['isUser']
          ? const EdgeInsets.symmetric(vertical: 10, horizontal: 8)
          : null,
      decoration: BoxDecoration(
        color: data['isUser'] ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data['isUser'] ? Colors.blueAccent : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${data['rank']}',
              style: TextStyle(
                  color: data['isUser'] ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/profile_dummy.png'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(data['score'], style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.star, color: Colors.orange, size: 20),
        ],
      ),
    );
  }
}

// --- Custom Painter for the Circular Progress Indicator ---
class CircleProgressPainter extends CustomPainter {
  final double percentage;

  CircleProgressPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    Paint progressPaint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, backgroundPaint);

    double sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// --- 3. Board Result Screen ---
class BoardResultScreen extends StatelessWidget {
  const BoardResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Board Result',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBoardStudentInfo(),
            const SizedBox(height: 24),
            _buildSubjectResults(),
            const SizedBox(height: 24),
            _buildOverallPerformance(),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aryan Sharma',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const Text(
                '11th JEE',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              Text(
                'Unique ID: 123456',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Exam Board',
                      style: TextStyle(color: Colors.black87)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Text('CBSE',
                            style: TextStyle(color: Colors.blueAccent)),
                        Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile.png'),
            backgroundColor: Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectResults() {
    final List<Map<String, dynamic>> subjectData = [
      {
        'name': 'English',
        'code': 'ENG101',
        'score': '85/100',
        'icon': Icons.book_outlined
      },
      {
        'name': 'Mathematics',
        'code': 'MATH101',
        'score': '92/100',
        'icon': Icons.calculate_outlined
      },
      {
        'name': 'Physics',
        'code': 'PHY101',
        'score': '78/100',
        'icon': Icons.science_outlined
      },
      {
        'name': 'Chemistry',
        'code': 'CHEM101',
        'score': '88/100',
        'icon': Icons.public_outlined
      },
      {
        'name': 'Second Language',
        'code': 'LANG101',
        'score': '90/100',
        'icon': Icons.translate_outlined
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            subjectData.map((subject) => _buildSubjectItem(subject)).toList(),
      ),
    );
  }

  Widget _buildSubjectItem(Map<String, dynamic> subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Icon(subject['icon'], color: Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subject['code'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(subject['score'],
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOverallPerformance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overall Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPerformanceBox('Total Marks', '433/500'),
            _buildPerformanceBox('Percentage', '86.6%'),
            _buildPerformanceBox('Rank', '12/250'),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceBox(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200, width: 1),
        ),
        child: Column(
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueAccent)),
          ],
        ),
      ),
    );
  }
}
