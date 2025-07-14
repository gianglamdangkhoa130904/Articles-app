import 'package:final_project/default/default.dart';
import 'package:final_project/views/setting_page.dart';
import 'package:flutter/material.dart';

class UserInforPage extends StatefulWidget {
  const UserInforPage({super.key});

  @override
  State<UserInforPage> createState() => _UserInforPageState();
}

class _UserInforPageState extends State<UserInforPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thông tin người dùng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: colorBG,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SettingPage()));
            }, 
            icon: Icon(Icons.settings, color: Colors.white,)
          )
        ],
      ),
      body: Center(
        child: Text("Thông tin người dùng", 
        style: TextStyle(fontSize: 32),
        )
      ),
    );
  }
}