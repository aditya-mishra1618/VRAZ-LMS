import 'package:flutter/material.dart';

import 'parent_app_drawer.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _dailySubjects = const [
    {
      'subject': 'Physics',
      'teacher': 'Zeeshan Sir',
      'time': '09:00 AM - 10:00 AM',
      'icon': Icons.science_outlined,
    },
    {
      'subject': 'Chemistry',
      'teacher': 'Ankit Sir',
      'time': '10:00 AM - 11:00 AM',
      'icon': Icons.science_outlined,
    },
    {
      'subject': 'Mathematics',
      'teacher': 'Ramswaroop Sir',
      'time': '11:00 AM - 12:00 PM',
      'icon': Icons.calculate_outlined,
    },
    {
      'subject': 'Doubt Lecture',
      'teacher': 'Ramswaroop Sir',
      'time': '02:00 PM - 03:00 PM',
      'icon': Icons.help_outline,
    },
  ];

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
        title: const Text('Daily Timetable',
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
            _buildStudentInfoCard(),
            const SizedBox(height: 24),
            _buildCalendar(),
            const SizedBox(height: 24),
            ..._dailySubjects.map((subject) => _buildSubjectCard(subject)),
            const SizedBox(height: 24),
            _buildDownloadButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
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
                '11th JEE MAINS',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              Text(
                'ID: 12345',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.arrow_back_ios)),
              const Text('October 26, 2024',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.arrow_forward_ios)),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            children: [
              const TableRow(
                children: [
                  Center(child: Text('S')),
                  Center(child: Text('M')),
                  Center(child: Text('T')),
                  Center(child: Text('W')),
                  Center(child: Text('T')),
                  Center(child: Text('F')),
                  Center(child: Text('S')),
                ],
              ),
              TableRow(
                children: [
                  _buildDateCell('29', isPlaceholder: true),
                  _buildDateCell('30', isPlaceholder: true),
                  _buildDateCell('1', isPlaceholder: true),
                  _buildDateCell('2', isPlaceholder: true),
                  _buildDateCell('3', isPlaceholder: true),
                  _buildDateCell('4', isPlaceholder: true),
                  _buildDateCell('5', isPlaceholder: true),
                ],
              ),
              TableRow(
                children: [
                  _buildDateCell('6'),
                  _buildDateCell('7'),
                  _buildDateCell('8'),
                  _buildDateCell('9'),
                  _buildDateCell('10'),
                  _buildDateCell('11'),
                  _buildDateCell('12'),
                ],
              ),
              TableRow(
                children: [
                  _buildDateCell('13'),
                  _buildDateCell('14'),
                  _buildDateCell('15'),
                  _buildDateCell('16'),
                  _buildDateCell('17'),
                  _buildDateCell('18'),
                  _buildDateCell('19'),
                ],
              ),
              TableRow(
                children: [
                  _buildDateCell('20'),
                  _buildDateCell('21'),
                  _buildDateCell('22'),
                  _buildDateCell('23'),
                  _buildDateCell('24'),
                  _buildDateCell('25'),
                  _buildDateCell('26', isSelected: true),
                ],
              ),
              TableRow(
                children: [
                  _buildDateCell('27'),
                  _buildDateCell('28'),
                  _buildDateCell('29'),
                  _buildDateCell('30'),
                  _buildDateCell('31'),
                  _buildDateCell('1', isPlaceholder: true),
                  _buildDateCell('2', isPlaceholder: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCell(String date,
      {bool isSelected = false, bool isPlaceholder = false}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.8)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            date,
            style: TextStyle(
              color: isPlaceholder
                  ? Colors.grey
                  : (isSelected ? Colors.white : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(subject['icon'], color: Colors.blueAccent),
        ),
        title: Text(subject['subject'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject['time']),
            Text('Faculty: ${subject['teacher']}',
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading timetable...')),
          );
        },
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text(
          'Download Timetable',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
