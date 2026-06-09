import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Manejador de mensajes en segundo plano (Requisito de FCM)
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
  
  // Configurar el manejador de segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seguridad Avanzada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    await _setupSensitiveData(); // 4 Campos Sensibles
    _setupFCM(); // Escucha de Wipe Remoto
  }

  // Configura FCM para recibir la orden de borrado
  void _setupFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data['action'] == 'wipe_data') {
        await _wipeAllData();
        _showWipeNotification();
      }
    });

    // Imprime el token para poder enviar la notificación específica a este dispositivo
    FirebaseMessaging.instance.getToken().then((token) {
      print("------------------------------------------");
      print("FCM TOKEN PARA PRUEBAS: $token");
      print("------------------------------------------");
    });
  }

  // Crear 4 campos sensibles si el almacenamiento está vacío
  Future<void> _setupSensitiveData() async {
    final all = await _storage.readAll();
    if (all.isEmpty) {
      await _storage.write(key: 'user_token', value: 'secret_tk_123456');
      await _storage.write(key: 'credit_card', value: '4590-1234-5678-0000');
      await _storage.write(key: 'private_key', value: 'rsa_priv_2024_xyz');
      await _storage.write(key: 'user_pin', value: '9988');
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storage.readAll();
    setState(() {
      _sensitiveData = data;
    });
  }

  Future<void> _wipeAllData() async {
    await _storage.deleteAll();
    await _loadData();
  }

  void _showWipeNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🚨 DATOS ELIMINADOS REMOTAMENTE"),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _verifyGPS() async {
    try {
      final bool isFake = await platform.invokeMethod('isFakeGPS');
      setState(() {
        _isFakeGPSDetected = isFake;
        _isLoading = false;
      });
    } on PlatformException catch (_) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_isFakeGPSDetected) {
      return Scaffold(
        backgroundColor: Colors.red.shade50,
        body: const Center(child: Text("Bloqueado: Fake GPS Detectado")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protección de Datos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.shield, color: Colors.blue),
                title: Text("Almacenamiento Seguro Activo"),
                subtitle: Text("Datos sensibles protegidos por hardware"),
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
            if (_sensitiveData.isEmpty)
              ElevatedButton(onPressed: _setupSensitiveData, child: const Text("Reiniciar Datos"))
          ],
        ),
      ),
    );
  }
}
