import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _usernameKey = 'username';

  /// Validates user credentials from the 'security_register' collection.
  Future<bool> login(String username, String password) async {
    try {
      final querySnapshot = await _firestore
          .collection('security_register')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await saveSession(username);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Saves the user session to local storage
  Future<void> saveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_usernameKey, username);
  }

  /// Clears the user session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_usernameKey);
  }

  /// Checks if a user is already logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Fetches all users from the security_register collection
  Future<List<Map<String, dynamic>>> getOperators() async {
    try {
      final snapshot = await _firestore.collection('security_register').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching operators: $e');
      return [];
    }
  }

  /// Fetches a specific user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final snapshot = await _firestore
          .collection('security_register')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  /// Gets the currently logged in username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Updates the FCM token for the current user in Firestore
  Future<void> updateFcmToken(String token) async {
    final username = await getUsername();
    if (username == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('security_register')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}
