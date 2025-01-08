import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class NotificationService extends ChangeNotifier {
  static const _vibrationPattern = [0, 500, 200, 500];
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _areNotificationsEnabled = false;
  bool _initialized = false;

  bool get areNotificationsEnabled => _areNotificationsEnabled;

  NotificationService() {
    _initNotifications();
    initializeNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      debugPrint('Initialisation des notifications...');
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      
      final success = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );
      
      _initialized = true;
      debugPrint('Notifications initialisées avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      final success = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      _areNotificationsEnabled = success ?? false;
      debugPrint('Notifications initialisées avec succès');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des notifications: $e');
      _areNotificationsEnabled = false;
      notifyListeners();
    }
  }

  Future<void> checkNotificationPermissions() async {
    if (await Permission.notification.isDenied) {
      _areNotificationsEnabled = false;
      notifyListeners();
      return;
    }
    
    _areNotificationsEnabled = true;
    notifyListeners();
  }

  Future<void> requestNotificationPermissions() async {
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      final iosPermissions = await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _areNotificationsEnabled = iosPermissions ?? true;
    } else {
      _areNotificationsEnabled = false;
    }
    
    notifyListeners();
  }

  Future<void> showGasAlert(String gasName, double level, int criticalLevel) async {
    if (!_areNotificationsEnabled) {
      debugPrint('Notifications are not enabled');
      return;
    }

    if (!_initialized) {
      debugPrint('Notifications non initialisées, tentative de réinitialisation...');
      await _initNotifications();
    }

    try {
      debugPrint('Préparation de la notification pour $level PPM (seuil: $criticalLevel PPM)');
      
      // Définir le niveau de danger
      String dangerLevel;
      if (level >= 2000) {
        dangerLevel = "DANGER EXTRÊME";
      } else if (level >= 1000) {
        dangerLevel = "DANGER";
      } else if (level >= 250) {
        dangerLevel = "ATTENTION";
      } else {
        dangerLevel = "NORMAL";
      }

      // Formater le niveau de gaz avec 1 décimale
      String formattedPPM = level.toStringAsFixed(1);
      
      debugPrint('Envoi notification: $dangerLevel - $formattedPPM PPM');

      final androidDetails = AndroidNotificationDetails(
        'gas_alerts',
        'Gas Alerts',
        channelDescription: 'Alertes de niveau de gaz',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(_vibrationPattern),
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alert_sound.wav',
        badgeNumber: 1,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0,
        '$dangerLevel - Niveau de $gasName Élevé',
        'Niveau actuel: $formattedPPM PPM\nSeuil critique: $criticalLevel PPM',
        details,
        payload: 'gas_alert',
      );
      
      debugPrint('Notification envoyée avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  Future<void> showConnectionAlert(String message) async {
    if (!_areNotificationsEnabled) {
      debugPrint('Notifications are not enabled');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'connection_alerts',
      'Connection Alerts',
      channelDescription: 'Alertes de connexion WiFi',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(_vibrationPattern),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Alerte Connexion',
      message,
      details,
      payload: 'connection_alert',
    );
  }

  Future<void> showTestNotification() async {
    if (!_areNotificationsEnabled) {
      debugPrint('Notifications are not enabled');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Canal pour tester les notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(_vibrationPattern),
      playSound: true,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 0, 0, 255),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2,
      'Test de Notification',
      'Si vous voyez ceci, les notifications fonctionnent correctement! ',
      details,
      payload: 'test_notification',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
