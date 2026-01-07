enum CallStatus { answered, missed, rejected }
enum CallType { audio, video }

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final CallType type;
  final CallStatus status;
  final int timestamp;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.type,
    required this.status,
    required this.timestamp,
  });

  factory CallModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return CallModel(
      id: id,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? 'Unknown',
      callerAvatar: map['callerAvatar'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? 'Unknown',
      receiverAvatar: map['receiverAvatar'],
      type: map['type'] == 'video' ? CallType.video : CallType.audio,
      status: CallStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'missed'),
        orElse: () => CallStatus.missed,
      ),
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp,
    };
  }
}
