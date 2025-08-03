import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'follow_list_page.dart';

class UserInfoSection extends StatelessWidget {
  final String name;
  final String avatar;
  final String description;
  final int followersCount;
  final int followingsCount;
  final int postCount;
  final String userId;

  final VoidCallback? onProfileUpdated;

  const UserInfoSection({
    super.key,
    required this.name,
    required this.avatar,
    required this.description,
    required this.followersCount,
    required this.followingsCount,
    required this.postCount,
    required this.userId,
    this.onProfileUpdated,
  });

  String formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)} Tr';
    if (num >= 10000) return '${num ~/ 1000} N';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 40,
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(
                        'https://dhkptsocial.onrender.com/files/download/$avatar')
                    : null,
                child:
                    avatar.isEmpty ? const Icon(Icons.person, size: 40) : null,
              ),
              const Spacer(),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfilePage(userId: userId)),
                  ).then((updated) {
                    if (updated == true) {
                      onProfileUpdated?.call(); // gọi callback từ cha
                    }
                  });
                },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFBEBEBE)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                  ),
                  child: const Text('Chỉnh sửa hồ sơ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FollowListPage(
                          userId: userId,
                          loggedInUserId: userId,
                          initialTab: 'followings')),
                ),
                child: Row(
                  children: [
                    Text(formatNumber(followingsCount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
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
                          loggedInUserId: userId,
                          initialTab: 'followers')),
                ),
                child: Row(
                  children: [
                    Text(formatNumber(followersCount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 4),
                    const Text("Người theo dõi",
                        style: TextStyle(fontSize: 16)),
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
