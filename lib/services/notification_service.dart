import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tappée: ${details.payload}');
      },
    );
  }

  Future<void> showGasAlert(double gasLevel) async {
    const androidDetails = AndroidNotificationDetails(
      'gas_detector_channel',
      'Alertes de gaz',
      channelDescription: 'Notifications pour les alertes de niveau de gaz',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Alerte Niveau de Gaz !',
      'Niveau dangereux détecté : ${gasLevel.toStringAsFixed(2)} ppm',
      details,
      payload: 'gasLevel:$gasLevel',
    );
  }
}
