class Comment {
  final String id;
  final String articleID;
  final String userID;
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
      id: json['id'] as String,
      articleID: json['articleID'] as String,
      userID: json['userID'] as String,
      commentDetail: json['commentDetail'] as String,
      commentStatus: json['commentStatus'] as String,
      publishDate: json['publishDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'articleID': articleID,
      'userID': userID,
      'commentDetail': commentDetail,
      'commentStatus': commentStatus,
      'publishDate': publishDate,
    };
  }
}