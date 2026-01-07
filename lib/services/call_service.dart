import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/call_model.dart';
import '../screens/in_call_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class CallService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  StreamSubscription? _incomingCallSub;

  String? get currentUid => _auth.currentUser?.uid;

  Future<void> makeCall(BuildContext context, UserModel receiver, {bool isVideo = false}) async {
    String callId = _db.ref('calls').push().key!;
    
    // Save to call history (sender)
    await _db.ref('call_history/$currentUid/$callId').set({
      'callerId': currentUid,
      'callerName': _auth.currentUser?.displayName ?? "Me",
      'callerAvatar': _auth.currentUser?.photoURL,
      'receiverId': receiver.uid,
      'receiverName': receiver.name,
      'receiverAvatar': receiver.avatar,
      'type': isVideo ? 'video' : 'audio',
      'status': 'calling',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Save to call history (receiver)
    await _db.ref('call_history/${receiver.uid}/$callId').set({
      'callerId': currentUid,
      'callerName': _auth.currentUser?.displayName ?? "Someone",
      'callerAvatar': _auth.currentUser?.photoURL,
      'receiverId': receiver.uid,
      'receiverName': receiver.name,
      'receiverAvatar': receiver.avatar,
      'type': isVideo ? 'video' : 'audio',
      'status': 'missed',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Initialize call document
    await _db.ref('calls/$callId').set({
      'status': 'calling',
      'type': isVideo ? 'video' : 'audio',
      'callerId': currentUid,
      'receiverId': receiver.uid,
    });

    // Notify receiver
    await _db.ref('notifications/${receiver.uid}/incoming_call').set({
      'callId': callId,
      'callerId': currentUid,
      'callerName': _auth.currentUser?.displayName ?? "Someone",
      'callerAvatar': _auth.currentUser?.photoURL,
      'type': isVideo ? 'video' : 'audio',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Navigate to call screen (Sender)
    if (context.mounted) {
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (_) => InCallScreen(
             friend: receiver,
             isVideo: isVideo,
             isCaller: true,
             callId: callId,
           ),
         ),
       );
    }
  }

  void listenForIncomingCalls(BuildContext context) {
    if (currentUid == null) return;
    _incomingCallSub?.cancel();
    _incomingCallSub = _db.ref('notifications/$currentUid/incoming_call').onValue.listen((event) async {
      if (!event.snapshot.exists) return;
      Map data = event.snapshot.value as Map;
      String callId = data['callId'];
      
      // Update status to ringing
      _db.ref('calls/$callId/status').set('ringing');

      // Play Incoming Ringtone
      try {
        await _ringtonePlayer.setSource(UrlSource('https://raw.githubusercontent.com/Anirudh-C/Video-Calling-App/master/assets/calling_tone.mp3'));
        await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
        await _ringtonePlayer.resume();
      } catch (e) {
        debugPrint("Error playing ringtone: $e");
      }

      // Incoming Call Dialog
      if (context.mounted) {
        _showIncomingCallDialog(context, data);
      }
    });
  }

  void _showIncomingCallDialog(BuildContext context, Map data) {
    bool dialogDismissed = false;

    // Listen if caller cancels
    final cancelSub = _db.ref('calls/${data['callId']}/status').onValue.listen((event) {
      if (event.snapshot.exists && (event.snapshot.value == 'ended' || event.snapshot.value == 'rejected')) {
         if (!dialogDismissed) {
           _ringtonePlayer.stop();
           Navigator.of(context).pop();
           dialogDismissed = true;
         }
      }
    });

    showGeneralPage(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Spacer(),
                   Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.white24, width: 2),
                     ),
                     child: CircleAvatar(
                       radius: 60,
                       backgroundColor: Colors.grey[800],
                       backgroundImage: data['callerAvatar'] != null ? NetworkImage(data['callerAvatar']) : null,
                       child: data['callerAvatar'] == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                     ),
                   ),
                   const SizedBox(height: 24),
                   Text(data['callerName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text("Secretchat ${data['type']} call", style: const TextStyle(color: Colors.white70, fontSize: 18)),
                   const Spacer(),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                       _buildCallAction(
                         icon: Icons.call_end,
                         color: Colors.red,
                         label: "Decline",
                         onTap: () async {
                           dialogDismissed = true;
                           cancelSub.cancel();
                           _ringtonePlayer.stop();
                           await _db.ref('notifications/$currentUid/incoming_call').remove();
                           await _db.ref('calls/${data['callId']}/status').set('rejected');
                           if (context.mounted) Navigator.pop(context);
                         },
                       ),
                       _buildCallAction(
                         icon: Icons.call,
                         color: Colors.green,
                         label: "Accept",
                         onTap: () async {
                           dialogDismissed = true;
                           cancelSub.cancel();
                           _ringtonePlayer.stop();
                           await _db.ref('notifications/$currentUid/incoming_call').remove();
                           await _db.ref('call_history/$currentUid/${data['callId']}/status').set('incoming');
                           
                           if (context.mounted) {
                             Navigator.pop(context);
                             
                             final userSnap = await _db.ref('users/${data['callerId']}').get();
                             if (userSnap.exists) {
                               UserModel caller = UserModel.fromMap(userSnap.value as Map);
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (_) => InCallScreen(
                                     friend: caller,
                                     isVideo: data['type'] == 'video',
                                     isCaller: false,
                                     callId: data['callId'],
                                   ),
                                 ),
                               );
                             }
                           }
                         },
                       ),
                     ],
                   ),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallAction({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  void showGeneralPage({required BuildContext context, required RoutePageBuilder pageBuilder}) {
     Navigator.push(context, PageRouteBuilder(
       pageBuilder: pageBuilder,
       transitionsBuilder: (context, animation, secondaryAnimation, child) {
         return FadeTransition(opacity: animation, child: child);
       },
     ));
  }

  Stream<List<CallModel>> getCallHistory() {
    if (currentUid == null) return Stream.value([]);
    return _db.ref('call_history/$currentUid').onValue.map((event) {
      List<CallModel> history = [];
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          history.add(CallModel.fromMap(key, value));
        });
        history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return history;
    });
  }

  Future<void> deleteCallLog(String callId) async {
    if (currentUid == null) return;
    await _db.ref('call_history/$currentUid/$callId').remove();
  }

  Future<void> clearCallHistory() async {
    if (currentUid == null) return;
    await _db.ref('call_history/$currentUid').remove();
  }

  void dispose() {
    _incomingCallSub?.cancel();
    _ringtonePlayer.dispose();
  }
}

