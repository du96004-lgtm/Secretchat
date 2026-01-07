class UserModel {
  final String uid;
  final String publicId;
  final String name;
  final String email;
  final String? avatar;
  final bool online;
  final int createdAt;

  UserModel({
    required this.uid,
    required this.publicId,
    required this.name,
    required this.email,
    this.avatar,
    this.online = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      publicId: map['publicId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatar: map['avatar'],
      online: map['online'] ?? false,
      createdAt: map['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'publicId': publicId,
      'name': name,
      'email': email,
      'avatar': avatar,
      'online': online,
      'createdAt': createdAt,
    };
  }
}
