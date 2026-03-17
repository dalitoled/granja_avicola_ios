import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm_profile_model.dart';
import '../services/farm_service.dart';
import '../services/activation_service.dart';
import '../services/authorization_code_service.dart';

class RegisterFarmScreen extends StatefulWidget {
  const RegisterFarmScreen({super.key});

  @override
  State<RegisterFarmScreen> createState() => _RegisterFarmScreenState();
}

class _RegisterFarmScreenState extends State<RegisterFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _codigoController = TextEditingController();

  final FarmService _farmService = FarmService();
  final ActivationService _activationService = ActivationService();
  final AuthorizationCodeService _authCodeService = AuthorizationCodeService();
  bool _isLoading = false;

  static const String ADMIN_EMAIL = 'danielledezmad9@gmail.com';

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _capacidadController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _registerFarm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email?.toLowerCase() == ADMIN_EMAIL.toLowerCase();

    // Si es el admin, no necesita código
    if (!isAdmin) {
      final codigoIngresado = _codigoController.text.trim().toUpperCase();
      final isValidCode = await _authCodeService.validateCode(
        codigoIngresado,
        null,
      );

      if (!isValidCode) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Código de autorización inválido o ya usado. Contacta al administrador.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // El resto del código de registro
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no autenticado')),
          );
        }
        return;
      }

      final farm = FarmProfileModel(
        id: '',
        userId: user.uid,
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        capacidad: int.tryParse(_capacidadController.text.trim()) ?? 0,
        createdAt: DateTime.now(),
      );

      final farmId = await _farmService.createFarm(farm);

      // Marcar código como usado solo si no es admin
      if (!isAdmin) {
        final codigoIngresado = _codigoController.text.trim().toUpperCase();
        await _authCodeService.markCodeAsUsed(
          codigoIngresado,
          user.uid,
          farm.nombre,
        );
      }

      final existingFarm = await _farmService.getFarmByUserId(user.uid);
      if (existingFarm == null) {
        await _activationService.activateApp(user.uid, farmId);
      }

      if (mounted) {
        _codigoController.clear();
        _nombreController.clear();
        _direccionController.clear();
        _telefonoController.clear();
        _capacidadController.clear();

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Granja "${farm.nombre}" registrada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar la granja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email?.toLowerCase() == ADMIN_EMAIL.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Granja'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 64,
                        color: Color(0xFF2E7D32),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Registrar Nueva Granja',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ingresa el código proporcionado por el administrador',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!isAdmin)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _codigoController,
                            decoration: const InputDecoration(
                              labelText: 'Código de Autorización',
                              hintText: 'Ingresa el código de 8 caracteres',
                              border: InputBorder.none,
                              filled: false,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingrese el código de autorización';
                              }
                              if (value.trim().length != 8) {
                                return 'El código debe tener 8 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Granja',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el nombre de la granja';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacidadController,
                decoration: const InputDecoration(
                  labelText: 'Capacidad (número de gallinas)',
                  prefixIcon: Icon(Icons.egg),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese la capacidad';
                  }
                  final capacidad = int.tryParse(value.trim());
                  if (capacidad == null || capacidad <= 0) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerFarm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Registrar Granja',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nota: Cada código puede ser usado para registrar una granja. Si tienes varias granjas, solicita códigos adicionales al administrador.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
