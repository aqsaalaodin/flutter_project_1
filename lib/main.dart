import 'package:flutter/material.dart';
import 'package:flutter_project_1/SplashScreen.dart';
//import 'package:flutter/material.dart';
import 'package:flutter_project_1/NotificationService.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(
    onBackground: notificationTapBackground,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}