import 'package:final_project/default/default.dart';
import 'package:final_project/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
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
Widget _buildSettingItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Widget? trailing,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 1,
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorBG.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: colorBG,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
class _SettingPageState extends State<SettingPage> {
  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      // Thử launch với các mode khác nhau
      bool launched = false;
      
      // Thử external application trước
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      
      // Nếu không được, thử platform default
      if (!launched && await canLaunchUrl(uri)) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
      
      // Nếu vẫn không được, thử external non-browser
      if (!launched && await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
      
      if (!launched) {
        _showErrorDialog('Không thể mở liên kết: $url\nVui lòng kiểm tra lại URL hoặc cài đặt trình duyệt.');
      }
      
    } catch (e) {
      print('Error launching URL: $e');
      _showErrorDialog('Đã xảy ra lỗi khi mở liên kết\nLỗi: ${e.toString()}');
    }
  }

  // Hàm hiển thị dialog lỗi
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Cài đặt', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: colorBG,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              // Container(
              //   width: double.infinity,
              //   padding: EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(12),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.grey.withOpacity(0.1),
              //         spreadRadius: 1,
              //         blurRadius: 5,
              //         offset: Offset(0, 2),
              //       ),
              //     ],
              //   ),
              //   child: Row(
              //     children: [
              //       CircleAvatar(
              //         radius: 30,
              //         backgroundColor: Colors.grey.shade200,
              //         child: Icon(Icons.person, size: 35, color: Colors.grey),
              //       ),
              //       SizedBox(width: 16),
              //       Expanded(
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               'Tên người dùng',
              //               style: TextStyle(
              //                 fontSize: 18,
              //                 fontWeight: FontWeight.bold,
              //               ),
              //             ),
              //             SizedBox(height: 4),
              //             Text(
              //               'user@example.com',
              //               style: TextStyle(
              //                 fontSize: 14,
              //                 color: Colors.grey.shade600,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       Icon(Icons.edit, color: colorBG),
              //     ],
              //   ),
              // ),
              
              // SizedBox(height: 24),
              
              // Account Settings
              // Text(
              //   'Tài khoản',
              //   style: TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.grey.shade700,
              //   ),
              // ),
              // SizedBox(height: 12),
              
              // _buildSettingItem(
              //   icon: Icons.person_outline,
              //   title: 'Chỉnh sửa hồ sơ',
              //   subtitle: 'Thay đổi thông tin cá nhân',
              //   onTap: () {},
              // ),
              
              // _buildSettingItem(
              //   icon: Icons.lock_outline,
              //   title: 'Đổi mật khẩu',
              //   subtitle: 'Cập nhật mật khẩu của bạn',
              //   onTap: () {},
              // ),
              
              // _buildSettingItem(
              //   icon: Icons.privacy_tip_outlined,
              //   title: 'Quyền riêng tư',
              //   subtitle: 'Quản lý quyền riêng tư tài khoản',
              //   onTap: () {},
              // ),
              
              // SizedBox(height: 24),
              
              // App Settings
              Text(
                'Ứng dụng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              
              // _buildSettingItem(
              //   icon: Icons.notifications_outlined,
              //   title: 'Thông báo',
              //   subtitle: 'Cài đặt thông báo push',
              //   onTap: () {},
              //   trailing: Switch(
              //     value: true,
              //     onChanged: (value) {},
              //     activeColor: colorBG,
              //   ),
              // ),
              
              // _buildSettingItem(
              //   icon: Icons.dark_mode_outlined,
              //   title: 'Chế độ tối',
              //   subtitle: 'Bật/tắt giao diện tối',
              //   onTap: () {},
              //   trailing: Switch(
              //     value: false,
              //     onChanged: (value) {},
              //     activeColor: colorBG,
              //   ),
              // ),
              
              _buildSettingItem(
                icon: Icons.language_outlined,
                title: 'Ngôn ngữ',
                subtitle: 'Tiếng Việt',
                onTap: () {},
              ),
              
              _buildSettingItem(
                icon: Icons.storage_outlined,
                title: 'Dung lượng lưu trữ',
                subtitle: 'Quản lý bộ nhớ cache',
                onTap: () {},
              ),
              
              SizedBox(height: 24),
              
              // Support Section
              Text(
                'Hỗ trợ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              
              _buildSettingItem(
                icon: Icons.help_outline,
                title: 'Trợ giúp & FAQ',
                subtitle: 'Câu hỏi thường gặp',
                onTap: () {},
              ),
              
              _buildSettingItem(
                icon: Icons.feedback_outlined,
                title: 'Phản hồi',
                subtitle: 'Gửi ý kiến đóng góp',
                onTap: () {},
              ),

              _buildSettingItem(
                icon: Icons.policy_outlined,
                title: 'Chính sách bảo mật',
                subtitle: 'Điều khoản và chính sách',
                onTap: () {_launchURL('https://www.termsfeed.com/live/cfb3ff99-3d3d-4502-bc9a-2da96761b2b6');},
              ),
              
              _buildSettingItem(
                icon: Icons.gavel_outlined,
                title: 'Điều khoản sử dụng',
                subtitle: 'Quy định và điều kiện',
                onTap: () {},
              ),

              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'Về ứng dụng',
                subtitle: 'Phiên bản 1.0.0',
                onTap: () {},
              ),
              
              SizedBox(height: 32),
              
              // Logout Button
              Center(
                child: ElevatedButton(
                  onPressed: () => _handleLogout(context), 
                  child: Text(
                    'Đăng xuất', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}