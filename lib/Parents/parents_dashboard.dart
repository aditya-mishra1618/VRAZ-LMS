import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Parents/service/parent_child_api.dart';
import 'package:vraz_application/Parents/service/parent_profile_api_service.dart';
import '../parent_session_manager.dart';
import 'Grievance_screen.dart';
import 'attendance_report_screen.dart';
import 'models/parent_child_model.dart';
import 'models/parent_profile_model.dart';
import 'notifications_screen.dart';
import 'parent_app_drawer.dart';
import 'parent_teacher_meeting_screen.dart';
import 'payments_screen.dart';
import 'results_screen.dart';
import 'timetable_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ParentChild> _childrenDetails = [];
  bool _isLoadingChildren = false;
  ParentProfile? _profile;
  bool _isLoadingProfile = false;
  @override
  void initState() {
    super.initState();
    _loadParentData();
    _fetchParentProfile();
    _fetchParentChildren();
  }
  Future<void> _fetchParentChildren() async {
    setState(() => _isLoadingChildren = true);
    final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
    final token = sessionManager.token;
    if (token != null) {
      final childrenList = await ParentChildrenApi.fetchParentChildren(token);
      print('[ParentDashboard] Loaded children: $childrenList');
      setState(() {
        _childrenDetails = childrenList;
        _isLoadingChildren = false;
      });
      sessionManager.setChildrenDetails(childrenList);
    } else {
      setState(() => _isLoadingChildren = false);
    }
  }
  Future<void> _fetchParentProfile() async {
    setState(() => _isLoadingProfile = true);
    final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
    final token = sessionManager.token;
    if (token != null) {
      final profile = await ParentProfileApi.fetchParentProfile(token);
      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    } else {
      setState(() => _isLoadingProfile = false);
    }
  }

  void _loadParentData() {
    final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
    final parent = sessionManager.currentParent;

    debugPrint('[ParentDashboard] 👤 Loaded parent: ${parent?.fullName}');
    debugPrint('[ParentDashboard] 👶 Children count: ${parent?.children.length ?? 0}');
  }

  int? _getChildId() {
    final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
    final parent = sessionManager.currentParent;

    if (parent?.children.isNotEmpty == true) {
      try {
        return int.parse(parent!.children.first);
      } catch (e) {
        debugPrint('[ParentDashboard] ❌ Invalid child ID format: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
      await sessionManager.clearSession();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
          'Parent Dashboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () {
              setState(() {
                _loadParentData();
              });
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: const ParentAppDrawer(),
      body: Consumer<ParentSessionManager>(
        builder: (context, sessionManager, child) {
          final parent = sessionManager.currentParent;

          if (parent == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadParentData();
              });
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildParentInfoCard(parent),
                  const SizedBox(height: 24),
                  _buildChildrenSection(parent),
                  const SizedBox(height: 24),
                  _buildGridView(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParentInfoCard(parent) {
    final profile = _profile;

    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: profile?.photoUrl != null
                ? NetworkImage(profile!.photoUrl!)
                : null,
            backgroundColor: Colors.blueGrey,
            child: profile?.photoUrl == null
                ? Text(
              (profile?.fullName ?? parent.fullName)[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parent',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.fullName ?? parent.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      profile?.phoneNumber ?? parent.phoneNumber,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (profile?.email != null && profile!.email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      profile!.email,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (profile?.occupation != null && profile!.occupation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      profile!.occupation,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection(parent) {
    if (parent.children.isEmpty) {
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
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'No children linked yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Children',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${parent.children.length}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...parent.children.asMap().entries.map((entry) {
            final index = entry.key;
            final childId = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      radius: 20,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Student',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'ID: $childId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.verified_user,
                      color: Colors.green.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final gridItems = [
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Grievance',
        'colors': [Colors.lightBlue.shade100, Colors.lightBlue.shade200]
      },
      {
        'icon': Icons.group_add_outlined,
        'label': 'Parent-Teacher Meeting',
        'colors': [Colors.purple.shade100, Colors.purple.shade200]
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Attendance Record',
        'colors': [Colors.orange.shade100, Colors.orange.shade200]
      },
      {
        'icon': Icons.credit_card_outlined,
        'label': 'Payments Screen',
        'colors': [Colors.green.shade100, Colors.green.shade200]
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'Results',
        'colors': [Colors.blue.shade100, Colors.blue.shade200]
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'colors': [Colors.red.shade100, Colors.red.shade200],
        'badge': '3'
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Timetable',
        'colors': [Colors.deepPurple.shade100, Colors.deepPurple.shade200]
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final item = gridItems[index];
        return _buildGridItem(
          item['icon'] as IconData,
          item['label'] as String,
          item['colors'] as List<Color>,
          badge: item['badge'] as String?,
        );
      },
    );
  }

  Widget _buildGridItem(IconData icon, String label, List<Color> colors,
      {String? badge}) {
    return InkWell(
      onTap: () {
        final childId = _getChildId();

        if (label == 'Grievance') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GrievanceScreen(),
            ),
          );
        } else if (label == 'Parent-Teacher Meeting') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentTeacherMeetingScreen(),
            ),
          );
        } else if (label == 'Attendance Record') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AttendanceReportScreen(),
            ),
          );
        } else if (label == 'Payments Screen') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentsScreen(),
            ),
          );
        } else if (label == 'Results') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResultsScreen(),
            ),
          );
        } else if (label == 'Notifications') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
        } else if (label == 'Timetable') {
          if (childId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimetableScreen(childId: childId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No child linked to view timetable'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: Colors.black.withOpacity(0.7)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}