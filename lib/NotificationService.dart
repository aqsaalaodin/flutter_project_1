import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ─── Initialize ───────────────────────────────────────────────────────────
  static Future<void> init({
    required void Function(NotificationResponse) onBackground,
  }) async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse r) {},
      onDidReceiveBackgroundNotificationResponse: onBackground,
    );

    // Request Android permissions directly inside init (no context needed)
    await _requestAndroidPermissions();
  }

  // ─── Android Permissions (without context) ────────────────────────────────
  static Future<void> _requestAndroidPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return;

    // Step 1: POST_NOTIFICATIONS — shows dialog on Android 13+ (API 33+)
    // On Android 12 and below this is automatically granted
    await androidImpl.requestNotificationsPermission();

    // Step 2: SCHEDULE_EXACT_ALARM — required for Android 12+ (API 31+)
    // Opens system settings dialog if permission is not granted
    await androidImpl.requestExactAlarmsPermission();
  }

  // ─── Check Current Permission Status ─────────────────────────────────────
  static Future<bool> arePermissionsGranted() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final notifGranted =
          await androidImpl.areNotificationsEnabled() ?? false;

      // canScheduleExactNotifications() is not available below Android 12
      // so only check it on Android 12 and above
      bool exactAlarmGranted = true;
      if (await _isAndroid12OrAbove()) {
        exactAlarmGranted =
            await androidImpl.canScheduleExactNotifications() ?? false;
      }

      return notifGranted && exactAlarmGranted;
    }

    // iOS — handled at init time
    return true;
  }

  // ─── Android Version Check Helper ─────────────────────────────────────────
  static Future<bool> _isAndroid12OrAbove() async {
    // flutter_local_notifications v18 does not expose SDK version directly
    // so we use try-catch to determine if the device is Android 12+
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.canScheduleExactNotifications();
      return true; // No error means Android 12+
    } catch (_) {
      return false; // Android 11 or below
    }
  }

  // ─── Show Exact Alarm Dialog (if permission still not granted) ─────────────
  // Call this from DashboardScreen once the app is fully loaded
  static void showExactAlarmDialogIfNeeded(BuildContext context) async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return;

    final canSchedule =
        await androidImpl.canScheduleExactNotifications() ?? false;

    if (!canSchedule && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'To receive notifications on time, please enable '
            '"Alarms & Reminders" permission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                androidImpl.requestExactAlarmsPermission();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  // ─── Schedule All Notifications ───────────────────────────────────────────
  static Future<void> scheduleAll() async {
    final hasPermission = await arePermissionsGranted();
    if (!hasPermission) {
      debugPrint('Notifications: Permission not granted, skipping scheduling');
      return;
    }

    await _plugin.cancelAll();

    final List<Map<String, String>> notifications = [
      {
        'title': '💎 New Diamond Paint Design!',
        'body': 'Check out today\'s featured design - Limited time offer!'
      },
      {
        'title': '🎨 Your Order is Ready!',
        'body': 'Your diamond paint kit has been dispatched. Track it now!'
      },
      {
        'title': '⭐ Flash Sale - 30% Off!',
        'body': 'Today only! Huge discounts on all diamond paint kits.'
      },
      {
        'title': '🖼️ New Collection Arrived!',
        'body': 'The Winter 2024 collection is now available. Explore it today!'
      },
      {
        'title': '💡 Tip of the Day',
        'body': 'Round drills are the best choice for beginners in diamond painting!'
      },
      {
        'title': '🏆 Complete Your Order!',
        'body':
            'You have items waiting in your cart. Complete your purchase and save!'
      },
    ];

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'diamond_paint_channel',
        'Diamond Paint Notifications',
        channelDescription: 'Updates from the Diamond Paint app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    for (int i = 0; i < notifications.length; i++) {
      await _plugin.zonedSchedule(
        i,
        notifications[i]['title']!,
        notifications[i]['body']!,
        tz.TZDateTime.now(tz.local).add(Duration(seconds: (i + 1) * 5)),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    debugPrint('Notifications: ${notifications.length} notifications scheduled');
  }
}