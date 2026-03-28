import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isPremium;
  final bool isAnonymous;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isPremium = false,
    this.isAnonymous = false,
  });

  factory AppUser.fromFirebaseUser(User user, {bool isPremium = false}) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isPremium: isPremium,
      isAnonymous: user.isAnonymous,
    );
  }
}
