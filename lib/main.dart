import 'package:flutter/material.dart';
//import 'package:flutter_project_1/UserManagementScreen.dart';
import 'package:flutter_project_1/dashboardscreen.dart';

//import 'package:student_management_system/CreateUserScreen.dart';
//import 'package:student_management_system/UserManagementScreen.dart';
//import 'package:student_management_system/HomeScreen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

