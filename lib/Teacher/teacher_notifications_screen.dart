import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../teacher_session_manager.dart';
import '../universal_notification_service.dart';
import 'teacher_app_drawer.dart';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UniversalNotificationService _notificationService =
      UniversalNotificationService.instance;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;

  String? _authToken;
  String? _teacherEmail;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    if (_isInitialized) return;

    setState(() => _isLoading = true);

    try {
      // 1. Load teacher credentials from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('teacher_auth_token');
      _teacherEmail = prefs.getString('teacher_email');

      // ✅ If not found in separate keys, get from TeacherSessionManager
      if (_authToken == null || _authToken!.isEmpty) {
        print(
            '[TeacherNotif] 🔄 Token not in separate key, checking TeacherSessionManager...');
        final sessionManager = TeacherSessionManager();
        await sessionManager.initialize();
        _authToken = sessionManager.authToken;

        if (_authToken != null) {
          print('[TeacherNotif] ✅ Got token from TeacherSessionManager');
          // Save it to separate keys for next time
          await prefs.setString('teacher_auth_token', _authToken!);
          if (sessionManager.currentTeacher?.email != null) {
            await prefs.setString(
                'teacher_email', sessionManager.currentTeacher!.email);
            _teacherEmail = sessionManager.currentTeacher!.email;
          }
        }
      }

      print(
          '[TeacherNotif] Auth Token: ${_authToken != null ? "Found: $_authToken..." : "Missing"}');
      print('[TeacherNotif] Teacher Email: $_teacherEmail');

      // Set role to 'teacher' for isolated storage
      _notificationService.setRole('teacher');

      // 2. Initialize the notification service
      await _notificationService.initialize();

      // 3. Fetch notifications from server
      if (_authToken != null && _authToken!.isNotEmpty) {
        print('[TeacherNotif] 🔄 Fetching notifications from server...');
        await _notificationService.fetchAndMergeFromServer(
            authToken: _authToken);
      } else {
        print('[TeacherNotif] ⚠️ No auth token, skipping server fetch');
      }

      // 4. Load stored notifications
      _notifications = _notificationService.getStoredNotifications();
      print(
          '[TeacherNotif] 📥 Loaded ${_notifications.length} TEACHER notifications');

      // 5. Listen for real-time notification updates
      _notificationSubscription =
          _notificationService.notificationsStream.listen((updatedList) {
        if (mounted) {
          print(
              '[TeacherNotif] 🔔 Real-time update: ${updatedList.length} notifications');
          setState(() {
            _notifications = updatedList;
          });
        }
      });

      _isInitialized = true;
      print(
          '[TeacherNotif] ✅ Initialized with ${_notifications.length} notifications');
    } catch (e, stackTrace) {
      print('[TeacherNotif] ❌ Initialization error: $e');
      print('[TeacherNotif] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() => _isLoading = true);
    try {
      print('[TeacherNotif] 🔄 Manual refresh triggered...');

      // ✅ Get latest token from TeacherSessionManager
      if (_authToken == null || _authToken!.isEmpty) {
        final sessionManager = TeacherSessionManager();
        await sessionManager.initialize();
        _authToken = sessionManager.authToken;
        print('[TeacherNotif] Got token from SessionManager for refresh');
      }

      await _notificationService.fetchAndMergeFromServer(authToken: _authToken);
      setState(() {
        _notifications = _notificationService.getStoredNotifications();
      });
      print(
          '[TeacherNotif] ✅ Refresh complete: ${_notifications.length} notifications');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notifications refreshed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[TeacherNotif] ❌ Refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Refresh failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- RE-ADDED: Getter for unread count ---
  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        // --- UPDATED: Re-added actions ---
        actions: [
          // 1. Unread Count Badge
          if (_unreadCount > 0)
            Padding(
              // Padding to center it vertically with the button
              padding: const EdgeInsets.only(top: 8.0, right: 4.0),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // 2. Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _isLoading ? null : _refreshNotifications,
            tooltip: 'Refresh notifications',
          ),
          const SizedBox(width: 8),
        ],
        // --- END UPDATE ---
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: _isLoading && _notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Notifications',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._notifications.map((notification) =>
                            _buildNotificationCard(notification)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A65F8),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNotificationDetailsDialog(
      BuildContext context, AppNotification notification) {
    // Mark as read when opened
    print('[TeacherNotif] 📖 Marking notification as read: ${notification.id}');
    _notificationService.markAsRead(
      notification.id,
      syncWithServer: true,
      serverToken: _authToken,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(
                notification.isRead
                    ? Icons.mark_email_read
                    : Icons.mark_email_unread,
                color: const Color(0xFF2A65F8),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title ?? 'Notification',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.body ?? 'No details available',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatDateTime(notification.receivedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (notification.data.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Additional Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...notification.data.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final Color statusColor = notification.isRead ? Colors.grey : Colors.green;
    final String statusText = notification.isRead ? 'Read' : 'New';

    final now = DateTime.now();
    final diff = now.difference(notification.receivedAt);
    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      timeAgo = '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }

    return InkWell(
      onTap: () {
        _showNotificationDetailsDialog(context, notification);
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: notification.isRead ? 0 : 3,
        color: notification.isRead ? Colors.grey[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isRead
              ? BorderSide.none
              : BorderSide(color: Colors.blue.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notification.title ?? 'Notification',
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body ?? 'No details',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.grey[200]
                      : const Color(0xFF2A65F8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mail_outline,
                  size: 32,
                  color: notification.isRead
                      ? Colors.grey[600]
                      : const Color(0xFF2A65F8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
