import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  AppRole? get currentRole => _user?.role;
  String get currentFarmId => _user?.farmId ?? '';

  bool hasPermission(String permission) {
    return _user?.hasPermission(permission) ?? false;
  }

  bool get canManageUsers => hasPermission(Permission.manageUsers);
  bool get canGenerateCodes => hasPermission(Permission.generateCodes);
  bool get canAccessSystemConfig => hasPermission(Permission.systemConfig);
  bool get canManageLots => hasPermission(Permission.manageLots);
  bool get canManageProduction => hasPermission(Permission.manageEggProduction);
  bool get canManageSales => hasPermission(Permission.manageEggSales);
  bool get canManageFeed => hasPermission(Permission.manageFeedConsumption);
  bool get canManageExpenses => hasPermission(Permission.manageExpenses);
  bool get canViewReports => hasPermission(Permission.viewReports);
  bool get canManageInventory => hasPermission(Permission.manageInventory);
  bool get canManageHealth => hasPermission(Permission.manageHealth);
  bool get canManageVaccination => hasPermission(Permission.manageVaccination);
  bool get canManageMortality => hasPermission(Permission.manageMortality);

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? firebaseUser = await _authService.getCurrentUser();
      if (firebaseUser != null) {
        _user = await _authService.getUserById(firebaseUser.uid);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (_user != null && !_user!.isActive) {
        _error = 'Usuario desactivado. Contacte al administrador.';
        _user = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    AppRole role = AppRole.operador,
    String farmId = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isLoggedInAlready = _user != null;
      final newUser = await _authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        role: role,
        farmId: farmId,
        createdBy: _user?.uid ?? '',
        useSecondaryApp: isLoggedInAlready,
      );
      
      if (!isLoggedInAlready) {
        _user = newUser;
      }
      
      _isLoading = false;
      notifyListeners();
      return newUser != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateUserRole(String userId, AppRole newRole) async {
    await _authService.updateUserRole(userId, newRole);
    if (_user?.uid == userId) {
      _user = _user!.copyWith(role: newRole);
      notifyListeners();
    }
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    await _authService.toggleUserActive(userId, isActive);
    if (_user?.uid == userId) {
      _user = _user!.copyWith(isActive: isActive);
      notifyListeners();
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    return await _authService.getAllUsers();
  }

  Future<List<UserModel>> getUsersByFarm(String farmId) async {
    return await _authService.getUsersByFarm(farmId);
  }

  Future<List<UserModel>> getUsersByCreator(String creatorUid, String farmId) async {
    return await _authService.getUsersByCreator(creatorUid, farmId);
  }

  /// Reclama usuarios sin `createdBy` en la misma granja, asignándoles
  /// el UID del usuario actual como creador. Devuelve el número de usuarios migrados.
  Future<int> claimOrphanUsers() async {
    if (_user == null) return 0;
    return await _authService.claimOrphanUsers(
      claimerUid: _user!.uid,
      farmId: _user!.farmId,
      excludeUid: _user!.uid,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
