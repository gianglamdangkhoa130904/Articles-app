import 'package:final_project/components/card_post.dart';
import 'package:final_project/components/comment_item.dart';
import 'package:final_project/components/post.dart';
import 'package:final_project/default/default.dart';
import 'package:final_project/models/comment_model.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommentPage extends StatefulWidget {
  final String id;
  final String content;
  final String authorID;
  final String author;
  final String avatar;
  final String createdAt;
  final String articleStatus;
  final int numberOfComment;
  final int numberOfLike;
  final List<ImageFile> listImage;
  final bool isLiked;
  final String likeID;

  const CommentPage({
    super.key,
    this.id = "123",
    this.content = "mô tả bài viết",
    this.authorID = '',
    this.author = "Tác giả",
    this.createdAt = "13/09/2004",
    this.articleStatus = "active",
    this.numberOfComment = 123,
    this.numberOfLike = 123,
    this.avatar = 'https://picsum.photos/400/200?random=1',
    this.listImage = const [],
    this.isLiked = false,
    this.likeID = '',
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  TextEditingController _commentController = TextEditingController();

  Future<void> handleComment() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('customerId');
    final commentDetail = _commentController.text.trim();

    if (commentDetail.isEmpty) {
      _showSnackbar('Chưa nhập bình luận');
      return;
    } else if (commentDetail.length > 200) {
      _showSnackbar('Độ dài bình luận < 200 ký tự');
      return;
    }

    if (userID == null || userID.isEmpty) {
      _showSnackbar('Vui lòng đăng nhập để bình luận');
      return;
    }

    final comment = {
      "articleID": widget.id,
      "userID": userID,
      "commentDetail": commentDetail,
    };

    try {
      final response = await http.post(
        Uri.parse('https://dhkptsocial.onrender.com/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(comment),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Bình luận thành công');
        _commentController.clear();

        // Update numberOfComment
        final articlePost = {"numberOfComment": widget.numberOfComment + 1};
        await http.put(
          Uri.parse('https://dhkptsocial.onrender.com/articles/${widget.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(articlePost),
        );

        // Add notification
        final notification = {
          "user": widget.authorID,
          "actor": userID,
          "actionDetail": "đã bình luận bài viết của bạn",
          "article": widget.id,
          "comment": json.decode(response.body)["_id"]
        };
        await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(notification),
        );

        setState(() {});
      } else {
        _showSnackbar('Lỗi khi gửi bình luận');
      }
    } catch (e) {
      _showSnackbar('Lỗi kết nối mạng');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  Future<List<Comment>> fetchComments() async {
    try{
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/comments/${widget.id}')
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((comment) => Comment.fromJson(comment)).toList();
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      print(e);
      return [];
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      appBar: AppBar(
        title: Text('Bình luận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: colorBG,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          SizedBox(height: 20,),
          CardPost(
            id: widget.id,
            authorID: widget.authorID,
            author: widget.author,
            createdAt: widget.createdAt,
            content: widget.content,
            numberOfComment: widget.numberOfComment,
            numberOfLike: widget.numberOfLike,
            articleStatus: widget.articleStatus,
            avatar: widget.avatar,
            listImage: widget.listImage,
            isLiked: widget.isLiked,
            likeID: widget.likeID,
          ),
          SizedBox(height: 20,),
          Expanded(
            child: FutureBuilder<List<Comment>>(
            future: fetchComments(), 
            builder: (BuildContext context, AsyncSnapshot<List<Comment>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No comments available.'));
              } else {
              final comments = snapshot.data!;
              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                final comment = comments[index];
                return Column(
                  children: [
                  CommentItem(
                    comment: comment,
                    user: comment.userID,
                  ),
                  SizedBox(height: 10,),
                  ]
                );
                },
              );
              }
            },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
            children: [
              Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                hintText: 'Thêm bình luận...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
              ),
              SizedBox(width: 8),
              IconButton(
              icon: Icon(Icons.send, color: colorBG),
              onPressed: handleComment,
              ),
            ],
            ),
          ),
          ],
        ),
      ),
      ) 
    );
  }
}