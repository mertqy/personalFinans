import 'dart:async';

class AuthService {
  // Simple singleton for the mock
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _authStateController = StreamController<String?>.broadcast();
  String? _currentUser;
  bool _isAnonymous = false;

  String? get currentUser => _currentUser;
  bool get isAnonymous => _isAnonymous;
  Stream<String?> get authStateChanges => _authStateController.stream;


  // Mock Anonymous Sign-In
  Future<String?> signInAnonymously() async {
    _currentUser = 'local_user';
    _isAnonymous = true;
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  // Sign Out
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }
}
