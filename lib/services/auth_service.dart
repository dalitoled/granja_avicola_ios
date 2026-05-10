import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserModel>> getUsersByFarm(String farmId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('farmId', isEqualTo: farmId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene todos los usuarios creados por un administrador específico y bajo la misma granja.
  /// Lanza excepción si Firestore devuelve un error (p.ej. permission-denied).
  Future<List<UserModel>> getUsersByCreator(String creatorUid, String farmId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('farmId', isEqualTo: farmId)
        .where('createdBy', isEqualTo: creatorUid)
        .get();

    final users = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Ordenar en cliente para evitar requerir índice compuesto en Firestore
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return users;
  }

  Future<void> updateUserFarmId(String userId, String farmId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'farmId': farmId,
      });
    } catch (e) {
      throw 'Error al asociar usuario a granja';
    }
  }

  /// Asigna el campo [createdBy] a todos los usuarios que lo tengan vacío
  /// y pertenezcan a la misma granja del [claimerUid].
  /// Útil para migrar usuarios creados antes de que se implementara el campo createdBy.
  Future<int> claimOrphanUsers({
    required String claimerUid,
    required String farmId,
    String excludeUid = '',
  }) async {
    try {
      // Buscar usuarios sin createdBy en la misma granja
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('farmId', isEqualTo: farmId)
          .where('createdBy', isEqualTo: '')
          .get();

      final batch = _firestore.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        if (doc.id == claimerUid || doc.id == excludeUid) continue;
        batch.update(doc.reference, {'createdBy': claimerUid});
        count++;
      }

      if (count > 0) await batch.commit();
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    AppRole role = AppRole.operador,
    String farmId = '',
    String createdBy = '',
    bool useSecondaryApp = false,
  }) async {
    try {
      UserCredential userCredential;
      FirebaseApp? tempApp;

      if (useSecondaryApp) {
        tempApp = await Firebase.initializeApp(
          name: 'TemporaryRegisterApp_${DateTime.now().millisecondsSinceEpoch}',
          options: Firebase.app().options,
        );
        userCredential = await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(email: email, password: password);
      } else {
        userCredential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);
      }

      User? user = userCredential.user;

      if (tempApp != null) {
        await tempApp.delete();
      }

      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
          role: role,
          isActive: true,
          farmId: farmId,
          createdBy: createdBy,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _getAuthExceptionMessage(e.code);
    }
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _getAuthExceptionMessage(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envía un correo de restablecimiento de contraseña estándar web.
  /// No requiere configuración manual de enlaces móviles (ni Dynamic Links ni Hosting).
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Al no enviar ActionCodeSettings, Firebase usa su página web predeterminada para el reseteo.
      // El usuario abrirá el enlace en su navegador, cambiará la contraseña ahí,
      // y luego regresará manualmente a la app para iniciar sesión.
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getAuthExceptionMessage(e.code);
    }
  }

  Future<void> updateUserRole(String userId, AppRole newRole) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'role': RolePermissions.roleToString(newRole),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Error al actualizar el rol del usuario';
    }
  }

  Future<void> toggleUserActive(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw 'Error al cambiar el estado del usuario';
    }
  }

  String _getAuthExceptionMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'El correo electrónico ya está en uso';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'user-disabled':
        return 'El usuario ha sido deshabilitado';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Ocurrió un error. Por favor intente de nuevo';
    }
  }
}
