import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/activation_service.dart';
import '../services/farm_service.dart';
import '../services/admin_service.dart';
import 'register_farm_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final ActivationService _activationService = ActivationService();
  final FarmService _farmService = FarmService();
  final AdminService _adminService = AdminService();

  static const String ADMIN_EMAIL = 'danielledezmad9@gmail.com';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkExistingFarm();
    });
  }

  Future<void> _checkExistingFarm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    if (user.email?.toLowerCase() == ADMIN_EMAIL.toLowerCase()) {
      await _adminService.addAdmin(user.uid, user.email ?? '');
    }

    final farm = await _farmService.getFarmByUserId(user.uid);
    if (farm != null && mounted) {
      await _activationService.activateApp(user.uid, farm.id);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _navigateToRegisterFarm() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterFarmScreen()))
        .then((_) => _checkExistingFarm());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.agriculture,
                size: 100,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 32),
              Text(
                'Granja Avícola',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bienvenido a tu sistema de gestión avícola',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              const Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 48,
                        color: Color(0xFF2E7D32),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Activación Requerida',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Para comenzar a usar la aplicación, necesitas registrar tu granja.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToRegisterFarm,
                  icon: const Icon(Icons.add_business),
                  label: const Text('Registrar Mi Granja'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
