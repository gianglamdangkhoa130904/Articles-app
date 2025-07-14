import 'package:final_project/default/default.dart';
import 'package:final_project/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}
void _handleLogout(BuildContext context) async{
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('customerId');
  await prefs.remove('cached_articles');
  await prefs.remove('cache_timestamp');
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginPage()),
    (Route<dynamic> route) => false,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đăng xuất thành công'), backgroundColor: Colors.green,),
  );
}
class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Cài đặt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
          backgroundColor: colorBG,
          centerTitle: true,
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => _handleLogout(context), 
              child: Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                )
              ),
            )
          ],
        ),
      ) 
    );
  }
}