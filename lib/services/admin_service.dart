import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> addAdmin(String userId, String email) async {
    await _firestore.collection('admins').doc(userId).set({
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeAdmin(String userId) async {
    await _firestore.collection('admins').doc(userId).delete();
  }

  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }
}
