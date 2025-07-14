class Article {
  final String id;
  final String content;
  final String author;
  final String createdAt;
  final String articleStatus;
  final int numberOfComment;
  final int numberOfLike;

  Article({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.articleStatus,
    required this.numberOfComment,
    required this.numberOfLike
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['_id'] ?? '',
      content: json['description'] ?? '',
      author: json['userID'] ?? '',
      createdAt: json['publishDate'] ?? '',
      articleStatus: json['articleStatus'] ?? '',
      numberOfComment: json['numberOfComment'] ?? '',
      numberOfLike: json['numberOfLike'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'description': content,
      'userID': author,
      'publishDate': createdAt,
      'articleStatus': articleStatus,
      'numberOfComment': numberOfComment,
      'numberOfLike': numberOfLike,
    };
  }
  Article copyWith({
    String? id,
    String? content,
    String? author,
    String? createdAt,
    String? articleStatus,
    int? numberOfComment,
    int? numberOfLike,
  }) {
    return Article(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      articleStatus: articleStatus ?? this.articleStatus,
      numberOfComment: numberOfComment ?? this.numberOfComment,
      numberOfLike: numberOfLike ?? this.numberOfLike,
    );
  }
}
