import 'package:flutter/material.dart';
import 'package:flutter_project_1/NotificationService.dart';
import 'package:flutter_project_1/dashboardscreen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init ke andar hi Android permissions request ho jaati hain
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
    // App background se wapas aaye to dobara schedule karo
    if (state == AppLifecycleState.resumed) {
      _scheduleIfNeeded();
    }
  }

  Future<void> _scheduleIfNeeded() async {
    if (!_scheduled) {
      _scheduled = true;
      await NotificationService.scheduleAll();
      // 35 seconds baad flag reset — taake next resume pe dobara schedule ho sake
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