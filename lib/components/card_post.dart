import 'dart:typed_data';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:final_project/components/post.dart';
import 'package:final_project/views/comment_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:final_project/default/default.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/article_model.dart' as article_model;

class CardPost extends StatefulWidget {
  final String id;
  final String content;
  final String authorID;
  final String author;
  final String avatar;
  final String createdAt;
  final String articleStatus;
  final int numberOfComment;
  final int numberOfLike;
  final List<ImageFile> listImage;
  final bool isLiked;
  final String likeID;
  
  const CardPost({
    super.key,
    this.id = "123",
    this.content = "mô tả bài viết",
    this.authorID = '',
    this.author = "Tác giả",
    this.createdAt = "13/09/2004",
    this.articleStatus = "active",
    this.numberOfComment = 123,
    this.numberOfLike = 123,
    this.avatar = 'https://picsum.photos/400/200?random=1',
    this.listImage = const [],
    this.isLiked = false,
    this.likeID = '',
  });

  @override
  State<CardPost> createState() => _CardPostState();
}

class _CardPostState extends State<CardPost> {
  bool isLiked = false;
  String likeIDState ='';
  bool isFollowing = false;
  int currentLikes = 0;
  int currentImageIndex = 0;
  String name = "";
  String handle = "";
  String avatar = '';
  bool istoglingLike = false;
  
  // Mock data for images
  List<ImageFile> imageUrls = [
    ImageFile(fileName: 'https://picsum.photos/400/200?random=1', fileID: 'random1'),
    ImageFile(fileName: 'https://picsum.photos/400/200?random=2', fileID: 'random2'),
    ImageFile(fileName: 'https://picsum.photos/400/200?random=3', fileID: 'random3'),
  ];

  @override
  void initState() {
    super.initState();
    name = widget.author;
    handle = "@" + widget.author;
    avatar = widget.avatar;
    imageUrls = widget.listImage;
    isLiked = widget.isLiked;
    currentLikes = widget.numberOfLike;
    likeIDState = widget.likeID;
    // Load saved state from cache
    _loadSavedState();
  }

  // Load saved like state from cache
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_articles';
    final cachedData = prefs.getStringList(cacheKey);

    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        List<FullArticle> cachedArticles = cachedData
            .map((e) => FullArticle.fromJson(json.decode(e)))
            .toList();

        // Tìm bài viết có id trùng với widget.id
        final currentArticle = cachedArticles.firstWhere(
          (article) => article.article.id == widget.id,
          orElse: () => FullArticle(
            article: article_model.Article(
              id: widget.id,
              numberOfLike: widget.numberOfLike,
              content: widget.content,
              numberOfComment: widget.numberOfComment,
              author: widget.authorID,
              createdAt: widget.createdAt,
              articleStatus: widget.articleStatus
              // Add other required fields
            ),
            authorID: widget.authorID,
            authorName: widget.author,
            avatar: widget.avatar,
            listImage: widget.listImage,
            isLiked: widget.isLiked,
            likeID: widget.likeID,
          ),
        );

        // Cập nhật state từ cache
        if (mounted) {
          setState(() {
            isLiked = currentArticle.isLiked;
            currentLikes = currentArticle.article.numberOfLike;
            likeIDState = currentArticle.likeID;
          });
        }
      } catch (e) {
        print('Lỗi khi load cached state: $e');
      }
    }
  }

  // Update cache after like/unlike
  Future<void> _updateCache(bool newIsLiked, int newLikeCount, String newLikeID) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_articles';
    final cachedData = prefs.getStringList(cacheKey);

    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        List<FullArticle> cachedArticles = cachedData
            .map((e) => FullArticle.fromJson(json.decode(e)))
            .toList();

        // Cập nhật bài viết có id trùng với widget.id
        final updatedArticles = cachedArticles.map((article) {
          if (article.article.id == widget.id) {
            final updatedArticle = article.article.copyWith(
              numberOfLike: newLikeCount,
            );
            return FullArticle(
              article: updatedArticle,
              authorID: article.authorID,
              authorName: article.authorName,
              avatar: article.avatar,
              listImage: article.listImage,
              isLiked: newIsLiked,
              likeID: newLikeID,
            );
          }
          return article;
        }).toList();

        // Ghi lại cache sau khi update
        final updatedData = updatedArticles
            .map((e) => json.encode(e.toJson()))
            .toList();

        await prefs.setStringList(cacheKey, updatedData);
        print('Cache updated successfully');
      } catch (e) {
        print('Lỗi khi update cache: $e');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  String _getTimeAgo(String dateString) {
    List<String> parts = dateString.split('-');
    DateTime date = DateTime(
      int.parse(parts[0]), // year
      int.parse(parts[1]), // month  
      int.parse(parts[2].substring(0,1)), // day
    );
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tuần trước';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else {
      return '${(difference.inDays / 365).floor()} năm trước';
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      istoglingLike = true;
    });

    if (isLiked) {
      // Thực hiện unlike
      try {
        final prefs = await SharedPreferences.getInstance();
        final customerId = prefs.getString('customerId'); 
        
        // Cập nhật UI trước
        setState(() {
          isLiked = false;
          currentLikes -= 1;
        });
        
        // Xóa like từ server
        final dislikeResponse = await http.delete(
          Uri.parse('https://dhkptsocial.onrender.com/likes/${likeIDState}'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (dislikeResponse.statusCode == 200) {
          // Cập nhật số lượt like trong bài post
          final articleUpdateResponse = await http.put(
            Uri.parse('https://dhkptsocial.onrender.com/articles/${widget.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'numberOfLike': currentLikes}),
          );
          
          // Xóa thông báo
          try {
            final notificationData = {
              'user': widget.authorID,
              'actor': customerId,
              'like': likeIDState
            };
            
            await http.delete(
              Uri.parse('https://dhkptsocial.onrender.com/notifications'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(notificationData),
            );
          } catch (notificationError) {
            print('Error deleting notification: $notificationError');
          }
          
          // Cập nhật cache
          await _updateCache(false, currentLikes, '');
          
          setState(() {
            likeIDState = '';
            istoglingLike = false;
          });
          
          print('Unlike thành công');
        } else {
          // Rollback UI nếu API thất bại
          setState(() {
            isLiked = true;
            currentLikes += 1;
            istoglingLike = false;
          });
          print('Failed to unlike post: ${dislikeResponse.statusCode}');
        }
      } catch (e) {
        // Rollback UI nếu có lỗi
        setState(() {
          isLiked = true;
          currentLikes += 1;
          istoglingLike = false;
        });
        print('Lỗi unlike: $e');
      }
    } else {
      // Thực hiện like
      try {
        final prefs = await SharedPreferences.getInstance();
        final customerId = prefs.getString('customerId');
        
        // Cập nhật UI trước
        setState(() {
          isLiked = true;
          currentLikes += 1;
        });
        
        final likeResponse = await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/likes'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'articleID': widget.id,
            'userID': customerId,
          }),
        );
        
        if (likeResponse.statusCode == 200 || likeResponse.statusCode == 201) {
          final likeData = jsonDecode(likeResponse.body);
          final likeID = likeData['_id'];
          
          // Cập nhật số lượt like trong bài post
          await http.put(
            Uri.parse('https://dhkptsocial.onrender.com/articles/${widget.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'numberOfLike': currentLikes}),
          );

          // Gửi thông báo
          final notification = {
            'user': widget.authorID,
            'actor': customerId,
            'actionDetail': 'đã thích bài viết của bạn',
            'article': widget.id,
            'like': likeID,
          };
          
          await http.post(
            Uri.parse('https://dhkptsocial.onrender.com/notifications'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(notification),
          );
          
          // Cập nhật cache
          await _updateCache(true, currentLikes, likeID);
          
          setState(() {
            likeIDState = likeID;
            istoglingLike = false;
          });
          
          print('Like thành công: ${likeID}');
        } else {
          // Rollback UI nếu API thất bại
          setState(() {
            isLiked = false;
            currentLikes -= 1;
            istoglingLike = false;
          });
          print('Failed to like post: ${likeResponse.statusCode}');
        }
      } catch (e) {
        // Rollback UI nếu có lỗi
        setState(() {
          isLiked = false;
          currentLikes -= 1;
          istoglingLike = false;
        });
        print('Lỗi like: $e');
      }
    }
  }

  void _toggleFollow() {
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  void _previousImage() {
    setState(() {
      currentImageIndex = currentImageIndex > 0 
          ? currentImageIndex - 1 
          : imageUrls.length - 1;
    });
  }

  void _nextImage() {
    setState(() {
      currentImageIndex = (currentImageIndex + 1) % imageUrls.length;
    });
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Báo cáo bài viết'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Chặn người dùng'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List?> fetchImageBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return base64Decode(data);
    } else {
      return null;
    }
  }

  Future<List<Uint8List?>> fetchAllImages(List<String> urls) async {
    return Future.wait(urls.map((url) => fetchImageBytes(url)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile info, follow button and more options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with gradient border
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colorBG, Colors.purple.shade300],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: Image.network(
                          avatar,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Username and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTimeAgo(widget.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // More options
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Image content with navigation arrows
          if (imageUrls.isNotEmpty)
            CarouselSlider(
              options: CarouselOptions(
                autoPlay: false,
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                enableInfiniteScroll: imageUrls.length > 1,
                height: 400
              ),
              items: imageUrls.map((file) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: file.fileName.contains('.mp4') 
                      ? VideoPlayerWidget(
                          videoUrl: file.fileID,
                        )
                      : CachedNetworkImage(
                          imageUrl: file.fileID,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(color: colorBG, strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                                  SizedBox(height: 4),
                                  Text('Lỗi tải ảnh', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 16,),
          if (widget.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children:[
                  Text(name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4,),
                  Expanded(
                    child: Text(
                      widget.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ] 
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Interaction buttons (like, comment, share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Like button and count
                InkWell(
                  onTap: () => {
                    istoglingLike ? {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thao tác quá nhanh! Thử lại sau.', style: TextStyle(color: Colors.red),), backgroundColor: Colors.white,),
                      )
                    } : _toggleLike()
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey.shade600,
                            size: 24,
                            key: ValueKey(isLiked),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentLikes.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Comment button and count
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentPage(
                          id: widget.id,
                          authorID: widget.authorID,
                          author: widget.author,
                          createdAt: widget.createdAt,
                          content: widget.content,
                          numberOfComment: widget.numberOfComment,
                          numberOfLike: widget.numberOfLike,
                          articleStatus: widget.articleStatus,
                          avatar: widget.avatar,
                          listImage: widget.listImage,
                          isLiked: widget.isLiked,
                          likeID: widget.likeID,
                        ), // truyền object Post
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.numberOfComment.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Share button
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chia sẻ bài viết')),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// VideoPlayerWidget remains the same
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  
  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);
  
  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller.initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
    });
    
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: CircularProgressIndicator(color: colorBG, strokeWidth: 2),
        ),
      );
    }
    
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        Center(
          child: IconButton(
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                Text(
                  _formatDuration(_controller.value.position),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _controller.value.position.inMilliseconds.toDouble(),
                      min: 0,
                      max: _controller.value.duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        _controller.seekTo(Duration(milliseconds: value.round()));
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _formatDuration(_controller.value.duration),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}