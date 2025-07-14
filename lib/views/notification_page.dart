import 'package:final_project/default/default.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thông báo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: colorBG,
        centerTitle: true,
      ),
      body: Center(
        child: Text("Danh sách thông báo", 
        style: TextStyle(fontSize: 32),
        )
      ),
    );
  }
}