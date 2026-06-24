import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // <-- Necesario para el temporizador
import 'diseñoapp.dart';

class PantallaRecuperar extends StatefulWidget {
  const PantallaRecuperar({super.key});

  @override
  State<PantallaRecuperar> createState() => _PantallaRecuperarState();
}

class _PantallaRecuperarState extends State<PantallaRecuperar> {
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
    final TextEditingController _controladorUsuario = TextEditingController(); // Agregamos variables para controlar el Usuario
  final TextEditingController _controladorPassword = TextEditingController();
  bool _codigoEnviado = false;
  bool _cargando = false;
  String _mensajeError = "";
  bool _oscurecerPassword = true;

  // Variables para el temporizador
  Timer? _timerReenvio;
  int _segundosRestantes = 0;

  // Controladores
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  @override
  void dispose() {
    _timerReenvio?.cancel(); // Apagamos el timer si el usuario sale de la pantalla
    super.dispose();
  }

  void _iniciarTemporizador() {
    setState(() => _segundosRestantes = 60);
    _timerReenvio?.cancel();
    _timerReenvio = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_segundosRestantes > 0) {
            _segundosRestantes--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  // 1. Pedir Código al Servidor
  Future<void> _solicitarCodigo() async {
    if (_idCtrl.text.isEmpty) {
      setState(() => _mensajeError = "Ingresa tu No. Boleta / ID");
      return;
    }

    setState(() { _cargando = true; _mensajeError = ""; });

    try {
      final response = await http.post(
        Uri.parse('$urlBase/solicitar-recuperacion'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'id_usuario': _idCtrl.text.trim()}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() => _codigoEnviado = true);
        _iniciarTemporizador(); // Iniciamos la cuenta regresiva de 60s
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código enviado a tu correo 📧")));
        }
      } else {
        setState(() => _mensajeError = data['message'] ?? "Error desconocido");
      }
    } catch (e) {
      setState(() => _mensajeError = "Error de conexión con el servidor");
    } finally {
      setState(() => _cargando = false);
    }
  }

  // 2. Enviar Nueva Contraseña
  Future<void> _cambiarPassword() async {
    if (_codigoCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _mensajeError = "Llena el código y tu nueva contraseña");
      return;
    }

    setState(() { _cargando = true; _mensajeError = ""; });

    try {
      final response = await http.post(
        Uri.parse('$urlBase/resetear-password'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({
          'id_usuario': _idCtrl.text.trim(),
          'codigo': _codigoCtrl.text.trim(),
          'nueva_password': _passCtrl.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Contraseña actualizada con éxito! 🔐")));
          Navigator.pop(context); // Regresa al Login
        }
      } else {
        setState(() => _mensajeError = data['message'] ?? "Código incorrecto");
      }
    } catch (e) {
      setState(() => _mensajeError = "Error de conexión");
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      extendBodyBehindAppBar: true,
      body: Marcos(
        contenido: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text("Recuperar Contraseña", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            if (!_codigoEnviado) ...[
              const Text("Ingresa tu ID o Boleta. Enviaremos un código a tu correo institucional.", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              TextField(
                controller: _idCtrl,
                style: TextStyle(color: esOscuro ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: "No. Boleta o ID", filled: true, fillColor: esOscuro ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 20),
              _cargando 
                ? const CircularProgressIndicator(color: Colors.amber)
                : ElevatedButton(
                    onPressed: _solicitarCodigo,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 50)),
                    child: const Text("ENVIAR CÓDIGO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
            ] else ...[
              const Text("Revisa tu correo. Ingresa el código de 6 dígitos y tu nueva contraseña.", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              TextField(
                controller: _codigoCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: esOscuro ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: "Código de 6 dígitos", filled: true, fillColor: esOscuro ? Colors.black : Colors.white),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passCtrl,
                obscureText: _oscurecerPassword,
                style: TextStyle(color: esOscuro ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Nueva Contraseña",
                  filled: true,
                  fillColor: esOscuro ? Colors.black : Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_oscurecerPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _oscurecerPassword = !_oscurecerPassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _cargando 
                ? const CircularProgressIndicator(color: Colors.amber)
                : ElevatedButton(
                    onPressed: _cambiarPassword,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                    child: const Text("CAMBIAR CONTRASEÑA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              
              // --- NUEVO: BOTÓN DE REENVIAR CÓDIGO ---
              const SizedBox(height: 15),
              TextButton(
                onPressed: _segundosRestantes == 0 && !_cargando ? _solicitarCodigo : null,
                child: Text(
                  _segundosRestantes > 0 
                    ? "Reenviar código en ${_segundosRestantes}s" 
                    : "¿No te llegó? Reenviar código",
                  style: TextStyle(
                    color: _segundosRestantes > 0 ? Colors.grey : Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Text(_mensajeError, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}