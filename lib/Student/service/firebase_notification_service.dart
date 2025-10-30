import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../../student_session_manager.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
  FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  bool _isInitialized = false;
  bool _localNotificationsAvailable = false;

  // Initialize ONLY Firebase Messaging (NOT Firebase Core)
  Future<void> initializeMessaging(SessionManager sessionManager) async {
    if (_isInitialized) {
      print('⚠️ Firebase Messaging already initialized');
      return;
    }

    try {
      print('🔥 Initializing Firebase Messaging...');

      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ Notification permission granted');

        // Try to initialize local notifications (optional)
        try {
          await _initializeLocalNotifications();
          _localNotificationsAvailable = true;
        } catch (e) {
          print('⚠️ Local notifications unavailable, using system notifications: $e');
          _localNotificationsAvailable = false;
          // Continue anyway - system notifications will still work
        }

        // Get FCM token
        await _getFCMToken(sessionManager);

        // Setup handlers
        _setupForegroundMessageHandler();
        _setupNotificationTapHandler();
        _setupTokenRefreshHandler(sessionManager);

        _isInitialized = true;
        print('✅ Firebase Messaging initialized successfully');
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e, stackTrace) {
      print('❌ Error initializing Firebase Messaging: $e');
      print('Stack: $stackTrace');
      // Don't throw - app should continue
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with error handling
    final bool? initialized = await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized == true || initialized == null) {
      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'vraz_channel',
        'VRAZ Notifications',
        description: 'Notifications for VRAZ LMS',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
        print('✅ Local notifications initialized');
      }
    }
  }

  Future<void> _getFCMToken(SessionManager sessionManager) async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        print('🔑 FCM Token: $_fcmToken');
        await _sendTokenToBackend(_fcmToken!, sessionManager);
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(
      String token, SessionManager sessionManager) async {
    try {
      final authToken = await sessionManager.loadToken();

      if (authToken == null || authToken.isEmpty) {
        print('⚠️ No auth token - will register after login');
        return;
      }

      print('📤 Sending FCM token to backend...');

      final response = await http.post(
        Uri.parse('https://vraz-backend-api.onrender.com/api/devices/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'token': token}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Device registered: ${response.body}');
      } else {
        print('❌ Registration failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending token: $e');
    }
  }

  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message: ${message.notification?.title}');

      if (message.notification != null && _localNotificationsAvailable) {
        _showLocalNotification(message);
      }
    });
  }

  void _setupNotificationTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Notification tapped (background)');
      _handleNotificationTap(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('👆 Notification tapped (terminated)');
        _handleNotificationTap(message.data);
      }
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print('🔗 Handle navigation: $data');
    // TODO: Implement navigation
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_localNotificationsAvailable) {
      print('⚠️ Local notifications not available, skipping');
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'vraz_channel',
        'VRAZ Notifications',
        channelDescription: 'Notifications for VRAZ LMS',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
        notificationDetails,
        payload: json.encode(message.data),
      );

      print('✅ Local notification shown');
    } catch (e) {
      print('⚠️ Could not show local notification: $e');
    }
  }

  void _setupTokenRefreshHandler(SessionManager sessionManager) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 Token refreshed');
      _fcmToken = newToken;
      _sendTokenToBackend(newToken, sessionManager);
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        print('❌ Error parsing payload: $e');
      }
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      _isInitialized = false;
      print('🗑️ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting token: $e');
    }
  }

  Future<void> refreshToken(SessionManager sessionManager) async {
    if (_fcmToken != null) {
      await _sendTokenToBackend(_fcmToken!, sessionManager);
    } else {
      await _getFCMToken(sessionManager);
    }
  }
}