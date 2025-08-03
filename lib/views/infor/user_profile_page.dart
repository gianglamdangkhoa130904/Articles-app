import 'dart:convert';
import 'package:final_project/views/login_page.dart';
import 'package:final_project/views/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_info_section.dart';
import 'user_post_grid.dart';
import 'edit_profile_page.dart';

class UserProfileCache {
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

class UserProfilePage extends StatefulWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> posts = [];
  bool loadingUser = true, loadingPosts = true;

  int followersCount = 0, followingsCount = 0;

  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadAll();
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

  Future<void> _loadAll() async {
    final cachedUser = UserProfileCache.getUser(widget.userId);
    final cachedPosts = UserProfileCache.getPosts(widget.userId);

    if (cachedUser != null) {
      user = cachedUser;
      followersCount = (cachedUser['followers'] as List).length;
      followingsCount = (cachedUser['followings'] as List).length;
      loadingUser = false;
    }

    if (cachedPosts != null) {
      posts = cachedPosts;
      loadingPosts = false;
    }

    if (cachedUser == null) await _fetchUser();
    if (cachedPosts == null) await _fetchPosts();
  }

  Future<void> _fetchUser() async {
    setState(() => loadingUser = true);
    try {
      final res = await http.get(Uri.parse('https://dhkptsocial.onrender.com/users/${widget.userId}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        UserProfileCache.setUser(widget.userId, data);
        user = data;
        followersCount = (data['followers'] as List).length;
        followingsCount = (data['followings'] as List).length;
      }
    } catch (e) { print('❌ fetchUser error: $e'); }
    finally { setState(() => loadingUser = false); }
  }

  void _handleLogout(BuildContext context) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customerId');
    await prefs.remove('cached_articles');
    await prefs.remove('cache_timestamp');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đăng xuất thành công'), backgroundColor: Colors.green,),
    );
  }

  Future<void> _fetchPosts() async {
  setState(() => loadingPosts = true);
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
      UserProfileCache.setPosts(widget.userId, posts);
    }
  } catch (e) {
    print('❌ fetchPosts error: $e');
  } finally {
    setState(() => loadingPosts = false);
  }
}


  Future<void> _refreshPosts() async {
    UserProfileCache.setPosts(widget.userId, []);
    posts.clear();
    await _fetchPosts();
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
        backgroundColor: const Color(0xFF7893FF),
        // leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: _showAppBarTitle
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 18, color: Colors.white)),
                Text('${posts.length} bài viết', style: const TextStyle(fontSize: 18,color: Colors.white)),
              ])
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 35, height: 4, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: avatar.isNotEmpty
                            ? NetworkImage('https://dhkptsocial.onrender.com/files/download/$avatar')
                            : null,
                        child: avatar.isEmpty ? const Icon(Icons.person, size: 36) : null,
                      ),
                      const SizedBox(height: 8),
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text("Chỉnh sửa hồ sơ"),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditProfilePage(userId: widget.userId)),
                          ).then((updated) {
                            if (updated == true) {
                              UserProfileCache.clear(widget.userId);
                              _loadAll();
                            }
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text("Cài đặt"),
                        onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingPage(),
                            ),
                          )
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserInfoSection(
                name: name,
                avatar: avatar,
                description: user!['description'] ?? '',
                followersCount: followersCount,
                followingsCount: followingsCount,
                postCount: posts.length,
                userId: widget.userId,
                onProfileUpdated: () {
                  UserProfileCache.clear(widget.userId);
                  _loadAll();
                },
              ),
              const Divider(),
              loadingPosts && posts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator())
                  : UserPostGrid(posts: posts, loggedInUserId: widget.userId),
            ],
          ),
        ),
      ),
    );
  }
}
