import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  static const String _activationStatusKey = 'app_activated';
  static const String _farmIdKey = 'farm_id';
  static const String _userIdKey = 'user_id';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isAppActivated(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString(_userIdKey);

    if (storedUserId != userId) {
      await prefs.setBool(_activationStatusKey, false);
      await prefs.remove(_farmIdKey);
      await prefs.setString(_userIdKey, userId);
      return false;
    }

    return prefs.getBool(_activationStatusKey) ?? false;
  }

  Future<String?> getFarmId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString(_userIdKey);

    if (storedUserId != userId) {
      return null;
    }

    return prefs.getString(_farmIdKey);
  }

  Future<void> activateApp(String userId, String farmId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activationStatusKey, true);
    await prefs.setString(_farmIdKey, farmId);
    await prefs.setString(_userIdKey, userId);

    await _firestore.collection('activaciones').add({
      'userId': userId,
      'farmId': farmId,
      'activatedAt': DateTime.now().toIso8601String(),
      'status': 'active',
    });
  }

  Future<void> deactivateApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activationStatusKey, false);
    await prefs.remove(_farmIdKey);
  }

  Future<bool> checkActivationInFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activaciones')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      final querySnapshot = await _firestore.collection('activaciones').get();
      final filtered = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['userId'] == userId && data['status'] == 'active';
      });
      return filtered.isNotEmpty;
    }
  }
}
