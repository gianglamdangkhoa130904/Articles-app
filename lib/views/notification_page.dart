import 'dart:convert';
import 'package:final_project/default/default.dart';
import 'package:final_project/models/article_model.dart';
import 'package:final_project/models/user_model.dart';
import 'package:final_project/views/search_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class NotificationModel {
  final String id;
  final User? actor;
  final String actionDetail;
  final Article? article;
  final String? comment;
  final String createdAt;

  NotificationModel({
    required this.id,
    this.actor,
    required this.actionDetail,
    this.article,
    this.comment,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      actor: _parseUserID(json['actor']),
      actionDetail: json['actionDetail'] ?? '',
      article: json['article'] != null ? Article.fromJson(json['article']) : null,
      comment: json['comment'],
      createdAt: json['createdAt'] ?? '',
    );
  }
  
  static User _parseUserID(dynamic userIDData) {
    if (userIDData == null) {
      // Có thể throw exception hoặc return default User
      throw Exception('UserID không thể null');
    }
    
    if (userIDData is Map<String, dynamic>) {
      // Nếu userID là populated object, sử dụng User.fromJson()
      return User.fromJson(userIDData);
    } else if (userIDData is String) {
      // Nếu chỉ có ID string, tạo User object với thông tin tối thiểu
      // Hoặc có thể fetch thêm thông tin user từ API khác
      return User.fromJson({
        '_id': userIDData,
        'id': userIDData,
        'username': 'Loading...', // Temporary, có thể fetch sau
        'avatar': '',
        // Thêm các field required khác của User model
      });
    } else {
      // Fallback: convert về Map và parse
      return User.fromJson({
        '_id': userIDData.toString(),
        'username': 'Unknown User',
        'avatar': '',
      });
    }
  }
  String get avatar => actor?.avatar ?? '';
}
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> notifyList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // Fetch notifications từ API
  Future<void> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('customerId');
    try {
      setState(() {
        isLoading = true;
      });
      
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/notifications/$userID'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<NotificationModel> notifications = [];
        
        for (var notifyData in data) {
          notifications.add(NotificationModel.fromJson(notifyData));
        }
        
        setState(() {
          notifyList = notifications.reversed.toList(); // Reverse như trong ReactJS
        });
      } else {
        print('Không có thông báo nào');
      }
    } catch (error) {
      print('Error fetching notifications: $error');
      _showSnackBar('Có lỗi xảy ra khi tải thông báo');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Navigate to article page
  void handleNotifyArticle(Article article) {
    Navigator.pushNamed(
      context,
      '/article',
      arguments: article.toJson(),
    );
  }

  // Navigate to user profile
  void handleNotifyUser(String userID) {
    Navigator.pushNamed(
      context,
      '/users/$userID',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(preferredSize: Size.fromHeight(60), 
        child: Container(
          padding: EdgeInsets.only(top: 10, bottom: 12, left: 20, right: 20),
          decoration: BoxDecoration(
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
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width > 768 
              ? MediaQuery.of(context).size.width * 0.5 
              : MediaQuery.of(context).size.width * 0.9,
          child: Column(
            children: [
              // Header
              SizedBox(height: 16,),
              Text('Thông báo', style: TextStyle(color: colorBG, fontSize: 26, fontWeight: FontWeight.bold),),
              // Content
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: colorBG),
                      )
                    : notifyList.isEmpty
                        ? Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              'Không có thông báo nào',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorBG,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          )
                        : Container(
                          margin: EdgeInsets.only(top: 16),
                          child: ListView.builder(
                              itemCount: notifyList.length,
                              itemBuilder: (context, index) {
                                final notification = notifyList[index];
                                
                                return Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.only(top: 16),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: Offset(1, 3),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      if (notification.article != null) {
                                        handleNotifyArticle(notification.article!);
                                      } else {
                                        handleNotifyUser(notification.actor?.id ?? '');
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        // Avatar
                                        ClipOval(
                                          child: Image.network(
                                            "https://dhkptsocial.onrender.com/files/download/" + notification.avatar,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(Icons.person, color: Colors.grey);
                                            },
                                          ),
                                        ),
                                        
                                        SizedBox(width: 16),
                                        
                                        // Content
                                        Expanded(
                                          child: Text(
                                            '${notification.actor?.name ?? 'Unknown'} ${notification.actionDetail}',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: MediaQuery.of(context).size.width > 768 ? 18 : 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ),
              ),
              SizedBox(height: 20,),
            ],
          ),
        ),
      ),
    );
  }
}