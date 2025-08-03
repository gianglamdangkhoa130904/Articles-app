import 'package:final_project/default/default.dart';
import 'package:final_project/models/comment_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final String userID;
  final String userName;
  final String userAvatar;
  const CommentItem({
    super.key,
    this.userAvatar = 'https://picsum.photos/400/200?random=1',
    this.userName = "Kenshin", 
    this.userID = '1111',
    required this.comment,
  });
  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  String userID = '';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(widget.userAvatar);
    getCurrentUser();
  }
  getCurrentUser() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('customerId')!;
    });
  }
  String _formatUserName(String userName) {
  if (userName.length > 10) {
    return userName.substring(0, 11) + "...";
  }
  return userName;
}
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(width: 20),
        SizedBox(
          width: 44,
          height: 44,
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child: Image.network(
                "https://dhkptsocial.onrender.com/files/download/" + widget.userAvatar,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, color: Colors.grey);
                },
              ),
            ),
          ),
        ),
        
        SizedBox(width: 10),
        
        // Sử dụng Flexible để không bị overflow nhưng vẫn wrap content
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tên user với xử lý tên dài
              Container(
                padding: EdgeInsets.only(left: 8, right: 16),
                child: Text(
                  _formatUserName(widget.userName), // Gọi function format tên
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1, // Đảm bảo chỉ 1 dòng
                ),
              ),
              
              SizedBox(height: 4),
              
              // Container chứa comment - wrap theo nội dung
              IntrinsicWidth(
                child: Container(
                  constraints: BoxConstraints( // Chiều rộng tối thiểu
                    maxWidth: MediaQuery.of(context).size.width * 0.7, // Tối đa 70% màn hình
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16), 
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: userID == widget.userID ? colorBG : Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Quan trọng: chỉ chiếm không gian cần thiết
                    children: [
                      Flexible( // Trở lại Flexible để wrap content
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.comment.commentDetail,
                              style: TextStyle(fontSize: 14),
                              softWrap: true,
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.comment.timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(width: 8),
                      
                      Container(
                        width: 40,
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            // Handle menu action
                          },
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}