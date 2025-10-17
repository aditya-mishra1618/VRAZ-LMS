import 'package:flutter/material.dart';

import 'teacher_app_drawer.dart'; // Import your central drawer

// --- Data Models (can be moved later) ---
class LiveNotification {
  final String status;
  final String timeAgo;
  final String title;
  final String content;
  final String imageUrl;

  const LiveNotification({
    required this.status,
    required this.timeAgo,
    required this.title,
    required this.content,
    required this.imageUrl,
  });
}

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  // Dummy data for the notification list
  final List<LiveNotification> _notifications = const [
    LiveNotification(
      status: 'Sent',
      timeAgo: '10 min ago',
      title: 'Class Announcement',
      content:
          'Reminder: The deadline for the project is next Friday. Please...',
      imageUrl: 'assets/profile.png',
    ),
    LiveNotification(
      status: 'Pending',
      timeAgo: '20 min ago',
      title: 'Individual Student Message',
      content:
          'Hi Alex, I noticed you missed the last class. Please catch up on the...',
      imageUrl: 'assets/profile.png',
    ),
    LiveNotification(
      status: 'Sent',
      timeAgo: '1 hour ago',
      title: 'Video Lecture Uploaded',
      content: 'A new video lecture on "The Renaissance" has been uploade...',
      imageUrl: 'assets/profile.png',
    ),
  ];

  // --- Send Notification Dialog Logic ---
  void _showSendNotificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SendNotificationDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      // --- ADD THE DRAWER ---
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        // --- REMOVED THE LEADING BACK BUTTON ---
        title: const Text('Notifications',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 80), // Add bottom padding
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Notifications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.notifications_none,
                          size: 30, color: Colors.grey),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('2',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              ..._notifications.map((notif) => _buildNotificationCard(notif)),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: FloatingActionButton.extended(
                onPressed: _showSendNotificationDialog,
                label: const Text('Send Notification'),
                icon: const Icon(Icons.add),
                backgroundColor: Colors.blueAccent,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNotificationCard(LiveNotification notification) {
    final bool isSent = notification.status == 'Sent';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
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
                          color:
                              isSent ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(notification.status,
                            style: TextStyle(
                                color: isSent
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text(notification.timeAgo,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(notification.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(notification.content,
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(notification.imageUrl,
                  width: 60, height: 60, fit: BoxFit.cover),
            )
          ],
        ),
      ),
    );
  }
}

// --- The Dialog Widget ---
class SendNotificationDialog extends StatefulWidget {
  const SendNotificationDialog({super.key});

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  final List<String> _audienceOptions = ['Admin', 'Parents', 'Student', 'All'];
  List<String> _selectedAudiences = [];
  String? _selectedMessageType;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  void _sendNotification() {
    if (_selectedAudiences.isEmpty ||
        _selectedMessageType == null ||
        _titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields to send the notification.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle send logic
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Notification has been sent!'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Notification'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMultiSelectDropdown(),
            const SizedBox(height: 20),
            _buildSingleSelectDropdown(),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _sendNotification, child: const Text('Send')),
      ],
    );
  }

  Widget _buildMultiSelectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Send to:", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select Audience'),
              value: null,
              items: _audienceOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  // This prevents the dropdown from closing on tap
                  enabled: false,
                  child: StatefulBuilder(builder: (context, menuSetState) {
                    return InkWell(
                      onTap: () {
                        _toggleSelection(value);
                        // We need to call setState on the menu to rebuild it
                        menuSetState(() {});
                        // And also on the main dialog to update the display text
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedAudiences.contains(value),
                            onChanged: (bool? checked) {
                              _toggleSelection(value);
                              menuSetState(() {});
                              setState(() {});
                            },
                          ),
                          Text(value),
                        ],
                      ),
                    );
                  }),
                );
              }).toList(),
              onChanged: (String? value) {},
              selectedItemBuilder: (BuildContext context) {
                return [
                  // Show a summary of selected items or a hint
                  Text(
                    _selectedAudiences.isEmpty
                        ? 'Select Audience'
                        : _selectedAudiences.join(', '),
                    overflow: TextOverflow.ellipsis,
                  )
                ];
              },
            ),
          ),
        ),
      ],
    );
  }

  void _toggleSelection(String value) {
    if (_selectedAudiences.contains(value)) {
      _selectedAudiences.remove(value);
    } else {
      _selectedAudiences.add(value);
    }
  }

  Widget _buildSingleSelectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Type of Message:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedMessageType,
          items: ['Assignment', 'Daily Report', 'Announcement', 'Live Events']
              .map((String type) {
            return DropdownMenuItem<String>(value: type, child: Text(type));
          }).toList(),
          onChanged: (newValue) =>
              setState(() => _selectedMessageType = newValue),
          decoration: InputDecoration(
            hintText: 'Select Type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }
}
