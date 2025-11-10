import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../student_profile_provider.dart';
import 'app_drawer.dart';
import 'assignment.dart';
import 'attendance.dart';
import 'courses.dart';
import 'doubt_lecture_screen.dart';
import 'doubts.dart';
import 'feedback.dart';
import 'notification.dart';
import 'result.dart';
import 'student_id.dart';
import 'timetable.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load student profile when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final provider =
        Provider.of<StudentProfileProvider>(context, listen: false);
    if (!provider.hasData && !provider.isLoading) {
      await provider.loadStudentProfile();
    }
  }

  Future<void> _refreshProfile() async {
    final provider =
        Provider.of<StudentProfileProvider>(context, listen: false);
    await provider.refreshProfile();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: Consumer<StudentProfileProvider>(
            builder: (context, profileProvider, child) {
              // Show loading only when there's no data yet
              if (profileProvider.isLoading && !profileProvider.hasData) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your profile...'),
                    ],
                  ),
                );
              }

              // Show error state
              if (profileProvider.errorMessage != null &&
                  !profileProvider.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to Load Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profileProvider.errorMessage ?? 'Unknown error',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppBar(profileProvider),
                      const SizedBox(height: 24),
                      _buildStudentInfoCard(profileProvider),
                      const SizedBox(height: 24),
                      _buildTopCards(),
                      const SizedBox(height: 24),
                      _buildGridView(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(StudentProfileProvider profileProvider) {
    final studentName = profileProvider.studentName;
    final photoUrl = profileProvider.photoUrl;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54, size: 30),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                studentName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon:
              const Icon(Icons.notifications_none_rounded, color: Colors.grey),
          onPressed: () => _navigateTo(const NotificationsScreen()),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundImage: photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : const AssetImage('assets/profile.png') as ImageProvider,
          backgroundColor: Colors.grey[200],
          onBackgroundImageError: photoUrl.isNotEmpty
              ? (exception, stackTrace) {
                  print('⚠️ Error loading profile image: $exception');
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildStudentInfoCard(StudentProfileProvider profileProvider) {
    final studentName = profileProvider.studentName;
    final photoUrl = profileProvider.photoUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/profile.png') as ImageProvider,
            backgroundColor: Colors.grey[200],
            onBackgroundImageError: photoUrl.isNotEmpty
                ? (exception, stackTrace) {
                    print('⚠️ Error loading profile image: $exception');
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTopCards() {
    return Row(
      children: [
        Expanded(
          child: _buildTopCard(
            color: const Color(0xFFFE7453),
            title: 'Crash Courses',
            subtitle: 'Intensive learning',
            buttonText: 'Explore',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTopCard(
            color: const Color(0xFF28C27D),
            title: 'Free Lectures',
            subtitle: 'Knowledge for all',
            buttonText: 'Watch Now',
          ),
        ),
      ],
    );
  }

  Widget _buildTopCard({
    required Color color,
    required String title,
    required String subtitle,
    required String buttonText,
  }) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final List<Map<String, dynamic>> gridItems = [
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Attendance',
        'onTap': () => _navigateTo(const AttendanceScreen())
      },
      {
        'icon': Icons.school_outlined,
        'label': 'Courses',
        'onTap': () => _navigateTo(const CoursesScreen())
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Timetable',
        'onTap': () => _navigateTo(const TimetableScreen())
      },
      {
        'icon': Icons.question_answer_outlined,
        'label': 'Doubt Lecture',
        'onTap': () => _navigateTo(const DoubtLectureScreen())
      },
      {
        'icon': Icons.assignment_outlined,
        'label': 'Assignments',
        'onTap': () => _navigateTo(const AssignmentsScreen())
      },
      {
        'icon': Icons.help_outline,
        'label': 'Doubts',
        'onTap': () => _navigateTo(const DoubtsScreen())
      },
      {'icon': Icons.quiz_outlined, 'label': 'Test Portal', 'onTap': () {}},
      {
        'icon': Icons.person_pin_outlined,
        'label': 'Student ID Card',
        'onTap': () => _navigateTo(const StudentIdScreen())
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'Results',
        'onTap': () => _navigateTo(const ResultsScreen())
      },
      {
        'icon': Icons.feedback_outlined,
        'label': 'Feedback',
        'onTap': () => _navigateTo(const FeedbackScreen())
      },
    ];

    final List<Color> cardColors = [
      Colors.orange.shade300,
      Colors.blue.shade300,
      Colors.teal.shade300,
      Colors.lime.shade400,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.green.shade300,
      Colors.indigo.shade300,
      Colors.pink.shade300,
      Colors.amber.shade300,
      Colors.cyan.shade300,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return _buildGridItem(
          gridItems[index]['icon'],
          gridItems[index]['label'],
          gridItems[index]['onTap'],
          cardColors[index % cardColors.length],
        );
      },
    );
  }

  Widget _buildGridItem(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return Card(
      elevation: 2,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
