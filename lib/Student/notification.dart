import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../student_session_manager.dart';
import '../universal_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> _items;
  Stream<List<AppNotification>>? _stream;
  late final UniversalNotificationService _svc;
  StreamSubscription<List<AppNotification>>? _sub;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _svc = UniversalNotificationService.instance;
    _items = _svc.getStoredNotifications();
    _stream = _svc.notificationsStream;
    _sub = _stream?.listen((list) {
      setState(() {
        _items = list;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptServerSync());
  }

  Future<void> _attemptServerSync() async {
    final session = Provider.of<SessionManager>(context, listen: false);
    if (session.isLoggedIn) {
      await _refreshFromServer(authToken: session.authToken);
    } else {
      // still try without auth to load any locally stored notifications
      setState(() {
        _items = _svc.getStoredNotifications();
      });
    }
  }

  Future<void> _refreshFromServer({String? authToken}) async {
    setState(() => _loading = true);
    try {
      await _svc.fetchAndMergeFromServer(authToken: authToken);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _openDetails(AppNotification n) async {
    final session = Provider.of<SessionManager>(context, listen: false);
    try {
      final details = await UniversalNotificationService.instance
          .getNotificationDetails(n.id, authToken: session.authToken);
      await UniversalNotificationService.instance
          .markAsRead(n.id, syncWithServer: true, serverToken: session.authToken);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) {
          final body = details?.body ?? n.body ?? '';
          final title = details?.title ?? n.title ?? 'Notification';
          final dataJson = details != null ? details.data : n.data;
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(body),
                  const SizedBox(height: 12),
                  if (dataJson.isNotEmpty)
                    Text('Data: ${dataJson.toString()}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))
            ],
          );
        },
      );
    } catch (e) {
      await UniversalNotificationService.instance
          .markAsRead(n.id, syncWithServer: true, serverToken: session.authToken);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(n.title ?? 'Notification'),
          content: Text(n.body ?? ''),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
        ),
      );
    }
  }

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
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.mark_email_read_outlined, color: Colors.black54),
            onPressed: () async {
              final session = Provider.of<SessionManager>(context, listen: false);
              await _svc.markAllAsRead(syncWithServer: true, serverToken: session.authToken);
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () async {
              final session = Provider.of<SessionManager>(context, listen: false);
              await _refreshFromServer(authToken: session.authToken);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final session = Provider.of<SessionManager>(context, listen: false);
          await _refreshFromServer(authToken: session.authToken);
        },
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No notifications yet', style: TextStyle(color: Colors.grey))),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final n = _items[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: n.isRead ? null : Border.all(color: Colors.blueAccent.withOpacity(0.2)),
              ),
              child: InkWell(
                onTap: () => _openDetails(n),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: n.isRead ? Colors.grey[200] : Colors.blueAccent.withAlpha(40),
                      child: Icon(Icons.notifications, color: n.isRead ? Colors.grey : Colors.blueAccent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title ?? 'Notification',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: n.isRead ? Colors.grey[800] : Colors.black),
                                ),
                              ),
                              Text(
                                _formatTime(n.receivedAt),
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (n.body != null)
                            Text(n.body!, style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!n.isRead)
                                TextButton(
                                  onPressed: () async {
                                    final session = Provider.of<SessionManager>(context, listen: false);
                                    await _svc.markAsRead(n.id, syncWithServer: true, serverToken: session.authToken);
                                  },
                                  child: const Text('Mark read'),
                                ),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Notification data'),
                                      content: SingleChildScrollView(
                                        child: Text(n.data.isNotEmpty ? jsonEncode(n.data) : 'No data'),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Details'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}