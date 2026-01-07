import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    try {
      print('🔐 Signing in with email: $email');
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        print('✅ Sign in successful, UID: ${result.user!.uid}');
        print('🔧 Running _ensurePublicIdMapping...');
        await _ensurePublicIdMapping(result.user!.uid);
        print('✅ _ensurePublicIdMapping completed');
      }
      return result.user;
    } catch (e) {
      print('❌ Sign in error: $e');
      return null;
    }
  }

  Future<User?> signUp(String email, String password, String name) async {
    try {
      print('📝 Starting registration for email: $email');
      print('📝 Display name: $name');
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      print('✅ Firebase Auth user created: ${result.user?.uid}');
      
      User? user = result.user;
      if (user != null) {
        print('📝 Creating user profile in database...');
        await _createUserProfile(user.uid, name, email);
        print('✅ User profile created successfully');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code}');
      print('❌ Error message: ${e.message}');
      
      // Log specific error codes
      if (e.code == 'email-already-in-use') {
        print('❌ Email already registered');
      } else if (e.code == 'invalid-email') {
        print('❌ Invalid email format');
      } else if (e.code == 'weak-password') {
        print('❌ Password too weak');
      } else if (e.code == 'operation-not-allowed') {
        print('❌ Email/Password sign in not enabled in Firebase Console');
      }
      
      return null;
    } catch (e) {
      print('❌ Unexpected error during sign up: $e');
      print('❌ Error type: ${e.runtimeType}');
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      if (user != null) {
        // Check if user exists in DB, if not create
        final snapshot = await _db.ref('users/${user.uid}').get();
        if (!snapshot.exists) {
          await _createUserProfile(user.uid, user.displayName ?? "User", user.email ?? "");
        } else {
          // Ensure publicId mapping exists for existing users
          await _ensurePublicIdMapping(user.uid);
        }
      }
      return user;
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  // Ensure publicId mapping exists for a user
  Future<void> _ensurePublicIdMapping(String uid) async {
    try {
      final userSnap = await _db.ref('users/$uid').get();
      
      // If user profile doesn't exist, recreate it
      if (!userSnap.exists || userSnap.value == null) {
        print('⚠️ User profile missing for $uid, recreating...');
        
        // Get user info from Firebase Auth
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          // Create new user profile
          await _createUserProfile(
            uid,
            currentUser.displayName ?? 'User',
            currentUser.email ?? '',
          );
          print('✅ User profile recreated for $uid');
        }
        return;
      }
      
      // User exists, ensure publicId mapping
      final userData = userSnap.value as Map;
      final publicId = userData['publicId']?.toString();
      
      if (publicId != null && publicId.isNotEmpty) {
        // Check if mapping exists
        final mappingSnap = await _db.ref('publicIds/$publicId').get();
        if (!mappingSnap.exists) {
          // Create the mapping
          await _db.ref('publicIds/$publicId').set(uid);
          print('✅ Created publicId mapping: $publicId -> $uid');
        }
      } else {
        // User exists but has no publicId, create one
        print('⚠️ User has no publicId, creating...');
        String newPublicId = await _generateUniquePublicId();
        await _db.ref('users/$uid/publicId').set(newPublicId);
        await _db.ref('publicIds/$newPublicId').set(uid);
        print('✅ Created new publicId: $newPublicId for $uid');
      }
    } catch (e) {
      print('Error ensuring publicId mapping: $e');
    }
  }

  Future<void> _createUserProfile(String uid, String name, String email) async {
    String publicId = await _generateUniquePublicId();
    UserModel newUser = UserModel(
      uid: uid,
      publicId: publicId,
      name: name,
      email: email,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      online: true,
    );
    await _db.ref('users/$uid').set(newUser.toMap());
    // Index publicId for easy lookup
    await _db.ref('publicIds/$publicId').set(uid);
  }

  Future<String> _generateUniquePublicId() async {
    while (true) {
      String id = (Random().nextInt(90000) + 10000).toString();
      final snapshot = await _db.ref('publicIds/$id').get();
      if (!snapshot.exists) {
        return id;
      }
    }
  }

  Future<void> signOut() async {
    await _db.ref('users/${_auth.currentUser?.uid}/online').set(false);
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<UserModel?> getCurrentUserModel() async {
    User? user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _db.ref('users/${user.uid}').get();
    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.value as Map);
    }
    return null;
  }
}
