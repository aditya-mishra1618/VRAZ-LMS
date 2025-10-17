import 'package:flutter/material.dart';

import 'teacher_app_drawer.dart'; // Import your central drawer

// Data model for a student's ranking
class StudentRank {
  final int rank;
  final String name;
  final String rollNo;
  final int percentage;

  const StudentRank({
    required this.rank,
    required this.name,
    required this.rollNo,
    required this.percentage,
  });
}

class StudentPerformanceScreen extends StatelessWidget {
  const StudentPerformanceScreen({super.key});

  // Dummy data with Indian names for the leaderboard
  final List<StudentRank> _leaderboard = const [
    StudentRank(rank: 1, name: 'Aarav Sharma', rollNo: '12345', percentage: 95),
    StudentRank(rank: 2, name: 'Diya Patel', rollNo: '67890', percentage: 92),
    StudentRank(rank: 3, name: 'Vihaan Singh', rollNo: '24680', percentage: 90),
    StudentRank(rank: 4, name: 'Ananya Reddy', rollNo: '13579', percentage: 88),
    StudentRank(rank: 5, name: 'Ishaan Gupta', rollNo: '97531', percentage: 85),
    StudentRank(rank: 6, name: 'Saanvi Kumar', rollNo: '86420', percentage: 82),
    StudentRank(rank: 7, name: 'Arjun Desai', rollNo: '11223', percentage: 80),
    StudentRank(rank: 8, name: 'Myra Iyer', rollNo: '77445', percentage: 78),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      // --- ADD THE DRAWER ---
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        // --- REMOVED THE LEADING BACK BUTTON ---
        title: const Text('Leaderboard',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildFilterChip(),
            const SizedBox(height: 20),
            _buildLeaderboardList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Class 12th',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('JEE Mains',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Physics, Chemistry, Maths',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Image.asset('assets/profile.png', height: 60), // Placeholder image
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ChoiceChip(
        label: const Text('Maths'),
        selected: true, // Always selected for the Maths teacher
        onSelected: (selected) {},
        backgroundColor: Colors.white,
        selectedColor: Colors.blue[50],
        labelStyle:
            TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.blue[100]!),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _leaderboard.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = _leaderboard[index];
        return _buildRankItem(student);
      },
    );
  }

  Widget _buildRankItem(StudentRank student) {
    final bool isTopThree = student.rank <= 3;
    Color trophyColor;
    if (student.rank == 1) {
      trophyColor = Colors.amber;
    } else if (student.rank == 2) {
      trophyColor = Colors.grey[400]!;
    } else {
      trophyColor = Colors.brown[400]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          isTopThree
              ? Icon(Icons.emoji_events, color: trophyColor, size: 28)
              : Text(
                  student.rank.toString(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                'Roll No: ${student.rollNo}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${student.percentage}%',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}
