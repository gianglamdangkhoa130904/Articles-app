import 'package:final_project/models/user_model.dart';

class Comment {
  final String id;
  final String articleID;
  final User userID;
  final String commentDetail;
  final String commentStatus;
  final String publishDate;

  Comment({
    required this.id,
    required this.articleID,
    required this.userID,
    required this.commentDetail,
    required this.commentStatus,
    required this.publishDate,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? json['id'] ?? '',
      articleID: json['articleID'] ?? '',
      userID: _parseUserID(json['userID']),
      commentDetail: json['commentDetail'] ?? '',
      commentStatus: json['commentStatus'] ?? 'active',
      publishDate: json['publishDate'] ?? json['createdAt'] ?? '',
    );
  }

  // Helper method để parse userID safely
  static User _parseUserID(dynamic userIDData) {
    if (userIDData == null) {
      // Có thể throw exception hoặc return default User
      throw Exception('UserID không thể null');
    }
    
    if (userIDData is Map<String, dynamic>) {
      // Nếu userID là populated object, sử dụng User.fromJson()
      return User.fromJson(userIDData);
    } else if (userIDData is String) {
      // Nếu chỉ có ID string, tạo User object với thông tin tối thiểu
      // Hoặc có thể fetch thêm thông tin user từ API khác
      return User.fromJson({
        '_id': userIDData,
        'id': userIDData,
        'username': 'Loading...', // Temporary, có thể fetch sau
        'avatar': '',
        // Thêm các field required khác của User model
      });
    } else {
      // Fallback: convert về Map và parse
      return User.fromJson({
        '_id': userIDData.toString(),
        'username': 'Unknown User',
        'avatar': '',
      });
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'articleID': articleID,
      'userID': userID.toJson(), // Sử dụng User.toJson()
      'commentDetail': commentDetail,
      'commentStatus': commentStatus,
      'publishDate': publishDate,
    };
  }

  // Getter methods để dễ sử dụng trong UI
  String get userName => userID.username;
  String get userAvatar => userID.avatar?? '';
  String get timeAgo {
    try {
      DateTime publishDateTime = DateTime.parse(publishDate);
      DateTime now = DateTime.now();
      Duration difference = now.difference(publishDateTime);

      if (difference.inDays > 365) {
        int years = (difference.inDays / 365).floor();
        return '$years năm trước';
      } else if (difference.inDays > 30) {
        int months = (difference.inDays / 30).floor();
        return '$months tháng trước';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return publishDate; // Fallback về original date string
    }
  }
}