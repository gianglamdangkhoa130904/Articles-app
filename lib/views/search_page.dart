import 'package:final_project/default/default.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tìm kiếm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: colorBG,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text("Trang tìm kiếm", 
        style: TextStyle(fontSize: 32),
        )
      ),
    );
  }
}