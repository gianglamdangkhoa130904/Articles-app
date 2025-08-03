import 'package:final_project/components/post.dart';
import 'package:final_project/default/default.dart';
import 'package:final_project/views/search_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget{
  const HomePage({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(preferredSize: Size.fromHeight(60), 
        child: Container(
          padding: EdgeInsets.only(top: 10, bottom: 12, left: 20, right: 20),
          decoration: BoxDecoration(
            // gradient: LinearGradient(
            //   begin: Alignment.bottomCenter,
            //   end: Alignment.topRight,
            //   colors: [
            //     Colors.white,
            //     Colors.white,
            //     Colors.white,
            //     Colors.white,
            //     Colors.white,
            //     Colors.white,
            //     Colors.white,
            //     Colors.white,
            //     Colors.white,
            //     Colors.white,
            //     colorBG,
            //   ],
            // ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black38, // Màu bóng
                blurRadius: 5,        // Độ mờ (càng lớn, càng mềm)
                spreadRadius: 2,       // Độ lan rộng của bóng
                offset: Offset(1, 4),  // Dịch chuyển bóng theo x,y
              ),
              
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/logo.png'),
              IconButton(
                onPressed: () => {Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage()),
                )}, 
                icon: Icon(Icons.search_sharp, color: colorBG, size: 25,))
              ],
            ),
          )
      ),
      body: PostScreen(),
    );
  }
}