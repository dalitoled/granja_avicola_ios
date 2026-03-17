import 'package:cloud_firestore/cloud_firestore.dart';

class AuthorizationCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> validateCode(String code, String? expectedEmail) async {
    try {
      final snapshot = await _firestore
          .collection('codigos_autorizacion')
          .where('code', isEqualTo: code.toUpperCase())
          .where('used', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      if (data['expiresAt'] != null) {
        DateTime expiresAt = DateTime.parse(data['expiresAt']);
        if (DateTime.now().isAfter(expiresAt)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> markCodeAsUsed(
    String code,
    String userId,
    String farmName,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('codigos_autorizacion')
          .where('code', isEqualTo: code.toUpperCase())
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'used': true,
          'usedBy': userId,
          'farmName': farmName,
          'usedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<bool> isCodeValid(String code) async {
    return validateCode(code, null);
  }

  Future<String> generateCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code;
    bool exists = true;

    do {
      code = '';
      for (int i = 0; i < 8; i++) {
        code += chars[(DateTime.now().microsecond + i * 17) % chars.length];
      }

      final snapshot = await _firestore
          .collection('codigos_autorizacion')
          .where('code', isEqualTo: code)
          .get();

      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    await _firestore.collection('codigos_autorizacion').add({
      'code': code,
      'used': false,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now()
          .add(const Duration(days: 365))
          .toIso8601String(),
    });

    return code;
  }

  Future<List<Map<String, dynamic>>> getAllCodes() async {
    try {
      final snapshot = await _firestore
          .collection('codigos_autorizacion')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createCodeForUser(String email, String ownerName) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code;
    bool exists = true;

    do {
      code = '';
      for (int i = 0; i < 8; i++) {
        code += chars[(DateTime.now().microsecond + i * 17) % chars.length];
      }

      final snapshot = await _firestore
          .collection('codigos_autorizacion')
          .where('code', isEqualTo: code)
          .get();

      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    await _firestore.collection('codigos_autorizacion').add({
      'code': code,
      'used': false,
      'forEmail': email,
      'ownerName': ownerName,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now()
          .add(const Duration(days: 365))
          .toIso8601String(),
    });
  }
}
