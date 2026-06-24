import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'login_screen.dart'; 
import 'BienvenidaAdmin.dart';
import 'BienvenidaAlumno.dart';
import 'BienvenidaDirectivo.dart';
import 'BienvenidaDocente.dart';
import 'BienvenidaPAAE.dart';
import 'BienvenidaSS.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

// --- 1. SWITCH GLOBAL DE TEMA ---
// Lo ponemos aquí afuera para que el widget Marcos lo pueda ver
ValueNotifier<ThemeMode> temaGlobal = ValueNotifier(ThemeMode.dark);
final GlobalKey<ScaffoldMessengerState> mensajeroGlobalKey = GlobalKey<ScaffoldMessengerState>();
void main() async {
  // 1. Esto prepara el motor de Flutter SIEMPRE, sin importar si es Web o Android
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Aquí aplicamos la lógica: solo inicializa Firebase si NO estamos en la Web
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // 3. Ahora sí, arranca tu app. ¡Listo!
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 2. ENVOLVEMOS CON EL ESCUCHADOR ---
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaGlobal,
      builder: (context, modoActual, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          
          // Mantenemos tus colores exactos
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFF800000), // Guinda
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFF000033), // Azul Marino
            brightness: Brightness.dark,
          ),
          scaffoldMessengerKey: mensajeroGlobalKey,
          // --- 3. APLICAMOS EL MODO ACTUAL ---
          themeMode: modoActual, 

          home: const VerificadorSesion(), 
        );
      },
    );
  }
}

//Esto chequea la sesion y que sesion tenia antes para guardarlo e iniciar esa sesion sin tener que pasar por la pantalla de inicio de sesion primero
class VerificadorSesion extends StatefulWidget {
  const VerificadorSesion({super.key});

  @override
  State<VerificadorSesion> createState() => _VerificadorSesionState();
}

class _VerificadorSesionState extends State<VerificadorSesion> {
  @override
  void initState() {
    super.initState();
    
    _checarSesion();
  }

  Future<void> _checarSesion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool estaLogueado = prefs.getBool('isLoggedIn') ?? false;
    final String? rol = prefs.getString('userRole');

    print("--- CHEQUEO DE SESIÓN ---");
    print("¿isLoggedIn en disco?: $estaLogueado");
    print("Rol guardado: $rol");

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (estaLogueado && rol != null && rol.isNotEmpty) {
      _navegarSegunRol(rol);
    } else {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const PantallaLogin())
      );
    }
  }
  //Navega por la app segun el rol, valida los roles y manda a las pantallas dependiendo de los roles
  void _navegarSegunRol(String rol) {
    Widget pantallaDestino;
    switch (rol.toLowerCase()) {
      case "admin":
      case "administradores":
        pantallaDestino = const PantallaAdmin();
        break;
      case "alumno":
      case "alumnos":
        pantallaDestino = const PantallaAlumno();
        break;
      case "docente":
      case "docentes":
        pantallaDestino = const PantallaDocente();
        break;
      case "directivo":
      case "directivos":
        pantallaDestino = const PantallaDirectivo();
        break;
      case "paae":
        pantallaDestino = const PantallaPAAE();
        break;
     case "servicio social":
case "ss":
case "servicio_social":
case "serviciosocial": // Por si el Monstruo lo manda pegado
  pantallaDestino = const PantallaSS();
  break;
      default:
        pantallaDestino = const PantallaLogin();
    }

    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => pantallaDestino)
    );
  }
//Construlle toda la app
  @override
  Widget build(BuildContext context) {
    return const PantallaPresentacion();
  }
}