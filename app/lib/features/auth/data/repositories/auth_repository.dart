import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';
import '../../../../core/utils/helpers.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email/password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    final user = UserModel(
      uid: credential.user!.uid,
      uniqueId: AppHelpers.generateUniqueId(),
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
      settings: UserSettings(),
    );

    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
    return user;
  }

  // Sign in with email/password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    var profile = await getUserProfile();
    
    // If user exists in Auth but not Firestore, create profile
    if (profile == null && currentUser != null) {
      print('DEBUG: Creating missing Firestore profile for ${currentUser!.uid}');
      final user = UserModel(
        uid: currentUser!.uid,
        uniqueId: AppHelpers.generateUniqueId(),
        displayName: currentUser!.displayName ?? 'User',
        email: currentUser!.email ?? email,
        photoUrl: currentUser!.photoURL,
        createdAt: DateTime.now(),
        settings: UserSettings(),
      );
      await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
      profile = user;
    }
    return profile;
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;

    // Check if user already exists
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    // Create new user
    final user = UserModel(
      uid: uid,
      uniqueId: AppHelpers.generateUniqueId(),
      displayName: userCredential.user!.displayName ?? 'User',
      email: userCredential.user!.email ?? '',
      photoUrl: userCredential.user!.photoURL,
      createdAt: DateTime.now(),
      settings: UserSettings(),
    );

    await _firestore.collection('users').doc(uid).set(user.toFirestore());
    return user;
  }

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    if (currentUser == null) return null;
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
  }

  // Find user by unique ID
  Future<UserModel?> findUserByUniqueId(String uniqueId) async {
    final query = await _firestore
        .collection('users')
        .where('uniqueId', isEqualTo: uniqueId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (currentUser == null) return;
    await _firestore.collection('users').doc(currentUser!.uid).delete();
    await currentUser!.delete();
  }
}
