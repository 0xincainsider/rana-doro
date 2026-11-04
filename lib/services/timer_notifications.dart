import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../core/brand.dart';
import '../features/timer/domain/timer_phase.dart';

abstract interface class TimerNotifications {
  Future<bool> requestPermission();

  Future<void> schedule({required DateTime endsAt, required TimerPhase phase});

  Future<void> cancel();
}

class NoopTimerNotifications implements TimerNotifications {
  const NoopTimerNotifications();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required DateTime endsAt,
    required TimerPhase phase,
  }) async {}

  @override
  Future<void> cancel() async {}
}

class LocalTimerNotifications implements TimerNotifications {
  static const int _notificationId = 1;
  static const String _channelId = 'timer_fin';
  static const String _channelName = 'Fin de sesión';
  static const String _channelDescription =
      'Aviso silencioso cuando termina una fase';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      timezone_data.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_frog'),
        ),
      );
      _ready = true;
    } on Object {
      _ready = false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) {
      return false;
    }
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> schedule({
    required DateTime endsAt,
    required TimerPhase phase,
  }) async {
    if (!_ready) {
      return;
    }
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications();
      final scheduleMode = canExact == false
          ? AndroidScheduleMode.inexactAllowWhileIdle
          : AndroidScheduleMode.exactAllowWhileIdle;

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: 'ic_stat_frog',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        silent: true,
        onlyAlertOnce: true,
        category: AndroidNotificationCategory.reminder,
      );

      await _plugin.zonedSchedule(
        id: _notificationId,
        title: kAppName,
        body: phase == TimerPhase.focus
            ? kNotificationFocusDone
            : kNotificationBreakDone,
        scheduledDate: timezone.TZDateTime.from(endsAt.toUtc(), timezone.UTC),
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: scheduleMode,
        payload: phase.name,
      );
    } on Object {
      return;
    }
  }

  @override
  Future<void> cancel() async {
    if (!_ready) {
      return;
    }
    try {
      await _plugin.cancel(id: _notificationId);
    } on Object {
      return;
    }
  }
}
