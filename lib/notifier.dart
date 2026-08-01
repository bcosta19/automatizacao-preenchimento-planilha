import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const _channelCheckin = AndroidNotificationDetails(
    'checkin_diario',
    'Check-in diário',
    channelDescription: 'Lembrete para preencher o check-in do dia',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _channelSport = AndroidNotificationDetails(
    'outro_esporte',
    'Lembrete de esporte',
    channelDescription: 'Lembrete para marcar outro esporte feito no dia',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> scheduleAll(Settings s) async {
    await _plugin.cancelAll();
    if (!s.notificationsEnabled) return;

    await _plugin.zonedSchedule(
      id: 1,
      title: 'Hora do check-in!',
      body: 'Preencha seu check-in de hoje (fim do dia).',
      scheduledDate: _nextTime(s.endOfDayHour, s.endOfDayMinute),
      notificationDetails: const NotificationDetails(android: _channelCheckin),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    for (final day in s.sportDays) {
      if (day < DateTime.monday || day > DateTime.sunday) continue;
      await _plugin.zonedSchedule(
        id: 100 + day,
        title: 'Outro esporte',
        body: 'Fez ${s.defaultSport} (ou outro esporte) hoje?',
        scheduledDate: _nextWeekday(day, s.sportHour, s.sportMinute),
        notificationDetails: const NotificationDetails(android: _channelSport),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> testNotification() async {
    await _plugin.show(
      id: 999,
      title: 'Notificação de teste',
      body: 'Seu check-in está configurado e os lembretes funcionando.',
      notificationDetails: const NotificationDetails(android: _channelCheckin),
    );
  }

  static tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (next.weekday != weekday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
