import 'package:flutter/material.dart';

import 'parent_app_drawer.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedPeriod = 'Weekly';
  final List<Map<String, String>> _detailedReport = [
    {
      'date': 'Jul 20, 2024',
      'time': '09:00 AM - 03:00 PM',
      'status': 'Present'
    },
    {
      'date': 'Jul 19, 2024',
      'time': '09:00 AM - 03:00 PM',
      'status': 'Present'
    },
    {
      'date': 'Jul 18, 2024',
      'time': '09:15 AM - 03:00 PM',
      'status': 'Partially Present'
    },
    {'date': 'Jul 17, 2024', 'time': 'N/A', 'status': 'Absent'},
    {
      'date': 'Jul 16, 2024',
      'time': '09:00 AM - 03:00 PM',
      'status': 'Present'
    },
    {
      'date': 'Jul 15, 2024',
      'time': '09:00 AM - 03:00 PM',
      'status': 'Present'
    },
    {
      'date': 'Jul 14, 2024',
      'time': '09:00 AM - 03:00 PM',
      'status': 'Present'
    },
    {'date': 'Jul 13, 2024', 'time': '09:00 AM - 03:00 PM', 'status': 'Absent'},
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
        title: const Text('Attendance Report',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.black54),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading report...')),
              );
            },
          ),
        ],
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
            const Text('Detailed Report',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._detailedReport
                .take(5)
                .map((report) => _buildDetailedReportCard(report)),
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Loading more attendance data...')),
                  );
                },
                child: const Text('View More',
                    style: TextStyle(color: Colors.blueAccent)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Analytics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPeriodToggle(),
            const SizedBox(height: 16),
            _buildAnalyticsCard(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // THESE METHODS WERE MISSING - THEY ARE NOW INCLUDED
  // --------------------------------------------------------------------------

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
            radius: 40,
            backgroundImage: AssetImage('assets/aryan_profile.png'),
            backgroundColor: Colors.blueGrey,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Student',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                'Aryan Sharma',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Text(
                '11th JEE MAINS',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReportCard(Map<String, String> report) {
    Color statusColor;
    Color backgroundColor;
    switch (report['status']) {
      case 'Present':
        statusColor = Colors.green.shade700;
        backgroundColor = Colors.green.shade50;
        break;
      case 'Absent':
        statusColor = Colors.red.shade700;
        backgroundColor = Colors.red.shade50;
        break;
      case 'Partially Present':
        statusColor = Colors.orange.shade700;
        backgroundColor = Colors.orange.shade50;
        break;
      default:
        statusColor = Colors.grey.shade700;
        backgroundColor = Colors.grey.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['date']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  report['time']!,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report['status']!,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Weekly'),
          _buildToggleButton('Monthly'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String period) {
    final bool isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    final List<double> weeklyData = [0.8, 0.9, 0.75, 0.95];
    final List<double> monthlyData = [0.92, 0.88, 0.95, 0.90, 0.85, 0.93];
    final List<String> weeklyLabels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
    final List<String> monthlyLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun'
    ];

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Overall Attendance', style: TextStyle(color: Colors.grey)),
              Text('+5% vs last month',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '95%',
            style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: HistogramPainter(
                data: _selectedPeriod == 'Weekly' ? weeklyData : monthlyData,
                labels:
                    _selectedPeriod == 'Weekly' ? weeklyLabels : monthlyLabels,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class HistogramPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;

  HistogramPainter({required this.data, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint barPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double barWidth = (size.width - (data.length - 1) * 10) / data.length;
    const double barSpacing = 10.0;
    const double maxBarHeight = 100.0;

    double currentX = 0;

    for (int i = 0; i < data.length; i++) {
      final double barHeight = data[i] * maxBarHeight;
      final RRect bar = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          currentX,
          size.height - barHeight - 20,
          barWidth,
          barHeight,
        ),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      );

      canvas.drawRRect(bar, barPaint);
      canvas.drawRRect(bar, outlinePaint);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(currentX + (barWidth / 2) - (textPainter.width / 2),
            size.height - textPainter.height),
      );

      currentX += barWidth + barSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is HistogramPainter) {
      return oldDelegate.data != data || oldDelegate.labels != labels;
    }
    return true;
  }
}
