import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'diseñoapp.dart';
import 'BienvenidaAdmin.dart';
import 'BienvenidaAlumno.dart';
import 'BienvenidaDirectivo.dart';
import 'BienvenidaDocente.dart';
import 'BienvenidaPAAE.dart';
import 'BienvenidaSS.dart';
import 'notificacion_service.dart';
import 'package:flutter/foundation.dart';
import 'Recuperar.dart';
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});
  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  bool _oscurecer = true;
  final TextEditingController _controladorUsuario = TextEditingController(); // Agregamos variables para controlar el Usuario
  final TextEditingController _controladorPassword = TextEditingController(); // Controlar contraseña
  String _errorLog = ""; // Esto es para los errores

  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev'; // Abrimos la url hacia Ngrok
  @override
  void initState() {
    super.initState();
    _verificarTerminos();
  }
  Future<void> _verificarTerminos() async {
    final prefs = await SharedPreferences.getInstance();
    // Revisa si ya los aceptó antes. Si es null, devuelve false.
    bool aceptados = prefs.getBool('terminosAceptados') ?? false;

    if (!aceptados) {
      // Espera un milisegundo a que cargue la pantalla y lanza el cuadro
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarCuadroTerminos();
      });
    }
  }
  void _mostrarCuadroTerminos() {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false, // OBLIGA al usuario a picar un botón, no puede cerrarlo tocando afuera
      builder: (context) => AlertDialog(
        backgroundColor: esOscuro ? const Color(0xFF000022) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield, color: Colors.amber, size: 30),
            const SizedBox(width: 10),
            Expanded(child: Text("Términos y Privacidad", style: TextStyle(color: esOscuro ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Antes de usar UDI Connect, debes aceptar nuestros términos de uso y el aviso de privacidad de tus datos.",
              style: TextStyle(color: esOscuro ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.5))
              ),
              child: const Text(
                "🔒 Tus contraseñas están encriptadas.\n📷 Las fotos solo se usan para reportes.\n🚫 El mal uso causará baja del sistema.",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            // AQUÍ PUEDEN LEER EL TEXTO COMPLETO
            InkWell(
              onTap: () {
                // Aquí podrías poner un url_launcher hacia tu Google Docs, 
                // o para no complicarte, lanzar otro cuadro de diálogo con todo el texto largo.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Visita: bit.ly/terminos-udiconnect para leer el documento completo.")));
              },
              child: const Text(
                "Leer Términos y Condiciones completos",
                style: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        actions: [
          // Botón de Rechazar (Saca al usuario de la app)
          TextButton(
            onPressed: () {
               // Si no acepta, no puede usar la app.
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes aceptar los términos para usar la app.")));
            },
            child: const Text("Rechazar", style: TextStyle(color: Colors.red)),
          ),
          // Botón de Aceptar
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              // 1. Guarda en la memoria que ya aceptó para que no vuelva a salir
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('terminosAceptados', true);
              
              // 2. Cierra el cuadro
              if (mounted) Navigator.pop(context);
            },
            child: const Text("ACEPTAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  Future<void> iniciarSesion() async { // Este es un método de iniciar sesión
    final usuario = _controladorUsuario.text.trim(); // Declaramos los input que se van a escribir y decimos que deben ser igual a los controladores
    final password = _controladorPassword.text.trim();
    if (!kIsWeb) {
  await NotificacionService().inicializar();
}
    // Si las contraseñas o los usuarios están vacíos entonces pide llenar los campos 
    if (usuario.isEmpty || password.isEmpty) {
      setState(() { _errorLog = "Por favor, llena todos los campos"; });
      return;
    }
    // Esto es un try para evitar errores por si no funciona el servidor
    try {
      final response = await http.post(
        Uri.parse('$urlBase/login'), // Conectándose al servidor va a mandar una pregunta sobre si está el usuario en la base de datos
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'id_usuario': usuario,
          'password': password,
        }),
      );
      // Si la respuesta es 200, entonces se abren las puertas y se es enviado a la respectiva pantalla
      if (response.statusCode == 200) {
        final Map<String, dynamic> respuesta = json.decode(response.body);
        final user = respuesta['user'];
        

        // --- AQUÍ GUARDAMOS LA SESIÓN ---
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true); // <--- esto mantiene la sesión iniciada si es que el usuario salió de ella
        await prefs.setString('userName', user['nombres'] ?? 'Usuario');
        await prefs.setString('userRole', user['id_rol']);
        await prefs.setString('userKey', user['id_usuario'].toString());
        await NotificacionService().inicializar();
        if (mounted) _navegarSegunRol(user['id_rol']);
        // Si la respuesta fue 401 entonces manda credenciales incorrectas
      } else if (response.statusCode == 401) {
        setState(() { _errorLog = "Credenciales incorrectas"; });
      } else { // Y si no es ninguno entonces es un error del servidor
        setState(() { _errorLog = "Error en el servidor: ${response.statusCode}"; });
      }
    } catch (e) { // Esto enseña el error detallado y donde fue el error
      print("Error detallado: $e");
      setState(() { _errorLog = "Error de conexión con el servidor"; });
    }
  }
  // Este método navega según el rol, se usa switch con case
  void _navegarSegunRol(String rol) {
    switch (rol.toLowerCase()) {
      case "admin":
      case "administradores":
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaAdmin()));
        break;
      case "alumno":
      case "alumnos":
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaAlumno()));
        break;
      case "docente":
      case "docentes":
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaDocente()));
        break;
      case "directivo":
      case "directivos":
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaDirectivo()));
        break;
      case "paae":
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaPAAE()));
        break;
      case "servicio social":
      case "ss":
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PantallaSS()));
        break;
      default:
        setState(() { _errorLog = "Rol no reconocido: $rol"; });
    }
  }
  // --- Método para las notas de los parches que se agreguen ---
  void _mostrarNotasParche(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000022), // Fondo oscuro para que combine
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Notas del Parche - v1.35.2", 
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("• BIENVENIDO A UDI CONNECT v1.35.2", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 10),
              Text("• Se añadieron notificaciones", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 10),
              Text("• Bienvenido a UDI Connect", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
  // Esto dibuja toda la pantalla 
  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Marcos( // Se llama a diseño con Marcos que es todo el diseño en general ahorrando tiempo 
        contenido: Column( // este es el contenido que va dentro del cuadro 
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text("Bienvenido a UDI CONNECT", // Damos la bienvenida
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 100),
            TextField(
              controller: _controladorUsuario, // Esto es el input para el Login
              style: TextStyle(color: esOscuro ? Colors.white : Colors.black),
              decoration: InputDecoration(
                  labelText: "No. Boleta o ID de trabajador", 
                  filled: true, 
                  fillColor: esOscuro ? Colors.black : Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controladorPassword, // Este es el input de la contraseña
              style: TextStyle(color: esOscuro ? Colors.white : Colors.black),
              obscureText: _oscurecer,
              decoration: InputDecoration(
                labelText: "Contraseña",
                filled: true,
                fillColor: esOscuro ? Colors.black : Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(_oscurecer ? Icons.visibility : Icons.visibility_off),
                  onPressed: () { setState(() { _oscurecer = !_oscurecer; }); },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(_errorLog, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: iniciarSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: esOscuro ? null : Colors.red,
              ),
              child: Text(
                "Iniciar Sesión",
                style: TextStyle(
                  color: esOscuro ? const Color.fromARGB(255, 196, 80, 180) : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaRegistro())); // Al pulsar el texto de Registrarse nos manda a otra pantalla 
              },
              child: const Text("¿No tienes una cuenta? ¡Regístrate aquí!", style: TextStyle(color: Color(0xFFFFD700))),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaRecuperar()));
              },
              child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(color: Color.fromARGB(255, 12, 255, 243))),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => _mostrarNotasParche(context), // Llama a la función de _mostrarNotasParche para el texto
              child: const Text(
                "Ver notas del parche", 
                style: TextStyle(
                  color: Colors.white54, 
                  fontSize: 12, 
                  decoration: TextDecoration.underline // Subrayado para que parezca link
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}