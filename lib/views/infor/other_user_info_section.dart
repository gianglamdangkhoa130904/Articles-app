import 'package:flutter/material.dart';
import 'follow_list_page.dart';

class OtherUserInfoSection extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isFollowed;
  final bool loadingFollow;
  final String loggedInUserId;
  final String userId;
  final VoidCallback onFollowToggle;
  final int followersCount;
  final int followingsCount;
  final int postCount;

  const OtherUserInfoSection({
    super.key,
    required this.user,
    required this.isFollowed,
    required this.loadingFollow,
    required this.loggedInUserId,
    required this.userId,
    required this.onFollowToggle,
    required this.followersCount,
    required this.followingsCount,
    required this.postCount,
  });

  String formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)} Tr';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(0)} N';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? '';
    final avatar = user['avatar'] ?? '';
    final description = user['description'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage('https://dhkptsocial.onrender.com/files/download/$avatar')
                    : null,
                child: avatar.isEmpty ? const Icon(Icons.person, size: 40) : null,
              ),
              const Spacer(),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: loadingFollow ? null : onFollowToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowed ? Colors.white : const Color(0xFF7893FF),
                    foregroundColor: isFollowed ? Colors.black : Colors.white,
                    side: BorderSide(color: isFollowed ? Colors.grey : Colors.transparent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Text(isFollowed ? "Đang theo dõi" : "Theo dõi", style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowListPage(
                      userId: userId,
                      loggedInUserId: loggedInUserId,
                      initialTab: 'followings',
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(formatNumber(followingsCount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 4),
                    const Text("Đang theo dõi", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowListPage(
                      userId: userId,
                      loggedInUserId: loggedInUserId,
                      initialTab: 'followers',
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(formatNumber(followersCount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 4),
                    const Text("Người theo dõi", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
