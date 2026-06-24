import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'main.dart';

class NotificacionService {
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

 Future<void> inicializar() async {
    if (kIsWeb) return;

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel_v4', 
      'Alertas Prioritarias UDI',
      description: 'Este canal muestra banners emergentes (Heads-up).',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );
    
    // --- ERROR 1 CORREGIDO AQUÍ ---
    // Le agregamos la etiqueta "settings:"
    await _localNotifications.initialize(
      settings: initializationSettings, 
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    try {
      final FirebaseMessaging fcm = FirebaseMessaging.instance;
      await fcm.requestPermission(alert: true, badge: true, sound: true);

      String? token = await fcm.getToken();
      if (token != null) _enviarTokenAlServidor(token);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        
        if (notification != null) {
          // --- ERROR 2 CORREGIDO AQUÍ ---
          // Le ponemos su etiqueta a cada uno de los 4 datos
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title ?? '',
            body: notification.body ?? '',
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id, 
                channel.name,
                channelDescription: channel.description,
                importance: Importance.max,
                priority: Priority.max,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });
    } catch (e) {
      print("❌ Error en NotificacionService: $e");
    }
  }
  Future<void> _enviarTokenAlServidor(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? idUsuario = prefs.getString('userKey'); 

    if (idUsuario != null) {
      try {
        await http.post(
          Uri.parse('$urlBase/guardar-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_usuario': idUsuario, 'token': token}),
        );
      } catch (e) {
        print("❌ Error enviando token: $e");
      }
    }
  }
}