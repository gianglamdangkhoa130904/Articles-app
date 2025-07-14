import 'package:final_project/components/card_post.dart';
import 'package:final_project/components/post.dart';
import 'package:final_project/default/default.dart';
import 'package:flutter/material.dart';

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
          ],
        ),
      ) 
    );
  }
}