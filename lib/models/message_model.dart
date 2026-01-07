class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final int timestamp;
  final String? imageUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.imageUrl,
  });

  factory MessageModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
    };
  }
}
