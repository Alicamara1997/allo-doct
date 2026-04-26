import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  // Remplacez par votre App ID Agora
  static const String appId = "7a127ccf060a4510a57327c358881990"; 
  
  static Future<void> setupPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  static Future<RtcEngine> initEngine() async {
    final engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    return engine;
  }
}
