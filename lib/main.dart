import 'package:final_project/views/bottom_nav_test.dart';
import 'package:final_project/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasLogin = prefs.containsKey('customerId');
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SafeArea(
      child: hasLogin ? NavigationTest() : const LoginPage()
    ),
  ));
}