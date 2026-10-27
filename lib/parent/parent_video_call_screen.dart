import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pass a short-lived token issued by your authenticated backend.
/// The backend must authorize this user for the appointment and return
/// the same channelName for both participants, but a distinct uid per user.
class ParentVideoCallScreen extends StatefulWidget {
  const ParentVideoCallScreen({
    super.key,
    required this.appId,
    required this.token,
    required this.channelName,
    required this.uid,
    required this.therapistName,
  });

  final String appId;
  final String token;
  final String channelName;
  final int uid;
  final String therapistName;

  @override
  State<ParentVideoCallScreen> createState() => _ParentVideoCallScreenState();
}

class _ParentVideoCallScreenState extends State<ParentVideoCallScreen> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _micOn = true;
  bool _cameraOn = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final permissions = await [Permission.camera, Permission.microphone].request();
      if (permissions.values.any((status) => !status.isGranted)) {
        throw StateError('Camera and microphone permissions are required.');
      }
      if (widget.appId.isEmpty || widget.token.isEmpty || widget.channelName.isEmpty) {
        throw StateError('Missing Agora App ID, token or channel.');
      }
      final engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(RtcEngineContext(appId: widget.appId));
      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _joined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted && _remoteUid == remoteUid) {
            setState(() => _remoteUid = null);
          }
        },
        onError: (code, message) {
          if (mounted) setState(() => _error = '$code: $message');
        },
      ));
      await engine.enableVideo();
      await engine.startPreview();
      await engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: widget.uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleMic() async {
    final next = !_micOn;
    await _engine?.muteLocalAudioStream(!next);
    if (mounted) setState(() => _micOn = next);
  }

  Future<void> _toggleCamera() async {
    final next = !_cameraOn;
    await _engine?.muteLocalVideoStream(!next);
    if (mounted) setState(() => _cameraOn = next);
  }

  Future<void> _endCall() async {
    await _engine?.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    final engine = _engine;
    if (engine != null) {
      engine.leaveChannel().then((_) => engine.release());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    return Scaffold(
      backgroundColor: const Color(0xFF211A32),
      appBar: AppBar(
        title: Text('Session with ${widget.therapistName}'),
        backgroundColor: const Color(0xFF35274C),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _remoteUid != null && engine != null
                        ? AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: engine,
                              canvas: VideoCanvas(uid: _remoteUid),
                              connection: RtcConnection(channelId: widget.channelName),
                            ),
                          )
                        : Center(
                            child: Text(
                              _error ?? (_joined ? 'Waiting for therapist to join…' : 'Connecting…'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                  ),
                  if (engine != null && _cameraOn)
                    Positioned(
                      right: 16,
                      top: 16,
                      width: 112,
                      height: 156,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: engine,
                            canvas: VideoCanvas(uid: widget.uid),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filled(
                    onPressed: _toggleMic,
                    icon: Icon(_micOn ? Icons.mic : Icons.mic_off),
                    tooltip: 'Toggle microphone',
                  ),
                  IconButton.filled(
                    onPressed: _toggleCamera,
                    icon: Icon(_cameraOn ? Icons.videocam : Icons.videocam_off),
                    tooltip: 'Toggle camera',
                  ),
                  IconButton.filled(
                    onPressed: () => _engine?.switchCamera(),
                    icon: const Icon(Icons.cameraswitch),
                    tooltip: 'Switch camera',
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _endCall,
                    icon: const Icon(Icons.call_end),
                    tooltip: 'End call',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
