import 'package:final_project/components/card_post.dart';
import 'package:final_project/components/comment_item.dart';
import 'package:final_project/components/post.dart';
import 'package:final_project/default/default.dart';
import 'package:final_project/models/comment_model.dart';
import 'package:final_project/views/search_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  List<Comment> _commentList = [];
  bool _isLoadingComments = true;

  // Hàm validate input
  String? _validateComment(String comment) {
    if (comment.isEmpty) {
      return 'Chưa nhập bình luận';
    }
    
    if (comment.length > 200) {
      return 'Độ dài bình luận < 200 ký tự';
    }
    
    return null;
  }

  Future<void> _fetchComments() async {
    try {

      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/comments/${widget.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Comment> comments = [];
        
        // Parse response data thành Comment objects
        if (data['data'] != null) {
          for (var commentData in data['data']) {
            comments.add(Comment.fromJson(commentData));
          }
        }
        
        setState(() {
          _commentList = comments;
           _isLoadingComments = false;
        });
      } else {
        _showSnackBar('Không thể tải bình luận', Colors.red);
      }
    } catch (error) {
      print('Error fetching comments: $error');
      _showSnackBar('Có lỗi xảy ra khi tải bình luận', Colors.red);
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }


  // Hàm xử lý gửi bình luận
  Future<void> _handleComment() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('customerId');
    String comment = _commentController.text.trim();
    
    // Validate input
    String? validationError = _validateComment(comment);
    if (validationError != null) {
      _showSnackBar(validationError, Colors.orange);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Dữ liệu bình luận
      Map<String, dynamic> dataComment = {
        'articleID': widget.id,
        'userID': userID, // Thay thế bằng userID thực tế
        'commentDetail': comment,
      };

      // Gửi bình luận
      final commentResponse = await http.post(
        Uri.parse('https://dhkptsocial.onrender.com/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dataComment),
      );

      if (commentResponse.statusCode == 200 || commentResponse.statusCode == 201) {
        final commentData = json.decode(commentResponse.body);
        
        // Cập nhật số lượng bình luận
        Map<String, dynamic> articlePost = {
          'numberOfComment': widget.numberOfComment + 1
        };

        await http.put(
          Uri.parse('https://dhkptsocial.onrender.com/articles/${widget.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(articlePost),
        );

        // Tạo thông báo
        Map<String, dynamic> notification = {
          'user': widget.authorID,
          'actor': userID, // Thay thế bằng userID thực tế
          'actionDetail': 'đã bình luận bài viết của bạn',
          'article': widget.id,
          'comment': commentData['_id'],
        };

        await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(notification),
        );

        _showSnackBar('Bình luận thành công', Colors.green);
        _commentController.clear();
        
        // Có thể gọi callback để refresh dữ liệu
        // fetchPost();
        _fetchComments();
        
      } else {
        _showSnackBar('Có lỗi xảy ra khi gửi bình luận', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Có lỗi xảy ra: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchComments();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
        body: Column(
          children: [
            // Phần nội dung cuộn được
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
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
                    SizedBox(height: 20),
                    
                    // Danh sách bình luận
                    _isLoadingComments 
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: colorBG),
                            ),
                          )
                        : _commentList.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Chưa có bình luận nào',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: _commentList.length,
                                itemBuilder: (context, index) {
                                  final comment = _commentList[index];
                                  return Column(
                                    children: [
                                      CommentItem(
                                        userID: comment.userID.id,
                                        comment: comment,
                                        userName: comment.userID.name,
                                        userAvatar: comment.userID.avatar!,
                                      ),
                                      SizedBox(height: 20,)
                                    ],
                                  );
                                },
                              ),
                    SizedBox(height: 100), // Padding để tránh bị che bởi input box
                  ],
                ),
              ),
            ),
            
            // Ô nhập bình luận cố định ở dưới
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: colorBG, // màu bóng
                    spreadRadius: 1, // độ lan rộng
                    blurRadius: 8, // độ mờ
                    offset: Offset(0, -4), // vị trí: x, y
                  ),
                ],
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Ô nhập text
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                            color: colorBG, // màu bóng
                            spreadRadius: 1, // độ lan rộng
                            blurRadius: 8, // độ mờ
                            offset: Offset(1, 2), // vị trí: x, y
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _commentController,
                        maxLines: null,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: 'Nhập bình luận...',
                          border: InputBorder.none,
                          counterText: '', // Ẩn counter text
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  // Nút gửi
                  GestureDetector(
                    onTap: _isSubmitting ? null : _handleComment,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isSubmitting ? colorBG : Colors.white,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                            color: colorBG, // màu bóng
                            spreadRadius: 1, // độ lan rộng
                            blurRadius: 8, // độ mờ
                            offset: Offset(1, 2), // vị trí: x, y
                          ),
                        ],
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: _isSubmitting ? Colors.white : colorBG,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}