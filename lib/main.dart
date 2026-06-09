import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

// --- GESTOR DE SESIÓN (RASP) ---
class SessionManager extends ChangeNotifier {
  Timer? _timer;
  final int _inactivitySeconds = 15; // 15 seg para pruebas
  bool _isSessionExpired = false;

  bool get isSessionExpired => _isSessionExpired;

  void startTimer(BuildContext context) {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: _inactivitySeconds), () {
      _handleLogout(context);
    });
  }

  void resetTimer(BuildContext context) {
    if (!_isSessionExpired && _timer != null) {
      startTimer(context);
    }
  }

  void _handleLogout(BuildContext context) {
    _timer?.cancel();
    _timer = null;
    _isSessionExpired = true;
    notifyListeners();

    // Navegación destructiva al Login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void clearExpiredFlag() {
    _isSessionExpired = false;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['action'] == 'wipe_data') {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seguridad RASP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // --- MONITOREO GLOBAL DE EVENTOS (Requisito A) ---
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => context.read<SessionManager>().resetTimer(context),
          onPointerMove: (_) => context.read<SessionManager>().resetTimer(context),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (_) => context.read<SessionManager>().resetTimer(context),
            child: child!,
          ),
        );
      },
      home: const LoginScreen(),
    );
  }
}

// --- PANTALLA DE LOGIN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Mostrar alerta si venimos de un cierre por inactividad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionManager>();
      if (session.isSessionExpired) {
        _showSessionExpiredDialog();
        session.clearExpiredFlag();
      }
    });
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text("Sesión Expirada"),
          ],
        ),
        content: const Text("Por su seguridad, se ha cerrado la sesión debido a inactividad prolongada."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ENTENDIDO"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("Bienvenido", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const ProtectedHomeScreen()),
                );
              },
              child: const Text("ENTRAR AL ÁREA SEGURA"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA PROTEGIDA (Anteriormente LoginScreen) ---
class ProtectedHomeScreen extends StatefulWidget {
  const ProtectedHomeScreen({super.key});

  @override
  State<ProtectedHomeScreen> createState() => _ProtectedHomeScreenState();
}

class _ProtectedHomeScreenState extends State<ProtectedHomeScreen> {
  static const platform = MethodChannel('com.lyzsolar.login_flutter/security');
  final _storage = const FlutterSecureStorage();
  
  bool _isFakeGPSDetected = false;
  bool _isLoading = true;
  Map<String, String> _sensitiveData = {};

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _verifyGPS();
    await _setupSensitiveData();
    _setupFCM();
    // Iniciar el temporizador al entrar
    if (mounted) {
      context.read<SessionManager>().startTimer(context);
    }
  }

  @override
  void dispose() {
    // Detener temporizador al salir manualmente
    super.dispose();
  }

  void _setupFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data['action'] == 'wipe_data') {
        await _wipeAllData();
      }
    });
  }

  Future<void> _setupSensitiveData() async {
    final all = await _storage.readAll();
    if (all.isEmpty) {
      await _storage.write(key: 'user_token', value: 'secret_tk_123456');
      await _storage.write(key: 'credit_card', value: '4590-1234-5678-0000');
      await _storage.write(key: 'user_pin', value: '9988');
      await _storage.write(key: 'private_key', value: 'rsa_priv_2024_xyz');
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storage.readAll();
    if (mounted) setState(() { _sensitiveData = data; });
  }

  Future<void> _wipeAllData() async {
    await _storage.deleteAll();
    await _loadData();
  }

  Future<void> _verifyGPS() async {
    try {
      final bool isFake = await platform.invokeMethod('isFakeGPS');
      if (mounted) setState(() { _isFakeGPSDetected = isFake; _isLoading = false; });
    } on PlatformException catch (_) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_isFakeGPSDetected) {
      return const Scaffold(body: Center(child: Text("Fake GPS Detectado. Bloqueado.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Área Protegida'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<SessionManager>().stopTimer();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Card(
              color: Colors.amberAccent,
              child: ListTile(
                leading: Icon(Icons.timer_outlined, color: Colors.red),
                title: Text("Control de Inactividad (RASP)"),
                subtitle: Text("La sesión se cerrará en 15 segundos si no hay interacción."),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _sensitiveData.isEmpty
                  ? const Center(child: Text("¡DATOS BORRADOS!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                  : ListView(
                      children: _sensitiveData.entries.map((e) => ListTile(
                        title: Text(e.key),
                        subtitle: Text(e.value),
                        trailing: const Icon(Icons.lock_outline),
                      )).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
