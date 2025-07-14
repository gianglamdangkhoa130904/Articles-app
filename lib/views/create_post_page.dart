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

      _showSnackbar('Đăng bài thành công');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildMediaPreview(XFile file) {
    if (file.mimeType?.startsWith('video') == true) {
      return VideoPreview(file: file);
    } else {
      return Image.file(File(file.path), height: 120, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(preferredSize: Size.fromHeight(60), 
        child: Container(
          padding: EdgeInsets.only(top: 10, bottom: 12, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black38, // Màu bóng
                blurRadius: 10,        // Độ mờ (càng lớn, càng mềm)
                spreadRadius: 5,       // Độ lan rộng của bóng
                offset: Offset(0, 1),  // Dịch chuyển bóng theo x,y
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _descriptionController,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: "Mô tả bài viết",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text("Chọn ảnh"),
                    onPressed: () => pickMedia(ImageSource.gallery, isVideo: false),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.videocam),
                    label: const Text("Chọn video"),
                    onPressed: () => pickMedia(ImageSource.gallery, isVideo: true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _mediaFiles.isEmpty
                    ? const Text("Chưa chọn ảnh hoặc video")
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mediaFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return buildMediaPreview(_mediaFiles[index]);
                        },
                      ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : const Icon(Icons.cloud_upload),
                label: const Text("Đăng bài"),
                onPressed: isLoading ? null : handleUpload,
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

  @override
  void initState() {
    _controller = VideoPlayerController.file(File(widget.file.path))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? SizedBox(
            width: 120,
            height: 120,
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          )
        : const CircularProgressIndicator();
  }
}
