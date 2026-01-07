import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<List<UserModel>> getFriends() {
    if (currentUid == null) return Stream.value([]);
    return _db.ref('friends/$currentUid').onValue.asyncMap((event) async {
      List<UserModel> friends = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          Map<dynamic, dynamic> data = event.snapshot.value as Map;
          for (var friendUid in data.keys) {
            try {
              // Check if friend entry is valid (could be boolean or object)
              var friendData = data[friendUid];
              bool isAccepted = false;
              
              if (friendData is bool) {
                isAccepted = friendData;
              } else if (friendData is Map) {
                isAccepted = friendData['accepted'] == true;
              }
              
              if (isAccepted) {
                final userSnap = await _db.ref('users/$friendUid').get();
                if (userSnap.exists && userSnap.value != null) {
                  friends.add(UserModel.fromMap(userSnap.value as Map));
                }
              }
            } catch (e) {
              print('Error loading friend $friendUid: $e');
              // Continue to next friend
            }
          }
        } catch (e) {
          print('Error loading friends list: $e');
        }
      }
      return friends;
    });
  }

  Future<void> sendFriendRequest(String publicId) async {
    try {
      print('🔍 Looking up publicId: "$publicId"');
      
      // Get target user ID from public ID
      final snap = await _db.ref('publicIds/$publicId').get();
      
      print('📊 Snapshot exists: ${snap.exists}, value: ${snap.value}, type: ${snap.value.runtimeType}');
      
      if (!snap.exists || snap.value == null) {
        print('❌ User not found in publicIds for: $publicId');
        throw "User not found with ID: $publicId";
      }
      
      // Safely convert to string - handle both String and other types
      String targetUid;
      try {
        if (snap.value is String) {
          targetUid = snap.value as String;
        } else if (snap.value is Map) {
          // Handle corrupted data - try to extract uid
          targetUid = (snap.value as Map)['uid']?.toString() ?? '';
        } else {
          targetUid = snap.value.toString();
        }
        
        if (targetUid.isEmpty) {
          throw "Invalid user data for ID: $publicId";
        }
        
        print('✅ Found targetUid: $targetUid');
      } catch (e) {
        print('Error parsing publicId data: $e, value type: ${snap.value.runtimeType}');
        throw "User not found with ID: $publicId";
      }
      
      if (targetUid == currentUid) {
        throw "You cannot add yourself";
      }

      // Verify the user actually exists
      final userCheck = await _db.ref('users/$targetUid').get();
      if (!userCheck.exists) {
        throw "User not found with ID: $publicId";
      }

      // Check if already friends - handle both old and new data formats
      final friendCheck = await _db.ref('friends/$currentUid/$targetUid').get();
      if (friendCheck.exists && friendCheck.value != null) {
        try {
          var friendData = friendCheck.value;
          bool isFriend = false;
          
          if (friendData is bool) {
            isFriend = friendData;
          } else if (friendData is Map) {
            isFriend = friendData['accepted'] == true;
          }
          
          if (isFriend) {
            throw "Already friends with this user";
          }
        } catch (e) {
          // If there's any error parsing friend data, assume not friends
          print('Error checking friend status: $e');
        }
      }

      // Check if request already sent
      final requestCheck = await _db.ref('requests/$targetUid/$currentUid').get();
      if (requestCheck.exists && requestCheck.value != null) {
        throw "Friend request already sent";
      }

      // Send the request
      await _db.ref('requests/$targetUid/$currentUid').set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      });
    } catch (e) {
      // Re-throw with more context
      if (e.toString().contains('User not found') || 
          e.toString().contains('cannot add yourself') ||
          e.toString().contains('Already friends') ||
          e.toString().contains('already sent')) {
        rethrow;
      }
      throw "Error sending friend request: ${e.toString()}";
    }
  }

  Stream<List<UserModel>> getIncomingRequests() {
    if (currentUid == null) return Stream.value([]);
    return _db.ref('requests/$currentUid').onValue.asyncMap((event) async {
      List<UserModel> requesters = [];
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        for (var requesterUid in data.keys) {
          final userSnap = await _db.ref('users/$requesterUid').get();
          if (userSnap.exists) {
            requesters.add(UserModel.fromMap(userSnap.value as Map));
          }
        }
      }
      return requesters;
    });
  }

  Future<void> acceptRequest(String requesterUid) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Add to both users' friend lists with timestamp
    await _db.ref('friends/$currentUid/$requesterUid').set({
      'timestamp': timestamp,
      'accepted': true,
    });
    
    await _db.ref('friends/$requesterUid/$currentUid').set({
      'timestamp': timestamp,
      'accepted': true,
    });
    
    // Remove the request
    await _db.ref('requests/$currentUid/$requesterUid').remove();
    
    // Notify the requester that their request was accepted
    await _db.ref('notifications/$requesterUid/friend_accepted').set({
      'acceptedBy': currentUid,
      'timestamp': timestamp,
    });
  }

  Future<void> rejectRequest(String requesterUid) async {
    await _db.ref('requests/$currentUid/$requesterUid').remove();
  }

  Stream<List<MessageModel>> getMessages(String friendUid) {
    String chatRoomId = _getChatRoomId(currentUid!, friendUid);
    return _db.ref('messages/$chatRoomId').onValue.map((event) {
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

  Future<void> sendMessage(String friendUid, String text) async {
    String chatRoomId = _getChatRoomId(currentUid!, friendUid);
    await _db.ref('messages/$chatRoomId').push().set({
      'senderId': currentUid,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteMessage(String friendUid, String messageId) async {
    String chatRoomId = _getChatRoomId(currentUid!, friendUid);
    await _db.ref('messages/$chatRoomId/$messageId').remove();
  }

  Future<void> clearChat(String friendUid) async {
    String chatRoomId = _getChatRoomId(currentUid!, friendUid);
    await _db.ref('messages/$chatRoomId').remove();
  }

  String _getChatRoomId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }
}
