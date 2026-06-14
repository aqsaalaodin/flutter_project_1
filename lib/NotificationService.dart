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

    await _plugin
        .resolvePlatformSpecificImplementation<  // ← yahan < > sahi hai
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─── Schedule All Notifications ───────────────────────────────────────────
  static Future<void> scheduleAll() async {
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
    'body': 'You have items waiting in your cart. Complete your purchase and save!'
  },
];

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'diamond_paint_channel',
        'Diamond Paint Notifications',
        channelDescription: 'Diamond Paint app ke updates',
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
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // ← yeh add karo
  );
}
  }
}