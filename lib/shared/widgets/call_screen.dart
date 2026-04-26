import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/agora_service.dart';

class CallScreen extends StatefulWidget {
  final UserModel currentUser;
  final String remoteUserName;
  final String callId;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.currentUser,
    required this.remoteUserName,
    required this.callId,
    this.isVideoCall = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _muted = false;
  bool _videoEnabled = true;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // 1. Demander les permissions
    await AgoraService.setupPermissions();

    // 2. Initialiser le moteur
    _engine = await AgoraService.initEngine();

    // 3. Configurer les écouteurs d'événements
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined with uid: ${connection.localUid}");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined with uid: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user offline");
          setState(() {
            _remoteUid = null;
          });
          Navigator.pop(context);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("Left channel");
        },
      ),
    );

    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.enableAudio();
    }

    // 4. Rejoindre le canal
    // Note: Dans un environnement de test Agora, vous pouvez utiliser un AppID sans Token
    await _engine.joinChannel(
      token: "", // À remplacer par un vrai token en production
      channelId: widget.callId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _disposeAgora();
    super.dispose();
  }

  Future<void> _disposeAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _remoteVideoView(),
          _localVideoView(),
          _buildOverlayHeader(),
          _buildControls(),
        ],
      ),
    );
  }

  // Vue de la vidéo distante (Plein écran)
  Widget _remoteVideoView() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.callId),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                "En attente de ${widget.remoteUserName}...",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Vue de la vidéo locale (Vignette flottante)
  Widget _localVideoView() {
    if (_localUserJoined && widget.isVideoCall && _videoEnabled) {
      return Positioned(
        top: 60,
        right: 20,
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildOverlayHeader() {
    return Positioned(
      top: 50,
      left: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.remoteUserName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
              SizedBox(width: 8),
              Text(
                "Appel en cours",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            onPressed: () {
              setState(() => _muted = !_muted);
              _engine.muteLocalAudioStream(_muted);
            },
            icon: _muted ? Icons.mic_off : Icons.mic,
            color: _muted ? Colors.red : Colors.white.withAlpha(50),
          ),
          _buildControlButton(
            onPressed: () => Navigator.pop(context),
            icon: Icons.call_end,
            color: Colors.red,
            size: 70,
          ),
          if (widget.isVideoCall)
            _buildControlButton(
              onPressed: () {
                setState(() => _videoEnabled = !_videoEnabled);
                _engine.muteLocalVideoStream(!_videoEnabled);
              },
              icon: _videoEnabled ? Icons.videocam : Icons.videocam_off,
              color: !_videoEnabled ? Colors.red : Colors.white.withAlpha(50),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    double size = 55,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 10)],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
