import 'package:flutter/material.dart';

// A simple model for a notification item
class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  // The constructor must be 'const' to be used in a const list.
  const NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Dummy data for notifications - this can now be a const list.
  static const List<NotificationItem> _notifications = [
    NotificationItem(
      icon: Icons.assignment_turned_in,
      iconColor: Colors.green,
      title: 'Assignment Graded',
      subtitle: 'Your Physics assignment on Kinematics has been graded.',
      time: '2 hours ago',
    ),
    NotificationItem(
      icon: Icons.calendar_today,
      iconColor: Colors.blue,
      title: 'New Timetable Uploaded',
      subtitle: 'The class schedule for next week is now available.',
      time: '1 day ago',
    ),
    NotificationItem(
      icon: Icons.help_outline,
      iconColor: Colors.orange,
      title: 'Doubt Resolved',
      subtitle: 'Prof. Ankit Sir has answered your doubt on Chemical Bonding.',
      time: '2 days ago',
    ),
    NotificationItem(
      icon: Icons.announcement,
      iconColor: Colors.redAccent,
      title: 'Important Announcement',
      subtitle: 'The center will be closed on Monday for a public holiday.',
      time: '3 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  // FIXED: withOpacity is deprecated
                  backgroundColor:
                      notification.iconColor.withAlpha(26), // 10% opacity
                  child: Icon(notification.icon, color: notification.iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.subtitle,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.time,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
