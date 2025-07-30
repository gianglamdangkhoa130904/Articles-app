import 'dart:convert';
import 'package:final_project/models/comment_model.dart';
import 'package:final_project/models/user_model.dart';
import 'package:flutter/material.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final String user;
  const CommentItem({
    super.key,
    this.user = "name:Kenshin,...", 
    required this.comment,
  });
  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  String userName = "Kenshin";
  String userAvatar = "https://picsum.photos/400/200?random=1";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // User user = User.fromJson(json.decode(widget.user));
    // userName = user.name;
    // userAvatar = user.avatar!;
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: ClipOval(
            child: Image.network(
              userAvatar,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              userName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(widget.comment.commentDetail),
                  SizedBox(width: 10),
                  IconButton(onPressed: (){}, icon: Icon(Icons.more_vert, color: Colors.black,))
              ],
              )
            ),
          ],
        ),
      ],
    );
  }
}