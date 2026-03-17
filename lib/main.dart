import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/activation_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/activation_service.dart';
import 'services/farm_service.dart';
import 'services/admin_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GranjaAvicolaApp());
}

class GranjaAvicolaApp extends StatelessWidget {
  const GranjaAvicolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Granja Avícola',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final ActivationService _activationService = ActivationService();
  final FarmService _farmService = FarmService();
  final AdminService _adminService = AdminService();

  static const String ADMIN_EMAIL = 'danielledezmad9@gmail.com';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          _checkAndSetAdmin(snapshot.data!);

          return FutureBuilder<bool>(
            future: _checkIfShouldShowDashboard(snapshot.data!.uid),
            builder: (context, activationSnapshot) {
              if (activationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final shouldShowDashboard = activationSnapshot.data ?? false;

              if (shouldShowDashboard) {
                return const DashboardScreen();
              } else {
                return const ActivationScreen();
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }

  Future<void> _checkAndSetAdmin(User user) async {
    if (user.email?.toLowerCase() == ADMIN_EMAIL.toLowerCase()) {
      await _adminService.addAdmin(user.uid, user.email ?? '');
    }
  }

  Future<bool> _checkIfShouldShowDashboard(String userId) async {
    final farm = await _farmService.getFarmByUserId(userId);

    if (farm != null) {
      final isActivated = await _activationService.isAppActivated(userId);
      if (!isActivated) {
        await _activationService.activateApp(userId, farm.id);
      }
      return true;
    }

    return false;
  }
}
