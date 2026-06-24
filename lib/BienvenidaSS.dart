import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
import 'diseñoapp.dart';
import 'package:udi_connect/SSReportes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udi_connect/login_screen.dart';
import 'VerManuales.dart';

class PantallaSS extends StatefulWidget {
  const PantallaSS({super.key});

  @override
  State<PantallaSS> createState() => _PantallaSSState();
}

class _PantallaSSState extends State<PantallaSS> {
  bool _estaBloqueado = true; 
  bool _cargando = true;      
  String _mensajeBloqueo = "Verificando tu asistencia...";
  String _nombreUsuario = "Cargando..."; // <--- Variable para el nombre.
  Timer? _timerVigilante; 
  
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();

    // --- CONFIGURAMOS EL VIGILANTE ---
    _timerVigilante = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _verificarAcceso(mostrarCargando: false);
      }
    });
  }

  // Nueva función para cargar nombre y verificar acceso al inicio.
  Future<void> _inicializarPantalla() async {
    await _cargarNombre();
    await _verificarAcceso(mostrarCargando: true);
  }

  Future<void> _cargarNombre() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nombreUsuario = prefs.getString('userName') ?? "Servicio Social";
      });
    }
  }

  @override
  void dispose() {
    _timerVigilante?.cancel();
    super.dispose();
  }

  Future<void> _verificarAcceso({required bool mostrarCargando}) async {
    if (mostrarCargando) setState(() => _cargando = true);
    
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? miId = prefs.getString('userKey');

      if (miId == null) return;

      final response = await http.get(
        Uri.parse('$urlBase/asistencia/estado/$miId'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            _estaBloqueado = data['acceso'] == 'bloqueado';
            _mensajeBloqueo = data['mensaje'] ?? "Acceso restringido.";
            _cargando = false;
          });
        }
      }
    } catch (e) {
      print("Error en vigilante de acceso: $e");
      if (mostrarCargando) {
        setState(() {
          _mensajeBloqueo = "Error de conexión con el servidor.";
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Marcos(
        contenido: _cargando 
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _estaBloqueado 
            ? _interfazBloqueo() 
            : _interfazNormal(),
      ),
    );
  }

  Widget _interfazBloqueo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_person_rounded, size: 100, color: Colors.amber),
        const SizedBox(height: 20),
        const Text(
          "ACCESO RESTRINGIDO",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _mensajeBloqueo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 50),
        ElevatedButton.icon(
          onPressed: () => _verificarAcceso(mostrarCargando: true),
          icon: const Icon(Icons.refresh),
          label: const Text("REINTENTAR ACCESO"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: _cerrarSesionLocal,
          child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _interfazNormal() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        // --- AQUÍ APARECE EL NOMBRE REAL ---
        Text(
          "Bienvenido, $_nombreUsuario", 
          textAlign: TextAlign.center, 
          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 20),
        const Text("¿Qué deseas hacer hoy?", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white70)),
        const SizedBox(height: 100),
        
        _botonMenu("Gestionar Reportes", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaGestReportesSS()));
        }),
        
        const SizedBox(height: 20),
        
        _botonMenu("Visualizar Manuales", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaVerManuales()));
        }),
        
        const SizedBox(height: 20),
        
        _botonMenu("Cerrar Sesión", _cerrarSesionLocal),
      ],
    );
  }

  Widget _botonMenu(String texto, VoidCallback accion) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: esOscuro ? null : Colors.red,
        ),
        onPressed: accion,
        child: Text(texto, style: TextStyle(color: esOscuro ? null : Colors.white)),
      ),
    );
  }

  Future<void> _cerrarSesionLocal() async {
    _timerVigilante?.cancel(); 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const PantallaLogin()), 
        (Route<dynamic> route) => false
      );
    }
  }
}