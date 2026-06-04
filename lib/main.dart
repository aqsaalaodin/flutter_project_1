import 'package:flutter/material.dart';
import 'package:flutter_project_1/NotificationService.dart';
import 'package:flutter_project_1/dashboardscreen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ✅ Top-level — class ke bahar zaroori hai
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init(
    onBackground: notificationTapBackground,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleIfNeeded();
    }
  }

  void _scheduleIfNeeded() async {
    if (!_scheduled) {
      _scheduled = true;
      await NotificationService.scheduleAll();
      Future.delayed(const Duration(seconds: 35), () {
        if (mounted) setState(() => _scheduled = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}