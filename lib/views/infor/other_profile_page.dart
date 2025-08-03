import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'follow_list_page.dart';
import 'user_post_grid.dart';
import 'other_user_info_section.dart';

class OtherUserCache {
  static final Map<String, Map<String, dynamic>> _userData = {};
  static final Map<String, List<Map<String, dynamic>>> _postsData = {};

  static Map<String, dynamic>? getUser(String id) => _userData[id];
  static void setUser(String id, Map<String, dynamic> user) => _userData[id] = user;

  static List<Map<String, dynamic>>? getPosts(String id) => _postsData[id];
  static void setPosts(String id, List<Map<String, dynamic>> posts) => _postsData[id] = posts;
  static void clear(String id) {
    _userData.remove(id);
    _postsData.remove(id);
  }
}

class OtherProfilePage extends StatefulWidget {
  final String userId;
  final String loggedInUserId;
  const OtherProfilePage({
    super.key,
    required this.userId,
    required this.loggedInUserId,
  });

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> posts = [];
  bool loadingUser = true, loadingPosts = true;
  bool isFollowed = false, loadingFollow = false;
  int followersCount = 0, followingsCount = 0;

  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _refreshAll();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 100 && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }
  }

  Future<void> _refreshAll() async {
    OtherUserCache.clear(widget.userId);
    await fetchUser();
    await _fetchPosts();
  }

  Future<void> fetchUser() async {
    setState(() => loadingUser = true);

    final cached = OtherUserCache.getUser(widget.userId);
    if (cached != null) {
      setState(() {
        user = cached;
        _applyCounts(cached);
        loadingUser = false;
      });
      return;
    }

    try {
      final res = await http.get(Uri.parse('https://dhkptsocial.onrender.com/users/${widget.userId}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        OtherUserCache.setUser(widget.userId, data);
        setState(() {
          user = data;
          _applyCounts(data);
        });
      }
    } catch (e) {
      debugPrint('❌ fetchUser error: $e');
    } finally {
      setState(() => loadingUser = false);
    }
  }

  void _applyCounts(Map<String, dynamic> u) {
    followersCount = (u['followers'] as List).length;
    followingsCount = (u['followings'] as List).length;
    isFollowed = (u['followers'] as List).any((f) => f['_id'] == widget.loggedInUserId);
  }

  Future<void> _fetchPosts() async {
    setState(() {
      loadingPosts = true;
      posts.clear();
    });

    try {
      final resp = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/articles/${widget.userId}')
      );

      if (resp.statusCode == 200) {
        final dataList = jsonDecode(resp.body)['data'] as List;
        final List<Map<String, dynamic>> temp = [];

        for (var p in dataList) {
          List<Map<String, dynamic>> files = [];
          final fileRes = await http.get(
            Uri.parse('https://dhkptsocial.onrender.com/files/${p['_id']}')
          );

          if (fileRes.statusCode == 200) {
            final list = jsonDecode(fileRes.body) as List;
            for (final file in list) {
              final fileId = file['_id'];
              final filename = file['filename'].toString().toLowerCase();
              String fileType = 'image';

              if (filename.endsWith('.mp4') || filename.endsWith('.mov') || filename.endsWith('.avi')) {
                fileType = 'video';
              }

              files.add({
                'id': fileId,
                'type': fileType,
                'url': 'https://dhkptsocial.onrender.com/files/download/$fileId',
              });
            }
          }

          temp.add({
            'id': p['_id'],
            'likes': p['numberOfLike'],
            'comments': p['numberOfComment'],
            'files': files,
            'description': p['description'],
            'userId' : p['userID']
          });
        }

        posts = temp;
        OtherUserCache.setPosts(widget.userId, posts);
      }
    } catch (e) {
      debugPrint('❌ fetchPosts error: $e');
    } finally {
      setState(() => loadingPosts = false);
    }
  }

  Future<void> toggleFollow() async {
    if (loadingFollow) return;
    setState(() => loadingFollow = true);

    try {
      final res = await http.post(
        Uri.parse('https://dhkptsocial.onrender.com/users/follow/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'loggedInUserId': widget.loggedInUserId}),
      );
      if (res.statusCode == 200) {
        setState(() {
          isFollowed = !isFollowed;
          followersCount += isFollowed ? 1 : -1;
        });
      }
    } catch (e) {
      debugPrint('❌ toggleFollow error: $e');
    } finally {
      setState(() => loadingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingUser || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = user!['name'] ?? '';
    final avatar = user!['avatar'] ?? '';

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF7893FF),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: _showAppBarTitle
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 20, color: Colors.white)),
                      Text('${posts.length} bài viết', style: const TextStyle(color: Colors.white70)),
                    ]),
                  ),
                  ElevatedButton(
                    onPressed: toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowed ? Colors.grey[300] : Colors.white,
                      foregroundColor: isFollowed ? Colors.black : Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    ),
                    child: loadingFollow
                        ? const SizedBox(width: 20, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isFollowed ? 'Đã theo dõi' : 'Theo dõi'),
                  )
                ],
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              OtherUserInfoSection(
                user: user!,
                isFollowed: isFollowed,
                loadingFollow: loadingFollow,
                loggedInUserId: widget.loggedInUserId,
                userId: widget.userId,
                onFollowToggle: toggleFollow,
                followersCount: followersCount,
                followingsCount: followingsCount,
                postCount: posts.length,
              ),
              const Divider(),
              loadingPosts && posts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator())
                  : UserPostGrid(posts: posts, loggedInUserId: widget.loggedInUserId),
            ],
          ),
        ),
      ),
    );
  }
}
