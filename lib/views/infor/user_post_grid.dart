import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'post_detail_page.dart';

class UserPostGrid extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final String loggedInUserId;

  const UserPostGrid({
    super.key,
    required this.posts,
    required this.loggedInUserId,
  });

  @override
  State<UserPostGrid> createState() => _UserPostGridState();
}

class _UserPostGridState extends State<UserPostGrid> {
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeVideoControllers();
  }

  Future<void> _initializeVideoControllers() async {
    for (int i = 0; i < widget.posts.length; i++) {
      final files = widget.posts[i]['files'] as List<dynamic>;
      if (files.isNotEmpty && files[0]['type'] == 'video') {
        final controller = VideoPlayerController.network(files[0]['url']);
        await controller.initialize();
        controller.setLooping(false);
        controller.pause();
        _videoControllers[i] = controller;
        //setState(() {}); // refresh UI
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final post = widget.posts[index];
        final files = post['files'] as List<dynamic>;
        if (files.isEmpty) return const SizedBox();

        final firstFile = files[0];
        final fileType = firstFile['type'];
        final fileUrl = firstFile['url'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailPage(
                  post: post,
                  loggedInUserId: widget.loggedInUserId,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (fileType == 'image')
                CachedNetworkImage(
                  imageUrl: fileUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                )
              else if (_videoControllers.containsKey(index) &&
                  _videoControllers[index]!.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _videoControllers[index]!.value.size.width,
                    height: _videoControllers[index]!.value.size.height,
                    child: VideoPlayer(_videoControllers[index]!),
                  ),
                )
              else
                Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator())),
              if (fileType == 'video')
                const Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 24),
                ),
            ],
          ),
        );
      },
    );
  }
}
