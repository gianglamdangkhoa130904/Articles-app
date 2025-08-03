import 'package:final_project/components/card_post.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart' as article_model;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/default/default.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
class ImageFile {
  final String fileName;
  final String fileID;

  ImageFile({required this.fileName, required this.fileID});

  factory ImageFile.fromJson(Map<String, dynamic> json) {
    return ImageFile(
      fileName: json['fileName'] ?? '',
      fileID: json['fileID'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileID': fileID,
    };
  }
}
class FullArticle {
  final article_model.Article article;
  final String authorID;
  final String authorName;
  final String avatar;
  final List<ImageFile> listImage;
  final bool isLiked;
  final String likeID;

  FullArticle({
    required this.article,
    required this.authorID,
    required this.authorName,
    required this.avatar,
    required this.listImage,
    required this.isLiked,
    required this.likeID,
  });

  factory FullArticle.fromJson(Map<String, dynamic> json) {
    return FullArticle(
      article: article_model.Article.fromJson(json['article']),
      authorID: json['authorID'] ?? '',
      authorName: json['authorName'] ?? '',
      avatar: json['avatar'] ?? '',
      listImage: (json['listImage'] as List<dynamic>?)
          ?.map((item) => ImageFile.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      isLiked: json['isLiked'] ?? false,
      likeID: json['likeID'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'article': article.toJson(),
      'authorID': authorID,
      'authorName': authorName,
      'avatar': avatar,
      'listImage': listImage.map((image) => image.toJson()).toList(),
      'isLiked': isLiked,
      'likeID': likeID,
    };
  }
}
Future<String> fetchLike(String userID, String articleID) async {
  try {
    final url = Uri.parse('https://dhkptsocial.onrender.com/likes/${userID}/${articleID}');
    final response = await http.get(url);
    
    if (response.body == 'null' || response.body.isEmpty) {
      return '';
    }
    
    final like = json.decode(response.body);
    // print(userID);
    // print(articleID);
    // print(like?['_id']?.toString());
    return like?['_id']?.toString() ?? '';
  } catch (e) {
    print('Lỗi khi fetch like: $e');
    return '';
  }
}

Future<List<String>> fetchFollowing(String userID) async {
  try {
    final url = Uri.parse('https://dhkptsocial.onrender.com/users/$userID');
    final response = await http.get(url);
    
    if (response.statusCode != 200) {
      throw Exception('Lỗi lấy danh sách following: ${response.statusCode}');
    }
    
    final responseData = json.decode(response.body);
    final listFollowing = responseData['followings'] as List<dynamic>?;
    
    if (listFollowing == null) {
      return [];
    }
    
    return listFollowing
        .map((item) => item['_id'].toString())
        .toList();
  } catch (e) {
    throw Exception('Lỗi khi lấy danh sách following: $e');
  }
}
// Lấy danh sách bài đăng
Future<List<FullArticle>> fetchArticleList(String userID) async {
  try {
    // Lấy danh sách các user mà người này follow
    final listFollowing = await fetchFollowing(userID);
    
    if (listFollowing.isEmpty) {
      return [];
    }
    
    List<FullArticle> fullArticles = [];
    
    for (var follower in listFollowing) {
      try {
        final url = Uri.parse('https://dhkptsocial.onrender.com/articles/$follower');
        final response = await http.get(url);
        
        if (response.statusCode != 200) {
          print('Không thể lấy bài viết của user $follower: ${response.statusCode}');
          continue;
        }

        final responseBody = json.decode(response.body);
        final List<dynamic> articleList = responseBody['data'] as List<dynamic>? ?? [];

        for (var item in articleList) {
          try {
            final article = article_model.Article.fromJson(item);
            
            // Fetch thông tin author
            String authorName = '';
            String avatar = '';
            
            try {
              final userResponse = await http.get(
                Uri.parse('https://dhkptsocial.onrender.com/users/${article.author}')
              );
              if (userResponse.statusCode == 200) {
                final userData = json.decode(userResponse.body);
                authorName = userData['name']?.toString() ?? '';
                final avatarId = userData['avatar']?.toString();
                if (avatarId != null && avatarId.isNotEmpty) {
                  avatar = 'https://dhkptsocial.onrender.com/files/download/$avatarId';
                }
              }
            } catch (e) {
              print('Lỗi khi lấy thông tin user ${article.author}: $e');
            }
            
            // Fetch file của bài đăng
            List<ImageFile> images = [];
            try {
              final fileResponse = await http.get(
                Uri.parse('https://dhkptsocial.onrender.com/files/${article.id}')
              );
              if (fileResponse.statusCode == 200) {
                final fileData = json.decode(fileResponse.body) as List<dynamic>? ?? [];
                images = fileData
                    .map<ImageFile>((item) => ImageFile(
                        fileName: item['filename'] ?? '', // Tùy thuộc vào tên field trong API
                        fileID: 'https://dhkptsocial.onrender.com/files/download/${item['_id'].toString()}',
                    ))
                    .toList();
              }
            } catch (e) {
              print('Lỗi khi lấy hình ảnh cho bài viết ${article.id}: $e');
            }
            
            // Fetch like status - Di chuyển xuống cuối
            String likeID = await fetchLike(userID, article.id);
            
            // Cải thiện logic tạo FullArticle
            fullArticles.add(FullArticle(
              article: article,
              authorID: article.author,
              authorName: authorName,
              avatar: avatar,
              listImage: images,
              isLiked: likeID.isNotEmpty,
              likeID: likeID
            ));
            
          } catch (e) {
            print('Lỗi khi xử lý bài viết: $e');
            continue;
          }
        }
      } catch (e) {
        print('Lỗi khi xử lý user $follower: $e');
        continue;
      }
    }
    
    // Sắp xếp theo thời gian tạo (mới nhất trước)
    fullArticles.sort((a, b) => b.article.createdAt.compareTo(a.article.createdAt));
    final visibleArticles = fullArticles.where((e) => e.article.articleStatus != 'hidden').toList();
    return visibleArticles;
  } catch (e) {
    throw Exception('Lỗi khi fetch articles: $e');
  }
}
//Lấy danh sách bài đăng từ Cache hoặc lưu vào Cache
Future<List<FullArticle>> loadOrSaveToCache() async {
  try {

    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('customerId');
    final cacheKey = 'cached_articles';
    final cacheTimeKey = 'cache_timestamp';
    
    // Kiểm tra cache có hết hạn không (ví dụ: 10 phút)
    final cacheTime = prefs.getInt(cacheTimeKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final cacheExpiry = 10 * 60 * 1000;
    
    final isCacheExpired = (currentTime - cacheTime) > cacheExpiry;
    
    // Lấy dữ liệu cache
    final cachedData = prefs.getStringList(cacheKey);
    List<FullArticle> cachedArticles = [];
    
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        cachedArticles = cachedData
            .map((e) => FullArticle.fromJson(json.decode(e)))
            .toList();
      } catch (e) {
        print('Lỗi khi parse cache: $e');
        // Xóa cache bị lỗi
        await prefs.remove(cacheKey);
        await prefs.remove(cacheTimeKey);
      }
    }
    
    // Nếu cache chưa hết hạn và có dữ liệu, trả về cache
    if (!isCacheExpired && cachedArticles.isNotEmpty) {
      return cachedArticles;
    }
    
    // Fetch dữ liệu mới từ server
    try {
      final newArticles = await fetchArticleList(userID!);
      
      // Lưu vào cache
      if (newArticles.isNotEmpty) {
        final jsonList = newArticles.map((e) => json.encode(e.toJson())).toList();
        await prefs.setStringList(cacheKey, jsonList);
        await prefs.setInt(cacheTimeKey, currentTime);
      }
      return newArticles;
    } catch (e) {
      print('Lỗi khi fetch từ server: $e');
      
      // Nếu fetch thất bại, dùng cache cũ (nếu có)
      if (cachedArticles.isNotEmpty) {
        return cachedArticles;
      } else {
        // Nếu không có cache, throw lỗi
        throw Exception('Không thể lấy dữ liệu từ server và không có cache: $e');
      }
    }
  } catch (e) {
    throw Exception('Lỗi trong fetchArticlesWithCache: $e');
  }
}
Future<FullArticle> _fetchArticle(article_model.Article article) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('customerId');
    
    // Fetch thông tin author
    String authorName = '';
    String avatar = '';
    
    try {
      final userResponse = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/users/${article.author}')
      );
      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        authorName = userData['name']?.toString() ?? '';
        final avatarId = userData['avatar']?.toString();
        if (avatarId != null && avatarId.isNotEmpty) {
          avatar = 'https://dhkptsocial.onrender.com/files/download/$avatarId';
        }
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin user ${article.author}: $e');
    }
    
    // Fetch file của bài đăng
    List<ImageFile> images = [];
    try {
      final fileResponse = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/files/${article.id}')
      );
      if (fileResponse.statusCode == 200) {
        final fileData = json.decode(fileResponse.body) as List<dynamic>? ?? [];
        images = fileData
          .map<ImageFile>((item) => ImageFile(
              fileName: item['filename'] ?? '', // Tùy thuộc vào tên field trong API
              fileID: 'https://dhkptsocial.onrender.com/files/download/${item['_id'].toString()}',
          ))
          .toList();
      }
    } catch (e) {
      print('Lỗi khi lấy hình ảnh cho bài viết ${article.id}: $e');
    }
    
    // Fetch like status - Di chuyển xuống cuối
    String likeID = await fetchLike(userID!, article.id);
    
    // Cải thiện logic tạo FullArticle
    return FullArticle(
      article: article,
      authorID: article.author,
      authorName: authorName,
      avatar: avatar,
      listImage: images,
      isLiked: likeID.isNotEmpty,
      likeID: likeID
    );
    
  } catch (e) {
    print('Lỗi khi xử lý bài viết: $e');
    return FullArticle(
      article: article,
      authorID: '',
      authorName: '',
      avatar: '',
      listImage: [],
      isLiked: false,
      likeID: ''
    );
  }
}

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late IO.Socket socket;
  Future<List<FullArticle>>? _futureArticles; 
  List<FullArticle> articleList = [];
  @override
  void initState() {
    super.initState();
    _futureArticles = loadOrSaveToCache();
    _loadArticle();
    connectSocket();
  }
  void _loadArticle() async{
    final article = await loadOrSaveToCache();
    setState(() {
      articleList = article;
    });
  }
  
  void connectSocket(){
    socket = IO.io(
      'https://dhkptsocial.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );
    socket.onConnect((_){
      print('Connected to socket');
    });
    socket.on('newArticle', (data) async{
      print('Nhận sự kiện thêm bài đăng');
        article_model.Article newArticle = article_model.Article.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        final userID = prefs.getString('customerId');
        final listFollowing = await fetchFollowing(userID!);

        if(listFollowing.contains(newArticle.author)){
          FullArticle addedArticle = await _fetchArticle(article_model.Article.fromJson(data));
          if(mounted){
            setState(() {
              articleList.add(addedArticle);
            });
          }

          final cacheTimeKey = 'cache_timestamp';
          final cacheKey = 'cached_articles';
          final cachedData = prefs.getStringList(cacheKey);
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          List<FullArticle> cachedArticles = [];
          
          if (cachedData != null && cachedData.isNotEmpty) {
            try {
              cachedArticles = cachedData
                  .map((e) => FullArticle.fromJson(json.decode(e)))
                  .toList();
            } catch (e) {
              print('Lỗi khi parse cache: $e');
              // Xóa cache bị lỗi
              await prefs.remove(cacheKey);
            }
          }
          cachedArticles.add(addedArticle);
          final jsonList = cachedArticles.map((e) => json.encode(e.toJson())).toList();
          await prefs.setStringList(cacheKey, jsonList);
          await prefs.setInt(cacheTimeKey, currentTime);
        }
      });
  }
  @override
  Widget build(BuildContext context) {
    return articleList.isNotEmpty ? (
      ListView.builder(
        padding: const EdgeInsets.all(4),
        itemCount: articleList.length,
        itemBuilder: (context, index){
          final article = articleList[index];
              return CardPost(
                id: article.article.id,
                authorID: article.authorID,
                author: article.authorName,
                createdAt: article.article.createdAt,
                content: article.article.content,
                numberOfComment: article.article.numberOfComment,
                numberOfLike: article.article.numberOfLike,
                articleStatus: article.article.articleStatus,
                avatar: article.avatar,
                listImage: article.listImage,
                isLiked: article.isLiked,
                likeID: article.likeID,
              );
        }
      )
    ) : (
      FutureBuilder<List<FullArticle>>(
        future: _futureArticles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorBG,));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có bài viết nào'));
          } else {
            return const Center(child: Text('Tải bài viết thành công', style: TextStyle(color: Colors.green),));
          }
        },
      )
    );
  }
}