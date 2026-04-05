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

  factory AppUser.local({bool isPremium = false}) {
    return AppUser(
      uid: 'local_user',
      email: 'local@example.com',
      displayName: 'Yerel Kullanıcı',
      isPremium: isPremium,
      isAnonymous: true,
    );
  }
}
