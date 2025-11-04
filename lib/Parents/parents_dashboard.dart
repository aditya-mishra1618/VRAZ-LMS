import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/Parents/service/parent_child_api.dart';
import 'package:vraz_application/Parents/service/parent_profile_api_service.dart';
import 'package:vraz_application/Parents/support_ticket_screen.dart';

import '../Parents/notifications_screen.dart';
import 'Grievance_screen.dart';
import 'attendance_report_screen.dart';
import 'grievance_chat_screen.dart';
import 'models/parent_child_model.dart';
import 'models/parent_profile_model.dart';
import 'models/child_profile_model.dart';
import 'parent_app_drawer.dart';
import 'parent_teacher_meeting_screen.dart';
import 'payments_screen.dart';
import 'results_screen.dart';
import 'service/child_profile_api.dart';
import 'timetable_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  ParentProfile? _parentProfile;
  List<ParentChild> _children = [];
  ParentChild? _selectedChild;
  ChildProfile? _selectedChildProfile;
  bool _isLoading = true;
  String? _authToken;
  int _notificationBadgeCount = 0; // ✅ NEW: Dynamic badge count

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ NEW: Listen to app lifecycle
    _loadParentData();
    _loadNotificationCount(); // ✅ NEW: Load badge count
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ NEW: Reload badge when returning to dashboard
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotificationCount();
    }
  }

  // ✅ NEW: Load notification count from SharedPreferences
  Future<void> _loadNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('unread_notification_count') ?? 0;

      if (mounted) {
        setState(() {
          _notificationBadgeCount = count;
        });
      }

      print('[ParentDashboard] 🔔 Notification badge count: $count');
    } catch (e) {
      print('[ParentDashboard] ❌ Failed to load notification count: $e');
    }
  }

  Future<void> _loadParentData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('parent_auth_token');

      if (_authToken == null || _authToken!.isEmpty) {
        print('[ParentDashboard] ❌ No auth token found');
        _showError('Session expired. Please login again.');
        return;
      }

      print('[ParentDashboard] ✅ Auth token found: ${_authToken!.substring(0, 20)}...');

      // 2. Fetch parent profile
      print('[ParentDashboard] 🔄 Fetching parent profile...');
      _parentProfile = await ParentProfileApi.fetchParentProfile(_authToken!);

      if (_parentProfile != null) {
        print('[ParentDashboard] ✅ Parent profile loaded: ${_parentProfile!.fullName}');
        await _saveParentProfile(_parentProfile!);
      } else {
        print('[ParentDashboard] ⚠️ Failed to fetch parent profile');
      }

      // 3. Fetch children list
      print('[ParentDashboard] 🔄 Fetching children list...');
      _children = await ParentChildrenApi.fetchParentChildren(_authToken!);

      if (_children.isNotEmpty) {
        print('[ParentDashboard] ✅ Loaded ${_children.length} children');
        await _saveChildren(_children);

        // Set first child as selected by default
        _selectedChild = _children.first;
        await _saveSelectedChild(_selectedChild!);

        // Fetch detailed profile for selected child
        print('[ParentDashboard] 🔄 Fetching detailed profile for child: ${_selectedChild!.id}');
        _selectedChildProfile = await ChildProfileApi.fetchChildProfile(
          authToken: _authToken!,
          childId: _selectedChild!.id,
        );

        if (_selectedChildProfile != null) {
          print('[ParentDashboard] ✅ Child profile loaded: ${_selectedChildProfile!.fullName}');
          await _saveChildProfile(_selectedChildProfile!);
        } else {
          print('[ParentDashboard] ⚠️ Failed to fetch child profile');
        }

        print('[ParentDashboard] Selected child: ${_selectedChild!.fullName}');
      } else {
        print('[ParentDashboard] ⚠️ No children found');
        _showInfo('No children linked to this account.');
      }
    } catch (e, stackTrace) {
      print('[ParentDashboard] ❌ Error loading data: $e');
      print('[ParentDashboard] Stack trace: $stackTrace');
      _showError('Failed to load data. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Save parent profile to SharedPreferences
  Future<void> _saveParentProfile(ParentProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('parent_full_name', profile.fullName);
      await prefs.setString('parent_phone_number', profile.phoneNumber);
      await prefs.setString('parent_email', profile.email);
      await prefs.setString('parent_occupation', profile.occupation);
      if (profile.photoUrl != null) {
        await prefs.setString('parent_photo_url', profile.photoUrl!);
      }
      print('[ParentDashboard] ✅ Parent profile saved locally');
    } catch (e) {
      print('[ParentDashboard] ❌ Failed to save parent profile: $e');
    }
  }

  // Save children list to SharedPreferences
  Future<void> _saveChildren(List<ParentChild> children) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childrenJson = children.map((c) => c.toJson()).toList();
      await prefs.setString('parent_children', childrenJson.toString());
      await prefs.setInt('parent_children_count', children.length);
      print('[ParentDashboard] ✅ ${children.length} children saved locally');
    } catch (e) {
      print('[ParentDashboard] ❌ Failed to save children: $e');
    }
  }

  // Save selected child to SharedPreferences
  Future<void> _saveSelectedChild(ParentChild child) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_child_id', child.id);
      await prefs.setString('selected_child_name', child.fullName);
      await prefs.setString('selected_child_branch', child.branchName);
      await prefs.setString('selected_child_course', child.courseName);
      print('[ParentDashboard] ✅ Selected child saved: ${child.fullName}');
    } catch (e) {
      print('[ParentDashboard] ❌ Failed to save selected child: $e');
    }
  }

  // Save child profile details to SharedPreferences
  Future<void> _saveChildProfile(ChildProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save child profile details
      await prefs.setInt('child_profile_id', profile.id);
      await prefs.setString('child_full_name', profile.fullName);
      await prefs.setString('child_email', profile.email);
      await prefs.setString('child_phone', profile.phoneNumber);
      await prefs.setString('child_current_class', profile.currentClass);
      await prefs.setString('child_school_name', profile.schoolName);
      await prefs.setString('child_board', profile.board);
      await prefs.setString('child_marks_cgpa', profile.marksOrCgpa);
      await prefs.setString('child_category', profile.category);
      await prefs.setString('child_status', profile.status);
      await prefs.setString('child_form_number', profile.formNumber);
      await prefs.setString('child_session_year', profile.sessionYear);

      // Emergency contact
      await prefs.setString('child_emergency_name', profile.emergencyContactName);
      await prefs.setString('child_emergency_number', profile.emergencyContactNumber);
      await prefs.setString('child_emergency_relation', profile.emergencyContactRelation);

      // Fee details
      await prefs.setString('child_course_fee', profile.courseFee);
      await prefs.setString('child_total_payable', profile.totalPayable);
      await prefs.setBool('child_with_gst', profile.withGst);
      await prefs.setString('child_gst_percentage', profile.gstPercentage);

      // Branch and course
      await prefs.setString('child_branch_name', profile.branchName);
      await prefs.setString('child_branch_code', profile.branch.code);
      await prefs.setString('child_branch_location', profile.branch.locationAddress);
      await prefs.setString('child_course_name', profile.courseName);
      await prefs.setString('child_course_code', profile.course.code);

      // Student user details
      if (profile.photoUrl != null) {
        await prefs.setString('child_photo_url', profile.photoUrl!);
      }
      await prefs.setString('child_address', profile.studentUser.address);
      await prefs.setString('child_gender', profile.studentUser.gender);
      if (profile.studentUser.dateOfBirth != null) {
        await prefs.setString('child_dob', profile.studentUser.dateOfBirth!.toIso8601String());
      }
      if (profile.admissionDate != null) {
        await prefs.setString('child_admission_date', profile.admissionDate!.toIso8601String());
      }

      // Save entire profile as JSON (for easy retrieval)
      await prefs.setString('child_profile_json', json.encode(profile.toJson()));

      print('[ParentDashboard] ✅ Child profile saved locally');
      print('[ParentDashboard] 📋 Saved details: Class: ${profile.currentClass}, School: ${profile.schoolName}');
    } catch (e) {
      print('[ParentDashboard] ❌ Failed to save child profile: $e');
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

  // Show child selector and fetch profile when switched
  void _showChildSelector() {
    if (_children.isEmpty) {
      _showInfo('No children available');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Child'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _children.length,
            itemBuilder: (context, index) {
              final child = _children[index];
              final isSelected = _selectedChild?.id == child.id;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: child.photoUrl != null
                      ? NetworkImage(child.photoUrl!)
                      : const AssetImage('assets/profile.png') as ImageProvider,
                  child: child.photoUrl == null
                      ? Text(child.fullName[0].toUpperCase())
                      : null,
                ),
                title: Text(
                  child.fullName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('${child.courseName} - ${child.branchName}'),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(context);

                  setState(() {
                    _selectedChild = child;
                    _isLoading = true;
                  });

                  // Fetch detailed profile for newly selected child
                  print('[ParentDashboard] 🔄 Switching to child: ${child.fullName} (ID: ${child.id})');
                  _selectedChildProfile = await ChildProfileApi.fetchChildProfile(
                    authToken: _authToken!,
                    childId: child.id,
                  );

                  if (_selectedChildProfile != null) {
                    await _saveSelectedChild(child);
                    await _saveChildProfile(_selectedChildProfile!);
                    print('[ParentDashboard] ✅ Switched to child: ${_selectedChildProfile!.fullName}');
                  } else {
                    print('[ParentDashboard] ⚠️ Failed to fetch profile for switched child');
                  }

                  setState(() => _isLoading = false);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${child.fullName}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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
        actions: [
          if (_children.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.black54),
              onPressed: _showChildSelector,
              tooltip: 'Switch Child',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _isLoading ? null : () {
              _loadParentData();
              _loadNotificationCount(); // ✅ Also refresh badge
            },
            tooltip: 'Refresh',
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
        onRefresh: () async {
          await _loadParentData();
          await _loadNotificationCount(); // ✅ Also refresh badge
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildParentInfoCard(),
              if (_selectedChild != null) ...[
                const SizedBox(height: 16),
                _buildSelectedChildCard(),
              ],
              const SizedBox(height: 24),
              _buildGridView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentInfoCard() {
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
            backgroundImage: _parentProfile?.photoUrl != null
                ? NetworkImage(_parentProfile!.photoUrl!)
                : const AssetImage('assets/profile.png') as ImageProvider,
            child: _parentProfile?.photoUrl == null
                ? Text(
              _parentProfile?.fullName[0].toUpperCase() ?? 'P',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  _parentProfile?.fullName ?? 'Loading...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                if (_parentProfile?.occupation != null &&
                    _parentProfile!.occupation.isNotEmpty)
                  Text(
                    _parentProfile!.occupation,
                    style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChildCard() {
    if (_selectedChild == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: _selectedChild!.photoUrl != null
                ? NetworkImage(_selectedChild!.photoUrl!)
                : const AssetImage('assets/profile.png') as ImageProvider,
            child: _selectedChild!.photoUrl == null
                ? Text(
              _selectedChild!.fullName[0].toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Viewing: ',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    Expanded(
                      child: Text(
                        _selectedChild!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedChild!.courseName} - ${_selectedChild!.branchName}',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (_selectedChildProfile != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Class: ${_selectedChildProfile!.currentClass}',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_children.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.black54),
              onPressed: _showChildSelector,
              tooltip: 'Switch Child',
            ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final gridItems = [
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Grievance',
        'colors': [Colors.lightBlue.shade100, Colors.lightBlue.shade200],
        'screen': const GrievanceScreen(),
      },
      {
        'icon': Icons.support_agent_outlined,
        'label': 'Support Chat',
        'colors': [Colors.cyan.shade100, Colors.cyan.shade200],
        'screen': const SupportTicketScreen()
      },
      {
        'icon': Icons.group_add_outlined,
        'label': 'Parent-Teacher Meeting',
        'colors': [Colors.purple.shade100, Colors.purple.shade200],
        'screen': const ParentTeacherMeetingScreen(),
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Attendance Record',
        'colors': [Colors.orange.shade100, Colors.orange.shade200],
        'screen': const AttendanceReportScreen(),
      },
      {
        'icon': Icons.credit_card_outlined,
        'label': 'Payments Screen',
        'colors': [Colors.green.shade100, Colors.green.shade200],
        'screen': const PaymentsScreen(),
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'Results',
        'colors': [Colors.blue.shade100, Colors.blue.shade200],
        'screen': const ResultsScreen(),
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'colors': [Colors.red.shade100, Colors.red.shade200],
        'badge': _notificationBadgeCount > 0 ? _notificationBadgeCount.toString() : null, // ✅ DYNAMIC BADGE
        'screen': const NotificationsScreen(),
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Timetable',
        'colors': [Colors.deepPurple.shade100, Colors.deepPurple.shade200],
        'screen': const TimetableScreen(),
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
          item['screen'] as Widget?,
          badge: item['badge'] as String?,
        );
      },
    );
  }

  Widget _buildGridItem(
      IconData icon,
      String label,
      List<Color> colors,
      Widget? screen, {
        String? badge,
      }) {
    return InkWell(
      onTap: screen == null
          ? null
          : () async {
        // ✅ Reload badge count when returning from notifications screen
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
        if (label == 'Notifications') {
          _loadNotificationCount();
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
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.8),
                      fontSize: 14,
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
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}