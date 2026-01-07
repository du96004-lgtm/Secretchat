class CommunityModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String creatorId;
  final int createdAt;

  CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.creatorId,
    required this.createdAt,
  });

  factory CommunityModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return CommunityModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      iconUrl: map['iconUrl'],
      creatorId: map['creatorId'] ?? '',
      createdAt: map['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'creatorId': creatorId,
      'createdAt': createdAt,
    };
  }
}
