import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/authorization_code_service.dart';
import '../models/role_model.dart';
import 'register_farm_screen.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final AuthorizationCodeService _authCodeService = AuthorizationCodeService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const String ADMIN_EMAIL = 'danielledezmad9@gmail.com';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final isSuperAdminEmail = email == ADMIN_EMAIL.toLowerCase();
      
      // CASO 1: Es el SuperAdmin principal
      if (isSuperAdminEmail) {
        await _authService.registerWithEmailAndPassword(
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
          role: AppRole.superAdmin,
          farmId: '',
          createdBy: '',
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RegisterFarmScreen()),
            (route) => false,
          );
        }
        return;
      }

      // CASO 2: Usuario normal (requiere código obligatorio)
      final codeStr = _codeController.text.trim().toUpperCase();

      // Para validar el código necesitamos estar autenticados (reglas de Firestore).
      // 1. Registramos temporalmente al usuario con permisos mínimos para entrar.
      final newUser = await _authService.registerWithEmailAndPassword(
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
        role: AppRole.operador,
        farmId: '',
        createdBy: '',
      );

      if (newUser == null) {
        throw 'No se pudo crear la cuenta de usuario.';
      }

      // 2. Ahora sí estamos autenticados. Procedemos a validar el código.
      final isValidCode = await _authCodeService.validateCode(codeStr, null);

      if (!isValidCode) {
        // El código fue engañoso o bloqueado. PROCEDEMOS A REVERTIR Y BORRAR LA CUENTA:
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).delete();
          await firebaseUser.delete();
          await FirebaseAuth.instance.signOut();
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código de autorización inválido o ya usado.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 3. El código ES VÁLIDO. Obtenemos la granja destino.
      String targetFarmId = '';
      final codeData = await _authCodeService.getCodeData(codeStr);
      if (codeData != null) {
        targetFarmId = codeData['farmId'] ?? '';
      }

      // 4. Actualizamos el perfil del usuario a ADMIN y le asignamos la granja correcta
      await _authService.updateUserRole(newUser.uid, AppRole.admin);
      
      if (targetFarmId.isNotEmpty) {
        await _authService.updateUserFarmId(newUser.uid, targetFarmId);
      }

      // 5. Quemamos/Usamos el código
      await _authCodeService.markCodeAsUsed(
        codeStr,
        newUser.uid,
        _nameController.text.trim(),
        targetFarmId,
      );

      // 6. Redirigimos al usuario victorioso a su nueva vista de control
      if (mounted) {
        if (targetFarmId.isNotEmpty) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          // Fallback por si acaso es un código raro sin granja asignada
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RegisterFarmScreen()),
            (route) => false,
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Registrarse'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_add,
                        size: 60,
                        color: Color(0xFFFF8C00),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su correo';
                          }
                          if (!value.contains('@')) {
                            return 'Ingrese un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirme su contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.key,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Código de activación requerido',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      Text(
                                        'Solicita uno al administrador del sistema',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                labelText: 'Código de Activación',
                                hintText: 'Ej: ABC12345',
                                prefixIcon: const Icon(Icons.key, color: Colors.purple),
                                suffixIcon: _codeController.text.length == 8
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (value) => setState(() {}),
                              validator: (value) {
                                // Se permite omitir solo si es el SuperAdmin principal
                                if (_emailController.text.trim().toLowerCase() == ADMIN_EMAIL.toLowerCase()) {
                                  return null; 
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return 'El código de activación es obligatorio';
                                }
                                if (value.trim().length != 8) {
                                  return 'El código debe tener exactamente 8 caracteres';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Registrarse',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
