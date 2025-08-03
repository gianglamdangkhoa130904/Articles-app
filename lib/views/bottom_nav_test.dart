import 'package:final_project/default/default.dart';
import 'package:final_project/views/chat_list_page.dart';
import 'package:final_project/views/create_post_page.dart';
import 'package:final_project/views/home_page.dart';
import 'package:final_project/views/infor/user_profile_page.dart';
import 'package:final_project/views/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RightBottomVerticalNav();
  }
}

class RightBottomVerticalNav extends StatefulWidget  {
  @override
  _RightBottomVerticalNavState createState() => _RightBottomVerticalNavState();
}

class _RightBottomVerticalNavState extends State<RightBottomVerticalNav> with TickerProviderStateMixin {
  int _selectedIndex = 3;
  bool _isExpanded = false;
  String? customerId;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
     _loadCustomerId();
  }
  Future<void> _loadCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    customerId = prefs.getString('customerId');
    setState(() {
      customerId = prefs.getString('customerId');
    });
  }
  
  List<Widget> get  _views => [
    UserProfilePage(userId: customerId ?? ''),
    ChatListPage(),
    NotificationPage(),
    HomePage(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
      _isExpanded = false;
    });
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;

    return AnimatedOpacity(
      opacity: _isExpanded ? 1 : 0,
      duration: Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorBG : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Chuyển sang trang tạo bài đăng mới
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostPage()),
          );
        },
        backgroundColor: colorBG, // Sử dụng màu chính của app
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Stack(
          children: [
            _views[_selectedIndex], // Gọi view thật
        
            // Thanh nav bên phải dưới
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(
                        blurRadius: 5, 
                        color: Colors.black26,
                        spreadRadius: 1,       
                        offset: Offset(0, 5),  )],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isExpanded) _buildNavItem(Icons.person, 0),
                          if (_isExpanded) _buildNavItem(Icons.chat, 1),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorBG,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _isExpanded ? Icons.close : Icons.menu,
                                  color: Colors.white,
                                ),
                              ),
                          ),
                          if (_isExpanded) _buildNavItem(Icons.notifications, 2),
                          if (_isExpanded) _buildNavItem(Icons.home, 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
