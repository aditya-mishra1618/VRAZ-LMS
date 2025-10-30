/*
  UniversalNotificationService (with fetch fallbacks)

  - Tries POST /api/notifications/getMyNotifications with Authorization header.
  - If POST returns 404, will retry as GET.
  - If still 404, will try switching http <-> https on the base URL and repeat.
  - Logs full status and body for each attempt to help debug server routing issues.
  - Preserves previous behavior: persists notifications, handles FCM events, exposes notificationsStream.
*/

import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';

const String _kNotificationsKey = 'app_notifications_list';
const String _kDefaultRegisterPath = '/api/notifications/register';
const String _kDefaultMarkReadPath = '/api/notifications/mark-read';
const String _kDefaultMarkAllReadPath = '/api/notifications/mark-all-read';

class NotificationModel {
  final String id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  bool isRead;
  final String? type;

  NotificationModel({
    required this.id,
    this.title,
    this.body,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'] ??
        json['notificationId'] ??
        json['_id'] ??
        json['notification_id'];
    final createdAtVal = json['createdAt'] ??
        json['receivedAt'] ??
        json['timestamp'] ??
        json['created_at'];

    DateTime parsedDate;
    if (createdAtVal == null) {
      parsedDate = DateTime.now();
    } else if (createdAtVal is int) {
      parsedDate = createdAtVal > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(createdAtVal)
          : DateTime.fromMillisecondsSinceEpoch(createdAtVal * 1000);
    } else {
      parsedDate =
          DateTime.tryParse(createdAtVal.toString()) ?? DateTime.now();
    }

    final dataField = json['data'] ?? <String, dynamic>{};
    final Map<String, dynamic> dataMap = dataField is Map
        ? Map<String, dynamic>.from(dataField)
        : <String, dynamic>{};

    return NotificationModel(
      id: idVal?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? json['notificationTitle']?.toString(),
      body: json['body']?.toString() ??
          json['message']?.toString() ??
          json['notificationBody']?.toString(),
      data: dataMap,
      createdAt: parsedDate,
      isRead: json['isRead'] == true ||
          json['read'] == true ||
          json['is_read'] == true,
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }
}

class AppNotification {
  final String id;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  bool isRead;

  AppNotification({
    required this.id,
    this.title,
    this.body,
    required this.data,
    required this.receivedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'data': data,
    'receivedAt': receivedAt.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'],
      body: json['body'],
      data: Map<String, dynamic>.from(json['data'] ?? <String, dynamic>{}),
      receivedAt:
      DateTime.tryParse(json['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }

  factory AppNotification.fromModel(NotificationModel m) {
    return AppNotification(
      id: m.id,
      title: m.title,
      body: m.body,
      data: m.data,
      receivedAt: m.createdAt,
      isRead: m.isRead,
    );
  }

  @override
  String toString() => 'AppNotification(id:$id title:$title isRead:$isRead)';
}

// Background handler must be top-level
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kNotificationsKey);
    List<dynamic> list =
    existing != null ? json.decode(existing) as List<dynamic> : <dynamic>[];

    final Map<String, dynamic> jsonPayload = {
      'id': message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'receivedAt': DateTime.now().toIso8601String(),
      'isRead': false,
    };

    list.insert(0, jsonPayload);
    await prefs.setString(_kNotificationsKey, json.encode(list));
  } catch (_) {}
}

class UniversalNotificationService {
  UniversalNotificationService._internal();
  static final UniversalNotificationService instance =
  UniversalNotificationService._internal();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _notificationsController =
  StreamController<List<AppNotification>>.broadcast();

  String? _baseUrl;
  String _registerPath = _kDefaultRegisterPath;
  String _markReadPath = _kDefaultMarkReadPath;
  String _markAllReadPath = _kDefaultMarkAllReadPath;

  bool _initialized = false;

  Stream<List<AppNotification>> get notificationsStream =>
      _notificationsController.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> initialize({
    String? baseUrl,
    String? registerPath,
    String? markReadPath,
    String? markAllReadPath,
  }) async {
    if (_initialized) {
      print('[UNS] initialize() called but already initialized');
      return;
    }

    _baseUrl = baseUrl ?? ApiConfig.baseUrl;
    if (registerPath != null && registerPath.isNotEmpty) _registerPath = registerPath;
    if (markReadPath != null && markReadPath.isNotEmpty) _markReadPath = markReadPath;
    if (markAllReadPath != null && markAllReadPath.isNotEmpty) _markAllReadPath = markAllReadPath;

    print('[UNS] Initializing UniversalNotificationService. baseUrl=$_baseUrl registerPath=$_registerPath');

    await _loadFromStorage();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[UNS] onMessage received (foreground): id=${message.messageId} title=${message.notification?.title}');
      _handleRemoteMessage(message, opened: false);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[UNS] onMessageOpenedApp (opened): id=${message.messageId}');
      _handleRemoteMessage(message, opened: true);
    });

    final initialMessage = await _fm.getInitialMessage();
    if (initialMessage != null) {
      print('[UNS] getInitialMessage returned a message: id=${initialMessage.messageId}');
      _handleRemoteMessage(initialMessage, opened: true);
    }

    _initialized = true;
    print('[UNS] UniversalNotificationService initialized');
  }

  Future<void> _handleRemoteMessage(RemoteMessage message,
      {bool opened = false}) async {
    final payload = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      receivedAt: DateTime.now(),
      isRead: opened,
    );

    if (!_notifications.any((n) => n.id == payload.id)) {
      _notifications.insert(0, payload);
      print('[UNS] Adding FCM notification id=${payload.id} title=${payload.title}');
      await _saveToStorage();
      _notificationsController.add(List.unmodifiable(_notifications));
    } else {
      print('[UNS] Duplicate FCM notification ignored id=${payload.id}');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_kNotificationsKey, json.encode(jsonList));
      print('[UNS-DBG] Saved ${_notifications.length} notifications to SharedPreferences');
    } catch (e) {
      print('[UNS-ERR] Failed to save notifications: $e');
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kNotificationsKey);
      if (jsonString == null) {
        print('[UNS-DBG] No notifications stored yet (key=$_kNotificationsKey)');
        return;
      }
      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      _notifications.clear();
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _notifications.add(AppNotification.fromJson(item));
        } else {
          _notifications.add(AppNotification.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      _notificationsController.add(List.unmodifiable(_notifications));
      print('[UNS-DBG] Loaded ${_notifications.length} notifications from storage');
    } catch (e) {
      print('[UNS-ERR] Failed to load notifications from storage: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kNotificationsKey);
    }
  }

  List<AppNotification> getStoredNotifications() => List.unmodifiable(_notifications);

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveToStorage();
    _notificationsController.add(List.unmodifiable(_notifications));
    print('[UNS] Cleared all local notifications');
  }

  Future<void> addNotificationFromModel(NotificationModel model) async {
    final newItem = AppNotification.fromModel(model);
    if (_notifications.any((n) => n.id == newItem.id)) {
      print('[UNS] addNotificationFromModel: duplicate ignored id=${newItem.id}');
      return;
    }
    _notifications.insert(0, newItem);
    print('[UNS] addNotificationFromModel: added id=${newItem.id} title=${newItem.title}');
    await _saveToStorage();
    _notificationsController.add(List.unmodifiable(_notifications));
  }

  // Try a single HTTP request and log result
  Future<http.Response?> _tryRequest(Uri url, Map<String, String> headers, {String method = 'POST', String? body}) async {
    try {
      http.Response resp;
      if (method == 'POST') {
        resp = await http.post(url, headers: headers, body: body);
      } else {
        resp = await http.get(url, headers: headers);
      }
      print('[UNS] Request $method $url status=${resp.statusCode} body=${resp.body}');
      return resp;
    } catch (e) {
      print('[UNS-ERR] Request $method $url exception: $e');
      return null;
    }
  }

  // Main fetch with fallbacks: POST -> GET -> alternate scheme
  Future<void> fetchAndMergeFromServer({String? authToken}) async {
    print('[UNS] fetchAndMergeFromServer() called authToken=${authToken != null ? "present" : "absent"}');

    final originalBase = (_baseUrl ?? ApiConfig.baseUrl) ?? '';
    if (originalBase.isEmpty) {
      print('[UNS-ERR] No base URL configured for fetch');
      return;
    }

    // Build primary URL using original base and path
    Uri primaryUri = _uri('/api/notifications/getMyNotifications');

    Map<String, String> headers = _headers(authToken);

    // 1) Try POST on primaryUri
    print('[UNS] Attempting POST on $primaryUri');
    final postResp = await _tryRequest(primaryUri, headers, method: 'POST', body: '');
    if (postResp != null && postResp.statusCode >= 200 && postResp.statusCode < 300) {
      // success -> parse
      await _processFetchResponse(postResp);
      return;
    }

    // If we got a 404 or other non-success, try GET on same URL
    if (postResp != null && postResp.statusCode == 404) {
      print('[UNS] POST returned 404, retrying as GET on same URL');
      final getResp = await _tryRequest(primaryUri, headers, method: 'GET');
      if (getResp != null && getResp.statusCode >= 200 && getResp.statusCode < 300) {
        await _processFetchResponse(getResp);
        return;
      }
      // If still not OK, continue to alternate scheme
    } else if (postResp == null) {
      print('[UNS] POST request failed (network/exception), attempting GET as fallback');
      final getResp = await _tryRequest(primaryUri, headers, method: 'GET');
      if (getResp != null && getResp.statusCode >= 200 && getResp.statusCode < 300) {
        await _processFetchResponse(getResp);
        return;
      }
    } else {
      print('[UNS] POST response status ${postResp.statusCode} - attempting fallbacks');
    }

    // 2) Try alternate scheme (http <-> https) if primaryBase included a scheme
    try {
      final altBase = _flipScheme(originalBase);
      if (altBase != null && altBase.isNotEmpty && altBase != originalBase) {
        final altUri = _buildUriWithBase(altBase, '/api/notifications/getMyNotifications');
        print('[UNS] Trying alternate scheme: $altUri (method POST)');
        final altPost = await _tryRequest(altUri, headers, method: 'POST', body: '');
        if (altPost != null && altPost.statusCode >= 200 && altPost.statusCode < 300) {
          await _processFetchResponse(altPost);
          return;
        }
        if (altPost != null && altPost.statusCode == 404) {
          print('[UNS] Alternate POST returned 404, retrying as GET');
          final altGet = await _tryRequest(altUri, headers, method: 'GET');
          if (altGet != null && altGet.statusCode >= 200 && altGet.statusCode < 300) {
            await _processFetchResponse(altGet);
            return;
          }
        }
      }
    } catch (e) {
      print('[UNS-ERR] alternate scheme attempt exception: $e');
    }

    print('[UNS-ERR] All fetch attempts failed (POST/GET/alternate). No notifications merged.');
  }

  // Process a successful fetch response: parse, merge, and save
  Future<void> _processFetchResponse(http.Response resp) async {
    try {
      final body = _tryDecode(resp.body);
      final List<dynamic> payloadList = _extractListFromResponse(body);
      print('[UNS] Server returned ${payloadList.length} notification items (processing)');
      int added = 0;
      for (final e in payloadList) {
        final model = NotificationModel.fromJson(_asMap(e));
        if (!_notifications.any((n) => n.id == model.id)) {
          await addNotificationFromModel(model);
          added++;
        } else {
          print('[UNS] _processFetchResponse: skipped duplicate id=${model.id}');
        }
      }
      print('[UNS] _processFetchResponse: merged $added new notifications');
    } catch (e) {
      print('[UNS-ERR] Failed to process fetch response: $e');
    }
  }

  // Helpers to build Uri/headers and flip scheme
  Uri _uri(String path) {
    final base = (_baseUrl ?? ApiConfig.baseUrl) ?? '';
    final trimmedBase = base.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$trimmedBase$path');
  }

  Uri _buildUriWithBase(String base, String path) {
    final trimmedBase = base.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$trimmedBase$path');
  }

  String? _flipScheme(String base) {
    try {
      if (base.startsWith('https://')) {
        return base.replaceFirst('https://', 'http://');
      } else if (base.startsWith('http://')) {
        return base.replaceFirst('http://', 'https://');
      } else {
        // no explicit scheme - try https then http
        return 'https://$base';
      }
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _headers([String? auth]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth != null && auth.isNotEmpty) headers['Authorization'] = 'Bearer $auth';
    return headers;
  }

  Future<http.Response?> registerDeviceTokenForRole({
    required String role,
    required String userId,
    String? authToken,
    String? customBaseUrl,
    String? customRegisterPath,
  }) async {
    final base = customBaseUrl ?? _baseUrl ?? ApiConfig.baseUrl;
    if (base == null) throw Exception('Base URL not set for UniversalNotificationService');

    final path = customRegisterPath ?? _registerPath;
    final url = Uri.parse('${base.replaceAll(RegExp(r'/$'), '')}$path');

    final fcmToken = await _fm.getToken();
    if (fcmToken == null) {
      print('[UNS] registerDeviceTokenForRole: no FCM token available');
      return null;
    }

    final payload = {
      'role': role,
      'userId': userId,
      'fcmToken': fcmToken,
    };

    try {
      print('[UNS] registerDeviceTokenForRole POST $url payload=${json.encode(payload)}');
      final resp = await http.post(url,
          headers: _headers(authToken), body: json.encode(payload));
      print('[UNS] registerDeviceTokenForRole status=${resp.statusCode} body=${resp.body}');
      return resp;
    } catch (e) {
      print('[UNS-ERR] registerDeviceTokenForRole exception: $e');
      return null;
    }
  }

  Future<http.Response?> registerStudentDevice({
    required String studentPhone,
    String? authToken,
    String? customBaseUrl,
    String? customRegisterPath,
  }) =>
      registerDeviceTokenForRole(
        role: 'Student',
        userId: studentPhone,
        authToken: authToken,
        customBaseUrl: customBaseUrl,
        customRegisterPath: customRegisterPath,
      );

  Future<http.Response?> registerTeacherDevice({
    required String teacherId,
    String? authToken,
    String? customBaseUrl,
    String? customRegisterPath,
  }) =>
      registerDeviceTokenForRole(
        role: 'Teacher',
        userId: teacherId,
        authToken: authToken,
        customBaseUrl: customBaseUrl,
        customRegisterPath: customRegisterPath,
      );

  Future<void> markAsRead(String id,
      {bool syncWithServer = false, String? serverToken, String? customMarkReadPath}) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx].isRead = true;
    await _saveToStorage();
    _notificationsController.add(List.unmodifiable(_notifications));

    if (syncWithServer) {
      final base = _baseUrl ?? ApiConfig.baseUrl;
      if (base == null) return;
      final path = customMarkReadPath ?? _markReadPath;
      final url = Uri.parse('${base.replaceAll(RegExp(r'/$'), '')}$path');
      try {
        final resp = await http.post(url,
            headers: _headers(serverToken), body: json.encode({'id': id}));
        print('[UNS] markAsRead status=${resp.statusCode} body=${resp.body}');
      } catch (e) {
        print('[UNS-ERR] markAsRead exception: $e');
      }
    }
  }

  Future<void> markAllAsRead({bool syncWithServer = false, String? serverToken, String? customMarkAllPath}) async {
    for (var n in _notifications) n.isRead = true;
    await _saveToStorage();
    _notificationsController.add(List.unmodifiable(_notifications));

    if (syncWithServer) {
      final base = _baseUrl ?? ApiConfig.baseUrl;
      if (base == null) return;
      final path = customMarkAllPath ?? _markAllReadPath;
      final url = Uri.parse('${base.replaceAll(RegExp(r'/$'), '')}$path');
      try {
        final resp = await http.post(url, headers: _headers(serverToken), body: json.encode({}));
        print('[UNS] markAllAsRead status=${resp.statusCode} body=${resp.body}');
      } catch (e) {
        print('[UNS-ERR] markAllAsRead exception: $e');
      }
    }
  }

  dynamic _tryDecode(String body) {
    if (body.isEmpty) return null;
    try {
      return json.decode(body);
    } catch (_) {
      return body;
    }
  }

  List<dynamic> _extractListFromResponse(dynamic body) {
    if (body == null) return <dynamic>[];
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      if (body['data'] is List) return body['data'] as List<dynamic>;
      if (body['notifications'] is List) return body['notifications'] as List<dynamic>;
      return [body];
    }
    return <dynamic>[];
  }

  Map<String, dynamic> _asMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    try {
      return json.decode(item.toString()) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }
  Future<NotificationModel?> getNotificationDetails(String id, {String? authToken}) async {
    final url = _uri('/api/notifications/getNotificationDetails/$id');
    // Use _tryRequest helper if available; otherwise use a direct GET
    final resp = await _tryRequest(url, _headers(authToken), method: 'GET');
    if (resp != null && resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = _tryDecode(resp.body);
      if (body is Map<String, dynamic>) {
        final maybeData = body['data'] ?? body;
        return NotificationModel.fromJson(_asMap(maybeData));
      } else if (body is List && body.isNotEmpty) {
        return NotificationModel.fromJson(_asMap(body.first));
      } else {
        return null;
      }
    } else {
      // No data or non-2xx — return null
      print('[UNS-ERR] getNotificationDetails failed status=${resp?.statusCode ?? "null"}');
      return null;
    }
  }
  Future<String> debugDumpStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kNotificationsKey) ?? '';
      print('[UNS-DBG] debugDumpStorage -> ${jsonString.length} chars');
      return jsonString;
    } catch (e) {
      print('[UNS-ERR] debugDumpStorage exception: $e');
      return '';
    }
  }

  Future<void> dispose() async {
    await _notificationsController.close();
    print('[UNS] disposed');
  }
}