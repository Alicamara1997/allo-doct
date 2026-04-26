import 'dart:math';
import '../models/user_model.dart';

class CallService {
  // Ces valeurs doivent être remplacées par vos vraies credentials ZegoCloud
  // https://console.zegocloud.com/
  static const int appId = 123456789; // À REMPLACER
  static const String appSign = 'votre_app_sign_ici'; // À REMPLACER

  /// Génère un ID d'appel unique basé sur deux IDs d'utilisateurs ou un ID de rendez-vous
  static String generateCallId(String id1, String id2) {
    // Trier les IDs pour que l'ID soit le même peu importe qui initie l'appel
    List<String> ids = [id1, id2];
    ids.sort();
    return ids.join('_');
  }

  /// Prépare les paramètres pour ZegoUIKitPrebuiltCall
  static Map<String, dynamic> getCallConfig(UserModel currentUser, String callId) {
    return {
      'appID': appId,
      'appSign': appSign,
      'userID': currentUser.uid,
      'userName': currentUser.name,
      'callID': callId,
    };
  }
}
