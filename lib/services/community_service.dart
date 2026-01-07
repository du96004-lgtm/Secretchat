import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';

class CommunityService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  Future<void> createCommunity(String name, String description) async {
    String id = _db.ref('communities').push().key!;
    CommunityModel community = CommunityModel(
      id: id,
      name: name,
      description: description,
      creatorId: currentUid!,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.ref('communities/$id').set(community.toMap());
  }

  Stream<List<CommunityModel>> getCommunities() {
    return _db.ref('communities').onValue.map((event) {
      List<CommunityModel> communities = [];
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          communities.add(CommunityModel.fromMap(key, value));
        });
      }
      return communities;
    });
  }

  Stream<List<MessageModel>> getCommunityMessages(String communityId) {
    return _db.ref('community_messages/$communityId').onValue.map((event) {
      List<MessageModel> messages = [];
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          messages.add(MessageModel.fromMap(key, value));
        });
        messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return messages;
    });
  }

  Future<void> sendCommunityMessage(String communityId, String text) async {
    await _db.ref('community_messages/$communityId').push().set({
      'senderId': currentUid,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
