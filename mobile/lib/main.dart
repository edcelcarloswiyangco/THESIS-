import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'STRAYCONNECT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F7),
        useMaterial3: true,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isBootstrapping = true;
  bool _showRegister = false;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storedBaseUrl = await ApiConfig.loadBaseUrl();

    if (!mounted) {
      return;
    }

    setState(() {
      _authService = AuthService(
        apiService: ApiService(baseUrl: storedBaseUrl),
      );
    });

    await _authService.restoreSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _isBootstrapping = false;
    });
  }

  Future<void> _handleAuthenticated() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _showRegister = false;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    setState(() {
      _showRegister = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUser = _authService.currentUser;

    if (currentUser != null) {
      return HomeScreen(
        user: currentUser,
        authService: _authService,
        onLogout: _handleLogout,
      );
    }

    if (_showRegister) {
      return RegisterScreen(
        authService: _authService,
        onSwitchToLogin: () => setState(() {
          _showRegister = false;
        }),
        onAuthenticated: _handleAuthenticated,
      );
    }

    return LoginScreen(
      authService: _authService,
      onSwitchToRegister: () => setState(() {
        _showRegister = true;
      }),
      onAuthenticated: _handleAuthenticated,
    );
  }
}
