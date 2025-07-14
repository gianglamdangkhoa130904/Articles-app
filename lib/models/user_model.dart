class User {
  final String id;
  final String username;
  final String password;
  final String name;
  final String phone;
  final String dob;
  final String email;
  final String? address;
  final String? description;
  final String? avatar;
  final List<String> followers;
  final List<String> followings;
  final String status;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.phone,
    required this.dob,
    required this.email,
    this.address,
    this.description,
    this.avatar,
    required this.followers,
    required this.followings,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] ?? '',
      email: json['email'] ?? '',
      address: json['address'],
      description: json['description'],
      avatar: json['avatar'],
      followers: List<String>.from(json['followers'] ?? []),
      followings: List<String>.from(json['followings'] ?? []),
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'password': password,
      'name': name,
      'phone': phone,
      'dob': dob,
      'email': email,
      'address': address,
      'description': description,
      'avatar': avatar,
      'followers': followers,
      'followings': followings,
      'status': status,
    };
  }
}
