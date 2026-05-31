import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Handles Firebase Cloud Messaging token registration and foreground notifications.
/// Call [init] once after the user logs in successfully.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _apiService = ApiService();

  static const _androidChannel = AndroidNotificationChannel(
    'rspcm_channel',
    'RSPCM Уведомления',
    description: 'Уведомления о практиках и экзаменах',
    importance: Importance.high,
  );

  FirebaseMessaging? _getMessaging() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    final fcm = _getMessaging();
    if (fcm == null) return; // Firebase not configured — skip silently

    // Request permission (iOS / Android 13+)
    final settings = await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Initialize local notifications plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initSettings);

    // Register token
    await _registerToken(fcm);

    // Refresh token if it changes (e.g. reinstall)
    fcm.onTokenRefresh.listen(_sendTokenToServer);

    // Handle foreground messages as local notifications
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  Future<void> _registerToken(FirebaseMessaging fcm) async {
    final token = await fcm.getToken();
    if (token != null) {
      await _sendTokenToServer(token);
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    await _apiService.registerFcmToken(token);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
