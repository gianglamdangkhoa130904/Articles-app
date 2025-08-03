import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import trang cá nhân
import 'user_profile_page.dart';
import 'other_profile_page.dart';

class FollowListPage extends StatefulWidget {
  final String userId;
  final String loggedInUserId;
  final String initialTab;

  const FollowListPage({
    super.key,
    required this.userId,
    required this.loggedInUserId,
    this.initialTab = 'followers',
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? followData;
  Map<String, dynamic>? viewedUser;
  bool loading = true;
  bool loadingUser = true;
  int followersCount = 0;
  int followingsCount = 0;
  bool loadingFollow = false;
  String? currentFollowTarget;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'followings' ? 0 : 1,
    );
    fetchFollowData();
    fetchViewedUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchViewedUser() async {
    try {
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/users/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          viewedUser = data;
          loadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        loadingUser = false;
      });
      print('Error fetching user info: $e');
    }
  }

  Future<void> fetchFollowData() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://dhkptsocial.onrender.com/users/followdata/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          followData = data;
          followersCount = data['followers']?.length ?? 0;
          followingsCount = data['followings']?.length ?? 0;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      print('Error fetching follow data: $e');
    }
  }

  Future<void> toggleFollow(String targetUserId) async {
    if (loadingFollow) return;

    setState(() {
      loadingFollow = true;
      currentFollowTarget = targetUserId;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://dhkptsocial.onrender.com/users/follow/$targetUserId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'loggedInUserId': widget.loggedInUserId}),
      );

      if (response.statusCode == 200) {
        await fetchFollowData();
      } else {
        print("❌ Lỗi theo dõi. Status: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Lỗi follow/unfollow: $e');
    } finally {
      setState(() {
        loadingFollow = false;
        currentFollowTarget = null;
      });
    }
  }

  void handleProfileTap(String userId) {
    if (userId == widget.loggedInUserId) {
      print("➡️ Điều hướng đến trang cá nhân của chính mình (MyProfilePage)");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(userId: userId),
        ),
      );
    } else {
      print("➡️ Điều hướng đến trang cá nhân của người khác (OtherProfilePage)");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfilePage(
            userId: userId,
            loggedInUserId: widget.loggedInUserId,
          ),
        ),
      );
    }
  }

  Widget _buildUserList(List<dynamic> users) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = user['_id'] == widget.loggedInUserId;
        final isFollowing = (user['followers'] as List)
            .any((follower) => follower == widget.loggedInUserId);
        final isLoading = loadingFollow && currentFollowTarget == user['_id'];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => handleProfileTap(user['_id']),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: user['avatar'] != null && user['avatar'] != ''
                      ? NetworkImage(
                          'https://dhkptsocial.onrender.com/files/download/${user['avatar']}')
                      : null,
                  child: user['avatar'] == null || user['avatar'] == ''
                      ? const Icon(Icons.person, size: 24)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => handleProfileTap(user['_id']),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Không có tên',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '@${user['username'] ?? 'unknown'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isCurrentUser)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFollowing)
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.mail_outline, size: 20),
                          onPressed: () {
                            // xử lý nhắn tin
                          },
                        ),
                      ),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => toggleFollow(user['_id']),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 40),
                        backgroundColor:
                            isFollowing ? Colors.white : const Color(0xFF7893FF),
                        foregroundColor:
                            isFollowing ? Colors.black : Colors.white,
                        side: isFollowing
                            ? const BorderSide(color: Colors.grey)
                            : BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.grey),
                                ),
                              ),
                            )
                          : Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                    ),
                  ],
                )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Đang tải...';
    if (widget.userId == widget.loggedInUserId) {
      title = 'Hồ sơ của bạn';
    } else if (!loadingUser && viewedUser != null) {
      title = viewedUser!['name'] != null
          ? '${viewedUser!['name']}'
          : 'Hồ sơ cá nhân';
    }

    return Scaffold(
      appBar: AppBar(
  title: Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),
  ),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(34), // Chiều cao TabBar
    child: TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'Đang theo dõi: $followingsCount'),
        Tab(text: 'Người theo dõi: $followersCount'),
      ],
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.black,
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // chữ to
      unselectedLabelStyle: const TextStyle(fontSize: 15), // chữ thường
    ),
  ),
),

      body: TabBarView(
        controller: _tabController,
        children: [
          followData == null
              ? const Center(child: CircularProgressIndicator())
              : _buildUserList(followData!['followings']),
          followData == null
              ? const Center(child: CircularProgressIndicator())
              : _buildUserList(followData!['followers']),
        ],
      ),
    );
  }
}
