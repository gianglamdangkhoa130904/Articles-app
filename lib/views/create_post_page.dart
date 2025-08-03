import 'package:flutter/material.dart';
import 'package:final_project/default/default.dart';
import 'package:final_project/views/search_page.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:http_parser/http_parser.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {

  final TextEditingController _descriptionController = TextEditingController();
  final List<XFile> _mediaFiles = [];
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Hàm chọn nhiều ảnh/video cùng lúc
  Future<void> pickMultipleMedia() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn nhiều ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  pickMultipleImages();
                },
              ),
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Chọn 1 ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  pickMedia(ImageSource.gallery, isVideo: false);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text('Chọn video'),
                onTap: () {
                  Navigator.pop(context);
                  pickMedia(ImageSource.gallery, isVideo: true);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  pickMedia(ImageSource.camera, isVideo: false);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text('Quay video'),
                onTap: () {
                  Navigator.pop(context);
                  pickMedia(ImageSource.camera, isVideo: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Chọn nhiều ảnh cùng lúc
  Future<void> pickMultipleImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultipleMedia();
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _mediaFiles.addAll(pickedFiles);
      });
    }
  }

  Future<void> pickMedia(ImageSource source, {required bool isVideo}) async {
    final XFile? pickedFile = await (isVideo
        ? _picker.pickVideo(source: source)
        : _picker.pickImage(source: source));

    if (pickedFile != null) {
      setState(() {
        _mediaFiles.add(pickedFile);
      });
    }
  }

  // Xóa media đã chọn
  void removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
  }

  Future<void> handleUpload() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('customerId');

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      _showSnackbar('Vui lòng nhập mô tả bài đăng');
      return;
    }

    if (description.length > 200) {
      _showSnackbar('Mô tả không được quá 200 ký tự');
      return;
    }

    if (_mediaFiles.isEmpty) {
      _showSnackbar('Vui lòng chọn ảnh hoặc video');
      return;
    }

    setState(() => isLoading = true);

    final postData = {
      "descriptionPost": description,
      "user": user!,
    };

    try {
      final postResponse = await Dio().post(
        'https://dhkptsocial.onrender.com/articles',
        data: jsonEncode(postData),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final postId = postResponse.data['_id'];

      for (int i = 0; i < _mediaFiles.length; i++) {
        final file = File(_mediaFiles[i].path);
        final mimeType = _mediaFiles[i].mimeType ?? 'application/octet-stream';
        final parts = mimeType.split('/');

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            contentType: MediaType(parts[0], parts[1]),
            filename: file.path.split('/').last,
          ),
          'postId': postId,
        });

        await Dio().post(
          'https://dhkptsocial.onrender.com/files/upload',
          data: formData,
          options: Options(headers: {
            'Content-Type': 'multipart/form-data',
          }),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng bài thành công'), backgroundColor: Colors.green,));
      _descriptionController.clear();
      setState(() => _mediaFiles.clear());
    } catch (e) {
      print('Lỗi: $e');
      _showSnackbar('Đăng bài thất bại');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red,));
  }

  Widget buildMediaPreview(XFile file, int index) {
    // Kiểm tra loại file an toàn hơn
    bool isVideo = _isVideoFile(file);
    
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isVideo
                ? VideoPreview(file: file)
                : _buildImagePreview(file),
          ),
        ),
        // Nút xóa
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => removeMedia(index),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        // Hiển thị icon video nếu là video
        if (isVideo)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Hàm kiểm tra xem file có phải video không
  bool _isVideoFile(XFile file) {
    // Kiểm tra extension
    final extension = file.path.toLowerCase().split('.').last;
    final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm', 'flv'];
    
    // Kiểm tra MIME type nếu có
    final mimeType = file.mimeType?.toLowerCase() ?? '';
    
    return videoExtensions.contains(extension) || mimeType.startsWith('video/');
  }

  // Hàm hiển thị ảnh với error handling
  Widget _buildImagePreview(XFile file) {
    return Image.file(
      File(file.path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        return Container(
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                'Lỗi tải ảnh',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: PreferredSize(preferredSize: Size.fromHeight(60), 
        child: Container(
          padding: EdgeInsets.only(top: 10, bottom: 12, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                spreadRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/logo.png'),
              IconButton(
                onPressed: () => {Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPage()),
                )}, 
                icon: Icon(Icons.search_sharp, color: colorBG, size: 25,))
            ],
          ),
          )
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
          child: Column(
            children: [
              Text('Đăng bài', style: TextStyle(color: colorBG, fontSize: 26, fontWeight: FontWeight.bold),),
              SizedBox(height: 16,),
              TextField(
                controller: _descriptionController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Mô tả bài viết",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              
              // Nút chọn media duy nhất
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text("Thêm ảnh/video"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorBG,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: pickMultipleMedia,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hiển thị số lượng media đã chọn
              if (_mediaFiles.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Đã chọn ${_mediaFiles.length} file',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Preview media files
              Expanded(
                child: _mediaFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Chưa chọn ảnh hoặc video",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _mediaFiles.length,
                        itemBuilder: (context, index) {
                          return buildMediaPreview(_mediaFiles[index], index);
                        },
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Nút đăng bài
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, 
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(isLoading ? "Đang đăng..." : "Đăng tải"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorBG,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading ? null : handleUpload,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPreview extends StatefulWidget {
  final XFile file;

  const VideoPreview({super.key, required this.file});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    _controller = VideoPlayerController.file(File(widget.file.path))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
            onTap: _togglePlayPause,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                // Overlay play/pause button
                if (!_isPlaying)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                // Video duration overlay
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(_controller.value.duration),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 8),
                Text(
                  'Đang tải...',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}