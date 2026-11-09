import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules a local reminder when a titipan's due date arrives. The reminder
/// is only a marker: the titipan can still be settled after its due date.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      // No notification support (e.g. tests / unsupported platform).
    }
    _initialized = true;
  }

  /// Schedules (or reschedules) a due-date reminder for [titipanId].
  Future<void> scheduleDueDate({
    required int titipanId,
    required String personName,
    required DateTime dueDate,
  }) async {
    try {
      await init();
      await cancel(titipanId);

      // 9 AM on the due date; skip if that moment already passed.
      final when = tz.TZDateTime(
        tz.local,
        dueDate.year,
        dueDate.month,
        dueDate.day,
        9,
      );
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

      await _plugin.zonedSchedule(
        titipanId,
        'Jatuh tempo titipan',
        'Titipan dengan $personName sudah jatuh tempo hari ini.',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'titipan_due',
            'Jatuh Tempo Titipan',
            channelDescription: 'Pengingat jatuh tempo titipan',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Best-effort: a missing plugin must never break saving a titipan.
    }
  }

  /// Cancels the reminder for [titipanId] (settled or deleted).
  Future<void> cancel(int titipanId) async {
    try {
      await _plugin.cancel(titipanId);
    } catch (_) {
      // Best-effort.
    }
  }
}
