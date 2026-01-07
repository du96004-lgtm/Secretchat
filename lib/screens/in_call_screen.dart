import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/user_model.dart';
import '../screens/main_navigation.dart';

class InCallScreen extends StatefulWidget {
  final UserModel friend;
  final bool isVideo;
  final bool isCaller;
  final String callId;

  const InCallScreen({
    super.key,
    required this.friend,
    required this.isVideo,
    required this.isCaller,
    required this.callId,
  });

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  
  bool _isMicMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  String _status = "Initializing...";
  
  Timer? _callTimer;
  int _callDuration = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _callStatusSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _callerCandidatesSub;
  StreamSubscription? _receiverCandidatesSub;

  @override
  void initState() {
    super.initState();
    _isVideoOff = !widget.isVideo;
    _isSpeakerOn = widget.isVideo;
    _initWebRTC();
    _startTimer();
    _listenForCallEnd();
    
    if (widget.isCaller) {
      _playCallingTone();
    }
  }

  Future<void> _playCallingTone() async {
    try {
      await _audioPlayer.setSource(UrlSource('https://raw.githubusercontent.com/shubham-s-gupta/Flutter-WebRTC-Room/master/assets/calling.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint("Error playing calling tone: $e");
    }
  }

  Future<void> _stopCallingTone() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _initWebRTC() async {
    try {
      setState(() => _status = "Requesting permissions...");
      await [Permission.microphone, Permission.camera].request();

      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      setState(() => _status = "Starting camera...");
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': widget.isVideo ? {
          'facingMode': 'user',
          'width': 640,
          'height': 480,
        } : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;

      setState(() => _status = "Connecting...");
      
      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
        ]
      };

      _peerConnection = await createPeerConnection(configuration);

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          debugPrint("✅ Remote stream received");
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
            _status = "Connected";
          });
          _stopCallingTone();
        }
      };

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        final path = widget.isCaller ? 'caller' : 'receiver';
        FirebaseDatabase.instance.ref('calls/${widget.callId}/candidates/$path').push().set(candidate.toMap());
      };

      if (widget.isCaller) {
        await _createOffer();
      } else {
        await _listenForOffer();
      }

      _listenForCandidates();

    } catch (e) {
      debugPrint("❌ WebRTC Init Error: $e");
      if (mounted) setState(() => _status = "Failed: $e");
    }
  }

  Future<void> _createOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    
    await FirebaseDatabase.instance.ref('calls/${widget.callId}/offer').set({
      'sdp': offer.sdp,
      'type': offer.type,
    });

    _answerSub = FirebaseDatabase.instance.ref('calls/${widget.callId}/answer').onValue.listen((event) async {
      if (event.snapshot.exists && _peerConnection != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        RTCSessionDescription answer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(answer);
      }
    });
  }

  Future<void> _listenForOffer() async {
    _offerSub = FirebaseDatabase.instance.ref('calls/${widget.callId}/offer').onValue.listen((event) async {
      if (event.snapshot.exists && _peerConnection != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        RTCSessionDescription offer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(offer);
        
        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        
        await FirebaseDatabase.instance.ref('calls/${widget.callId}/answer').set({
          'sdp': answer.sdp,
          'type': answer.type,
        });
      }
    });
  }

  void _listenForCandidates() {
    final remotePath = widget.isCaller ? 'receiver' : 'caller';
    FirebaseDatabase.instance.ref('calls/${widget.callId}/candidates/$remotePath').onChildAdded.listen((event) async {
      if (event.snapshot.exists && _peerConnection != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        RTCIceCandidate candidate = RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
      }
    });
  }

  void _listenForCallEnd() {
    _callStatusSub = FirebaseDatabase.instance.ref('calls/${widget.callId}/status').onValue.listen((event) {
      if (!event.snapshot.exists) return;
      if (event.snapshot.value == 'ended' || event.snapshot.value == 'rejected') {
        if (mounted) _endCall();
      }
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _status == "Connected") {
        setState(() => _callDuration++);
      }
    });
  }

  Future<void> _endCall({String? reason}) async {
    _callTimer?.cancel();
    _callStatusSub?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _callerCandidatesSub?.cancel();
    _receiverCandidatesSub?.cancel();
    _stopCallingTone();
    
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();

    if (reason != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
    }
    
    await FirebaseDatabase.instance.ref('calls/${widget.callId}/status').set('ended');

    if (mounted) {
       Navigator.of(context).popUntil((r) => r.isFirst);
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
    }
  }

  void _onToggleMute() {
    setState(() => _isMicMuted = !_isMicMuted);
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMicMuted;
    });
  }

  void _onToggleVideo() {
    setState(() => _isVideoOff = !_isVideoOff);
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_isVideoOff;
    });
  }

  void _onSwitchCamera() {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  void _onToggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    Helper.setSpeakerphoneOn(_isSpeakerOn);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callStatusSub?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _callerCandidatesSub?.cancel();
    _receiverCandidatesSub?.cancel();
    _stopCallingTone();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String _formatDuration(int s) {
    if (s == 0 && _status != "Connected") return _status;
    int m = s ~/ 60;
    int rs = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildRemoteView(),
          if (_localStream != null && widget.isVideo && !_isVideoOff) 
            _buildLocalView(),
            
          _buildControls(),
          
          Positioned(
             top: 50, left: 20, right: 20,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(widget.friend.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 Text(_formatDuration(_callDuration), style: const TextStyle(color: Colors.white70, fontSize: 16)),
               ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteView() {
    if (_remoteRenderer.srcObject != null && widget.isVideo) {
      return RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover);
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: widget.friend.avatar != null ? NetworkImage(widget.friend.avatar!) : null,
            child: widget.friend.avatar == null ? const Icon(Icons.person, size: 80, color: Colors.white) : null,
          ),
          const SizedBox(height: 20),
          Text(
            _status,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalView() {
    return Positioned(
      top: 50,
      right: 20,
      width: 120,
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          color: Colors.black54,
          child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.9),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleButton(
              icon: _isMicMuted ? Icons.mic_off : Icons.mic,
              color: _isMicMuted ? Colors.red : Colors.white24,
              onPressed: _onToggleMute,
            ),
            const SizedBox(width: 15),
            _buildCircleButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              color: Colors.white24,
              onPressed: _onToggleSpeaker,
            ),
            if (widget.isVideo) ...[
              const SizedBox(width: 15),
              _buildCircleButton(
                icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                color: _isVideoOff ? Colors.red : Colors.white24,
                onPressed: _onToggleVideo,
              ),
              const SizedBox(width: 15),
              _buildCircleButton(
                icon: Icons.cameraswitch,
                color: Colors.white24,
                onPressed: _onSwitchCamera,
              ),
            ],
            const SizedBox(width: 20),
            _buildCircleButton(
              icon: Icons.call_end,
              color: Colors.red,
              onPressed: () => _endCall(),
              iconSize: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required Color color, required VoidCallback onPressed, double iconSize = 24}) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        onPressed: onPressed,
      ),
    );
  }
}
