import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/Parents/service/attendance_api.dart';

import 'models/attendance_model.dart';
import 'parent_app_drawer.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  List<AttendanceRecord> _allRecords = [];
  AttendanceSummary? _summary;
  bool _isLoading = true;
  String _selectedPeriod = 'Weekly';
  int _displayedRecordsCount = 5;

  String? _authToken;
  int? _selectedChildId;
  String? _selectedChildName;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get auth token and selected child
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('parent_auth_token');
      _selectedChildId = prefs.getInt('selected_child_id');
      _selectedChildName = prefs.getString('selected_child_name');

      print('[AttendanceReport] Auth Token: ${_authToken != null ? "Found" : "Missing"}');
      print('[AttendanceReport] Selected Child ID: $_selectedChildId');

      if (_authToken == null || _authToken!.isEmpty) {
        _showError('Session expired. Please login again.');
        return;
      }

      if (_selectedChildId == null) {
        _showError('No child selected. Please select a child from dashboard.');
        return;
      }

      // 2. Fetch attendance from API
      print('[AttendanceReport] 🔄 Fetching attendance records...');
      _allRecords = await AttendanceApi.fetchChildAttendance(
        authToken: _authToken!,
        childId: _selectedChildId!,
      );

      if (_allRecords.isNotEmpty) {
        _summary = AttendanceApi.calculateSummary(_allRecords);
        print('[AttendanceReport] ✅ Loaded ${_allRecords.length} attendance records');
        print('[AttendanceReport] 📊 Attendance: ${_summary!.attendancePercentageString}');
      } else {
        print('[AttendanceReport] ℹ️ No attendance records found');
        _showInfo('No attendance records available.');
      }
    } catch (e, stackTrace) {
      print('[AttendanceReport] ❌ Error: $e');
      print('[AttendanceReport] Stack trace: $stackTrace');
      _showError('Failed to load attendance. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showInfo(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _loadMoreRecords() {
    setState(() {
      _displayedRecordsCount += 10;
    });
  }

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
        title: const Text(
          'Attendance Report',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _isLoading ? null : _loadAttendanceData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.black54),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📥 Downloading report...')),
              );
            },
            tooltip: 'Download Report',
          ),
        ],
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const ParentAppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAttendanceData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentInfoCard(),
              const SizedBox(height: 24),
              if (_summary != null) ...[
                const Text(
                  'Analytics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPeriodToggle(),
                const SizedBox(height: 16),
                _buildAnalyticsCard(),
                const SizedBox(height: 24),
              ],
              const Text(
                'Detailed Report',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_allRecords.isEmpty)
                _buildEmptyState()
              else ...[
                ..._allRecords
                    .take(_displayedRecordsCount)
                    .map((record) => _buildDetailedReportCard(record)),
                if (_allRecords.length > _displayedRecordsCount)
                  Center(
                    child: TextButton(
                      onPressed: _loadMoreRecords,
                      child: const Text(
                        'View More',
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ),
              ],
            ],
          ),
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
            radius: 40,
            backgroundImage: AssetImage('assets/profile.png'),
            backgroundColor: Colors.blueGrey,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  _selectedChildName ?? 'Student',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_summary != null)
                  Text(
                    'Overall: ${_summary!.attendancePercentageString} (${_summary!.presentDays}/${_summary!.totalDays})',
                    style: TextStyle(
                      color: _summary!.attendancePercentage >= 75
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No attendance records',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReportCard(AttendanceRecord record) {
    Color statusColor;
    Color backgroundColor;

    if (record.isPresent) {
      statusColor = Colors.green.shade700;
      backgroundColor = Colors.green.shade50;
    } else if (record.isAbsent) {
      statusColor = Colors.red.shade700;
      backgroundColor = Colors.red.shade50;
    } else if (record.isLate) {
      statusColor = Colors.orange.shade700;
      backgroundColor = Colors.orange.shade50;
    } else {
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
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        record.formattedTime,
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.book, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        record.subjectName,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.displayStatus,
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
    if (_summary == null) return const SizedBox.shrink();

    final weeklyData = _summary!.getWeeklyPercentages();
    final monthlyData = _summary!.getMonthlyPercentages();

    final now = DateTime.now();
    final weeklyLabels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
    final monthlyLabels = List.generate(6, (i) {
      final monthDate = DateTime(now.year, now.month - (5 - i), 1);
      return DateFormat('MMM').format(monthDate);
    });

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
            children: [
              const Text(
                'Overall Attendance',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                '${_summary!.presentDays}/${_summary!.totalDays} days',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _summary!.attendancePercentageString,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _summary!.attendancePercentage >= 75
                  ? Colors.green
                  : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip('Present', _summary!.presentDays, Colors.green),
              const SizedBox(width: 8),
              _buildStatChip('Absent', _summary!.absentDays, Colors.red),
              if (_summary!.lateDays > 0) ...[
                const SizedBox(width: 8),
                _buildStatChip('Late', _summary!.lateDays, Colors.orange),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: HistogramPainter(
                data: _selectedPeriod == 'Weekly' ? weeklyData : monthlyData,
                labels: _selectedPeriod == 'Weekly' ? weeklyLabels : monthlyLabels,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
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
    if (data.isEmpty || labels.isEmpty) return;

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

      // Draw bar
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

      // Draw label using TextSpan
      final textSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
      );

      textPainter.textDirection = ui.TextDirection.ltr;
      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );

      final offset = Offset(
        currentX + (barWidth / 2) - (textPainter.width / 2),
        size.height - textPainter.height,
      );

      textPainter.paint(canvas, offset);

      currentX += barWidth + barSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! HistogramPainter ||
        oldDelegate.data != data ||
        oldDelegate.labels != labels;
  }
}