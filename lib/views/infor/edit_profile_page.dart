import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class EditProfilePage extends StatefulWidget {
  final String userId;

  const EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();

  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final bioFocus = FocusNode();
  final addressFocus = FocusNode();
  final phoneFocus = FocusNode();

  String avatar = '';
  bool loading = true;

  Map<String, String> originalValues = {};
  Map<String, String?> errors = {};
  Map<String, bool> touched = {};

  @override
  void initState() {
    super.initState();
    fetchUserInfo();

    [nameFocus, emailFocus, bioFocus, addressFocus, phoneFocus].asMap().forEach((_, node) {
      node.addListener(() {
        if (!node.hasFocus) validateFields();
      });
    });
  }

  Future<void> fetchUserInfo() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse('https://dhkptsocial.onrender.com/users/${widget.userId}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        bioController.text = data['description'] ?? '';
        addressController.text = data['address'] ?? '';
        phoneController.text = data['phone'] ?? '';
        avatar = data['avatar'] ?? '';

        originalValues = {
          'name': nameController.text,
          'email': emailController.text,
          'bio': bioController.text,
          'address': addressController.text,
          'phone': phoneController.text,
          'avatar': avatar,
        };

        touched = {
          'name': false,
          'email': false,
          'bio': false,
          'address': false,
          'phone': false,
        };

        validateFields();
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi tải dữ liệu: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  bool validateFields() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    setState(() {
      errors['name'] = name.isEmpty ? 'Tên không được để trống' : null;
      errors['email'] = !RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) ? 'Email không hợp lệ' : null;
      errors['phone'] = phone.isNotEmpty && !RegExp(r'^\d{10,11}$').hasMatch(phone) ? 'SĐT không hợp lệ' : null;
    });

    return errors.values.every((e) => e == null);
  }

  bool isChanged() {
    return nameController.text.trim() != originalValues['name'] ||
        emailController.text.trim() != originalValues['email'] ||
        bioController.text.trim() != originalValues['bio'] ||
        addressController.text.trim() != originalValues['address'] ||
        phoneController.text.trim() != originalValues['phone'] ||
        avatar != (originalValues['avatar'] ?? '');
  }

  bool get canSubmit => isChanged() && validateFields();

  Future<void> submitUpdate() async {
    try {
      final url = Uri.parse('https://dhkptsocial.onrender.com/users/edit/${widget.userId}');
      final body = jsonEncode({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'description': bioController.text.trim(),
        'address': addressController.text.trim(),
        'phone': phoneController.text.trim(),
        'avatar': avatar,
      });

      final res = await http.put(url, headers: {'Content-Type': 'application/json'}, body: body);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cập nhật thành công')));
        Navigator.pop(context, true); // Trả về cho trang trước biết đã update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Cập nhật thất bại')));
      }
    } catch (e) {
      debugPrint('❌ $e');
    }
  }

  void openAvatarModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => AvatarChangeModal(
        userId: widget.userId,
        currentAvatar: avatar,
        onAvatarChange: (newAvatar) => setState(() => avatar = newAvatar),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    bioController.dispose();
    addressController.dispose();
    phoneController.dispose();

    nameFocus.dispose();
    emailFocus.dispose();
    bioFocus.dispose();
    addressFocus.dispose();
    phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: avatar.isNotEmpty
                              ? NetworkImage('https://dhkptsocial.onrender.com/files/download/$avatar')
                              : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
                        ),
                        TextButton(
                          onPressed: openAvatarModal,
                          child: const Text('Đổi ảnh đại diện', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildTextField('Tên', nameController, 'name', focusNode: nameFocus),
                  buildTextField('Email', emailController, 'email', focusNode: emailFocus),
                  buildTextField('Tiểu sử (tuỳ chọn)', bioController, 'bio', multiline: true, focusNode: bioFocus),
                  buildTextField('Địa chỉ (tuỳ chọn)', addressController, 'address', focusNode: addressFocus),
                  buildTextField('SĐT (tuỳ chọn)', phoneController, 'phone', focusNode: phoneFocus),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: canSubmit ? submitUpdate : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canSubmit ? const Color(0xFF7893FF) : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Lưu thay đổi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, String key,
      {bool multiline = false, FocusNode? focusNode}) {
    final error = errors[key];
    final isTouched = touched[key] ?? false;
    final isValid = error == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: (_) {
          setState(() {
            touched[key] = true;
            validateFields();
          });
        },
        maxLines: multiline ? null : 1,
        minLines: multiline ? 3 : 1,
        keyboardType: key == 'phone' ? TextInputType.phone : (multiline ? TextInputType.multiline : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          errorText: isTouched && error != null ? error : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: isTouched && isValid ? Colors.green : Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: isTouched && isValid ? Colors.green : Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class AvatarChangeModal extends StatefulWidget {
  final String userId;
  final String currentAvatar;
  final Function(String) onAvatarChange;

  const AvatarChangeModal({
    super.key,
    required this.userId,
    required this.currentAvatar,
    required this.onAvatarChange,
  });

  @override
  State<AvatarChangeModal> createState() => _AvatarChangeModalState();
}

class _AvatarChangeModalState extends State<AvatarChangeModal> {
  final ImagePicker _picker = ImagePicker();
  String? _error;
  bool _isUploading = false;

  Future<void> _pickImage() async {
  try {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final File file = File(image.path);
    final ext = path.extension(image.path).toLowerCase();

    if (!['.jpg', '.jpeg', '.png', '.gif'].contains(ext)) {
      setState(() {
        _error = 'Vui lòng chọn file ảnh hợp lệ';
        _isUploading = false;
      });
      return;
    }

    setState(() {
      _error = null;
      _isUploading = true;
    });

    final uploadReq = http.MultipartRequest(
      'POST',
      Uri.parse('https://dhkptsocial.onrender.com/files/upload/avatar'),
    );

    uploadReq.files.add(
      await http.MultipartFile.fromPath('avatar', file.path),
    );

    final uploadRes = await uploadReq.send();
    final body = await uploadRes.stream.bytesToString();
    final data = jsonDecode(body);

    if (uploadRes.statusCode == 200) {
      final fileId = data['file']['_id'];
      widget.onAvatarChange(fileId);
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = 'Lỗi khi tải ảnh lên: ${data['message'] ?? 'Không rõ lỗi'}';
        _isUploading = false;
      });
    }
  } catch (e) {
    setState(() {
      _error = 'Đã xảy ra lỗi: ${e.toString()}';
      _isUploading = false;
    });
    debugPrint('❌ Upload error: $e');
  }
}


  Future<void> _removeAvatar() async {
  setState(() => _isUploading = true);

  try {
    final res = await http.put(
      Uri.parse('https://dhkptsocial.onrender.com/users/edit/${widget.userId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'avatar': ''}),
    );

    if (res.statusCode == 200) {
      widget.onAvatarChange('');
      Navigator.pop(context);
    } else {
      setState(() {
        _error = 'Không thể xoá avatar';
        _isUploading = false;
      });
    }
  } catch (e) {
    setState(() {
      _error = 'Lỗi: ${e.toString()}';
      _isUploading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_isUploading)
            const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
          else ...[
            ListTile(leading: const Icon(Icons.photo), title: const Text('Chọn ảnh'), onTap: _pickImage),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xoá avatar', style: TextStyle(color: Colors.red)),
              onTap: _removeAvatar,
            ),
          ],
        ],
      ),
    );
  }
}
