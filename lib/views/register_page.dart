import 'package:final_project/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:final_project/default/default.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime? _selectedDate;
  File? _avatarFile;
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _repasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarFile = File(image.path);
      });
    }
  }

  bool _isOver18(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age >= 18;
  }

  bool _isValidPassword(String password) {
    final lengthCheck = password.length >= 9 && password.length <= 20;
    final upperCaseCheck = password.contains(RegExp(r'[A-Z]'));
    final lowerCaseCheck = password.contains(RegExp(r'[a-z]'));
    final numberCheck = password.contains(RegExp(r'[0-9]'));
    final specialCharCheck = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return lengthCheck && upperCaseCheck && lowerCaseCheck && numberCheck && specialCharCheck;
  }

  bool _isValidUsername(String username) {
    final lengthCheck = username.length >= 9 && username.length <= 20;
    final specialCharCheck = !username.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final numberCheck = !username.startsWith(RegExp(r'[0-9]'));
    
    return lengthCheck && specialCharCheck && numberCheck;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_avatarFile == null) {
      _showSnackBar('Vui lòng thêm ảnh đại diện', isError: true);
      return;
    }
    
    if (_selectedDate == null) {
      _showSnackBar('Thiếu ngày sinh', isError: true);
      return;
    }
    
    if (!_isOver18(_selectedDate!)) {
      _showSnackBar('Người dùng đăng ký phải có độ tuổi từ 18 tuổi trở lên', isError: true);
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Upload avatar first
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://dhkptsocial.onrender.com/files/upload/avatar'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('avatar', _avatarFile!.path),
      );
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var avatarResponse = json.decode(responseData);
      
      if (response.statusCode == 200) {
        // Register user
        var registerResponse = await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/users'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': _usernameController.text,
            'password': _passwordController.text,
            'name': _nameController.text,
            'dob': _selectedDate!.toIso8601String(),
            'email': _emailController.text,
            'avatar': avatarResponse['file']['_id'],
          }),
        );
        
        if (registerResponse.statusCode == 200) {
          _showSnackBar('Sign up successfully');
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          _showSnackBar('Registration failed', isError: true);
        }
      } else {
        _showSnackBar('Avatar upload failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e', isError: true);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorBG.withOpacity(0.1),
              Colors.pink.withOpacity(0.05),
              Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              children: [
                // Header
                SizedBox(height: 20),
                Text(
                  'Tham gia cùng chúng tôi',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorBG,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kết nối với bạn bè và thế giới xung quanh bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                // Form Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar Upload
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: _avatarFile == null
                                        ? LinearGradient(
                                            colors: [colorBG, colorBG],
                                          )
                                        : null,
                                    color: _avatarFile != null ? Colors.grey[200] : null,
                                  ),
                                  child: _avatarFile == null
                                      ? Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 32,
                                        )
                                      : ClipOval(
                                          child: Image.file(
                                            _avatarFile!,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tải lên ảnh đại diện của bạn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Họ và tên',
                          hint: 'Nhập vào họ và tên',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Thiếu tên người dùng';
                            }
                            if (value.length < 8 || value.length > 20) {
                              return 'Tên người dùng phải có độ dài từ 8 đến 20 ký tự';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Date of Birth
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(Duration(days: 365 * 20)),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null
                                      ? 'Chọn ngày sinh'
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: TextStyle(
                                    color: _selectedDate == null ? Colors.grey[500] : Colors.black,
                                  ),
                                ),
                                Icon(Icons.calendar_today, color: colorBG),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email cá nhân',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Thiếu email';
                            }
                            if (!_isValidEmail(value)) {
                              return 'Email sai định dạng';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Username Field
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Tên đăng nhập',
                          hint: 'Chọn tên đăng nhập',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Thiếu tên đăng nhập';
                            }
                            if (!_isValidUsername(value)) {
                              return 'Tên đăng nhập không có ký tự đặc biệt và có độ dài lớn hơn 8, bé hơn 20 ký tự';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          hint: 'Tạo mật khẩu',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Thiếu mật khẩu';
                            }
                            if (!_isValidPassword(value)) {
                              return 'Mật khẩu phải gồm chữ hoa, chữ thường, số, ký tự đặc biệt và có độ dài lớn hơn 8, bé hơn 20 ký tự';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Confirm Password Field
                        _buildTextField(
                          controller: _repasswordController,
                          label: 'Xác nhận mật khẩu',
                          hint: 'Nhập lại mật khẩu',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Thiếu xác nhận mật khẩu';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu nhập lại không trùng khớp';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),

                        // Register Button
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: colorBG,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: colorBG.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _loading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Tạo tài khoản mới',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Bạn đã có tài khoản? ',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginPage()),
                                );
                              },
                              child: Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  color: colorBG,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorBG, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.5),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
    );
  }
}