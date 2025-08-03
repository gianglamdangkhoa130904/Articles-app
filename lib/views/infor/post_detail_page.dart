import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:video_player/video_player.dart';
import 'video_player_widget.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final String loggedInUserId;
  const PostDetailPage({
    super.key,
    required this.post,
    required this.loggedInUserId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool get isMyPost => widget.post['userId'] == widget.loggedInUserId;

  bool loadingUser = true, loadingFollow = false;
  Map<String, dynamic>? user;
  bool isFollowed = false;
  int followersCount = 0;

  List<dynamic> comments = [];
  bool loadingComments = false;
  final commentController = TextEditingController();

  bool isLiked = false;
  String? likeId;

  @override
  void initState() {
    super.initState();
    fetchPostUser();
    fetchComments();
    checkIfLiked();
  }

  Future<void> fetchPostUser() async {
    setState(() => loadingUser = true);
    final id = widget.post['userId'];
    try {
      final res = await http.get(Uri.parse('https://dhkptsocial.onrender.com/users/$id'));
      if (res.statusCode == 200) {
        user = jsonDecode(res.body);
        followersCount = (user!['followers'] as List).length;
        isFollowed = (user!['followers'] as List)
            .any((f) => f['_id'] == widget.loggedInUserId);
      }
    } catch (e) {
      debugPrint('❌ fetchPostUser error: $e');
    } finally {
      setState(() => loadingUser = false);
    }
  }

  Future<void> fetchComments() async {
    setState(() => loadingComments = true);
    try {
      final res = await http.get(Uri.parse('https://dhkptsocial.onrender.com/comments/${widget.post['id']}'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        comments = json['data'] ?? [];
      }
    } catch (e) {
      debugPrint('❌ fetchComments error: $e');
    } finally {
      setState(() => loadingComments = false);
    }
  }

  Future<void> checkIfLiked() async {
    try {
      final res = await http.get(Uri.parse(
          'https://dhkptsocial.onrender.com/likes/${widget.loggedInUserId}/${widget.post['id']}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data != null) {
          isLiked = true;
          likeId = data['_id'];
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('❌ checkIfLiked error: $e');
    }
  }

  Future<void> toggleLike() async {
    try {
      if (isLiked && likeId != null) {
        final res = await http.delete(
            Uri.parse('https://dhkptsocial.onrender.com/likes/$likeId'));
        if (res.statusCode == 200) {
          setState(() {
            isLiked = false;
            likeId = null;
            widget.post['likes'] = (widget.post['likes'] ?? 1) - 1;
          });
        }
      } else {
        final res = await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/likes'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'articleID': widget.post['id'],
            'userID': widget.loggedInUserId,
          }),
        );
        if (res.statusCode == 201) {
          final data = jsonDecode(res.body);
          setState(() {
            isLiked = true;
            likeId = data['_id'];
            widget.post['likes'] = (widget.post['likes'] ?? 0) + 1;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ toggleLike error: $e');
    }
  }

  Future<void> addComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa nhập bình luận')),
      );
      return;
    }
    if (text.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Độ dài bình luận < 200 ký tự')),
      );
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('https://dhkptsocial.onrender.com/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'articleID': widget.post['id'],
          'userID': widget.loggedInUserId,
          'commentDetail': text,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final commentData = jsonDecode(res.body);

        final newCommentCount = (widget.post['comments'] ?? 0) + 1;
        await http.put(
          Uri.parse('https://dhkptsocial.onrender.com/articles/${widget.post['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'numberOfComment': newCommentCount}),
        );

        final notification = {
          'user': widget.post['userID'],
          'actor': widget.loggedInUserId,
          'actionDetail': 'đã bình luận bài viết của bạn',
          'article': widget.post['id'],
          'comment': commentData['_id'],
        };
        await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(notification),
        );

        commentController.clear();
        await fetchComments();

        setState(() {
          widget.post['comments'] = newCommentCount;
        });
      } else {
        debugPrint('❌ addComment failed: ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ addComment error: $e');
    }
  }

  void toggleFollow() async {
    try {
      final response = await http.put(
        Uri.parse('https://dhkptsocial.onrender.com/users/${widget.post['userId']}/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'loggedInUserId': widget.loggedInUserId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          isFollowed = !isFollowed;
        });
      } else {
        print('❌ Follow/unfollow failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in toggleFollow: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.post['files'] as List;
    final description = widget.post['description'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isMyPost ? 'Bài viết của bạn' : 'Bài viết'),
      ),
      body: loadingUser
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: CachedNetworkImageProvider(
                        'https://dhkptsocial.onrender.com/files/download/${user!['avatar']}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user!['name'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isMyPost)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowed ? Colors.grey[300] : Colors.blue,
                          foregroundColor: isFollowed ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: toggleFollow,
                        child: loadingFollow
                            ? const SizedBox(width: 20, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(isFollowed ? 'Đã theo dõi' : 'Theo dõi'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (files.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final type = file['type'], url = file['url'];
                        if (type == 'image') {
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                          );
                        } else if (type == 'video') {
                          return VideoPlayerWidget(videoUrl: url);
                        }
                        return const Center(child: Text("Không hỗ trợ định dạng này"));
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                Text(description, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 0),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : null),
                      onPressed: toggleLike,
                    ),
                    Text('${widget.post['likes'] ?? 0} lượt thích'),
                    const SizedBox(width: 24),
                    const Icon(Icons.comment_outlined),
                    const SizedBox(width: 8),
                    Text('${widget.post['comments'] ?? 0} bình luận'),
                  ],
                ),
                const SizedBox(height: 0),

                Text('Bình luận', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                for (final cmt in comments)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        'https://dhkptsocial.onrender.com/files/download/${cmt['userID']['avatar']}',
                      ),
                    ),
                    title: Text(cmt['userID']['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(cmt['commentDetail'] ?? ''),
                  ),

                const SizedBox(height: 8),

                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Thêm bình luận...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: addComment,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
    );
  }
}