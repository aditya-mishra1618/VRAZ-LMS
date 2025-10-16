import 'package:flutter/material.dart';

// --- Placeholder Screens for Admin Navigation ---
class AdminTimetableScreen extends StatelessWidget {
  const AdminTimetableScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Manage Timetable')));
}

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Manage Notifications')));
}

class BatchCreationScreen extends StatelessWidget {
  const BatchCreationScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Batch Creation')));
}

class LeaveManagementScreen extends StatelessWidget {
  const LeaveManagementScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Leaves Management')));
}

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Manage Payments')));
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('User Management')));
}
// --- End of Placeholders ---

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateTo(Widget screen) {
    // Close the drawer before navigating
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define the items for both grid and drawer to avoid duplication
    final List<Map<String, dynamic>> featureItems = [
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Timetable',
        'onTap': () => _navigateTo(const AdminTimetableScreen())
      },
      {
        'icon': Icons.notifications_active_outlined,
        'label': 'Notifications',
        'onTap': () => _navigateTo(const AdminNotificationsScreen())
      },
      {
        'icon': Icons.group_add_outlined,
        'label': 'Batch Creation',
        'onTap': () => _navigateTo(const BatchCreationScreen())
      },
      {
        'icon': Icons.work_off_outlined,
        'label': 'Leaves Mgmt',
        'onTap': () => _navigateTo(const LeaveManagementScreen())
      },
      {
        'icon': Icons.payment_outlined,
        'label': 'Payments',
        'onTap': () => _navigateTo(const AdminPaymentsScreen())
      },
      {
        'icon': Icons.manage_accounts_outlined,
        'label': 'User Mgmt',
        'onTap': () => _navigateTo(const UserManagementScreen())
      },
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.grey),
            onPressed: () {},
          )
        ],
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: _buildDrawer(featureItems),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminInfoCard(),
            const SizedBox(height: 24),
            const Text(
              'Core Features',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGridView(featureItems),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(List<Map<String, dynamic>> items) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text(
              'Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text('admin@vraz.com'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'), // Placeholder
            ),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
          ),
          ...items.map((item) => ListTile(
                leading:
                    Icon(item['icon'] as IconData, color: Colors.grey[700]),
                title: Text(item['label'] as String),
                onTap: item['onTap'] as VoidCallback,
              ))
        ],
      ),
    );
  }

  Widget _buildAdminInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile.png'), // Placeholder
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> items) {
    final List<Color> colors = [
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.purple.shade50,
      Colors.yellow.shade100,
      Colors.red.shade50,
      Colors.lightGreen.shade100,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildGridItem(
          item['icon'] as IconData,
          item['label'] as String,
          colors[index % colors.length],
          item['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildGridItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.black.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
