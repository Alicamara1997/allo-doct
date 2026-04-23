import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password, String name, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Create user document in Firestore
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          role: role,
          name: name,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        
        // Also create a specific profile document based on role if needed
        if (role == 'practitioner') {
          await _firestore.collection('practitioners').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'specialty': '',
            'city': '',
            'bio': '',
            'isVerified': false,
          });
        } else {
           await _firestore.collection('patients').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
          });
        }
        
        return newUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
         return await getUserData(user.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get User Data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current auth stream
  Stream<User?> get userStream => _auth.authStateChanges();
}
