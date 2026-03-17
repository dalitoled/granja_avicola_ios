import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
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
