import 'package:flutter/material.dart';
import 'package:udi_connect/GestionarUsuarios.dart';
import 'package:udi_connect/GestionRegistros.dart';
import 'package:udi_connect/Gestionar Reportes.dart';
import 'package:udi_connect/GestionarManuales.dart';
import 'package:udi_connect/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diseñoapp.dart';
import 'Asistencia.dart';
import 'Estadisticas.dart';
import 'VerManuales.dart';
// Las importaciones a las pantallas arriba y 
class PantallaAdmin extends StatelessWidget {
  const PantallaAdmin({super.key});

  // Función para obtener tu nombre del servidor
  Future<String> _getNombre() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? "admin01";
  }
  // Esta es la parte visual de la pantalla
  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Marcos(
        contenido: FutureBuilder<String>(
          future: _getNombre(), // Este muestra el nombre de tu perfil 
          builder: (context, snapshot) {
            String nombreMostrar = snapshot.data ?? "Cargando...";

            return SingleChildScrollView( // Para que quepan todos los botones usamos SingleChildScrollView
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    "Bienvenido Administrador, $nombreMostrar", // Como es administrador le damos la bienvenida y después mostramos el nombre
                    textAlign: TextAlign.center, 
                    style: const TextStyle(
                      fontSize: 24, 
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Panel de Control Maestro",  // Solo un texto que dice de qué es ese menú
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  
                  const SizedBox(height: 50), // Bajamos el espacio para que se vea bien el diseño
                  // Aquí empiezan los botones para las pantallas, se llaman desde el método de hasta abajo 
                  _botonAdmin(
                    context, 
                    texto: "Gestionar Reportes", 
                    
                    destino: const PantallaGestReportes()
                  ),

                  const SizedBox(height: 15),

                  _botonAdmin(
                    context, 
                    texto: "Visualizar Manuales", 
                    destino: const PantallaVerManuales()
                  ),

                  const SizedBox(height: 15),

                  _botonAdmin(
                    context, 
                    texto: "Gestionar Manuales", 
                    
                    destino: const PantallaGestionarManuales()
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _botonAdmin(
                    context, 
                    texto: "Gestionar Asistencia",                
                    destino: const PantallaAsistencia()
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _botonAdmin(
                    context, 
                    texto: "Gestionar Registros", 
                    destino: const Registros()
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _botonAdmin(
                    context, 
                    texto: "Gestionar Usuarios", 
          
                    destino: const PantallaGestionUsuarios()
                  ),

                  const SizedBox(height: 15),

                  _botonAdmin(
                    context, 
                    texto: "Visualizar Estadísticas", 
          
                    destino: const PantallaEstadisticas()
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Botón Cerrar Sesión
                  SizedBox(
                    width: 250,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.logout, color: esOscuro ? null : Colors.white),
                      label: const Text("Cerrar Sesión"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esOscuro ? null : Colors.red.shade900,
                        foregroundColor: esOscuro ? null : Colors.white,
                      ),
                      onPressed: () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        // No borramos los términos, solo la sesión
                        await prefs.remove('isLoggedIn');
                        await prefs.remove('userName');
                        await prefs.remove('userRole');
                        await prefs.remove('userKey');
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context, 
                            MaterialPageRoute(builder: (context) => const PantallaLogin()), 
                            (Route<dynamic> route) => false
                          );
                        }
                      }, 
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Este es un Widget que dibuja los botones dependiendo de qué estés pulsando
Widget _botonAdmin(BuildContext context, {required String texto, required Widget destino}) {
  bool esOscuro = Theme.of(context).brightness == Brightness.dark;
  return SizedBox(
    width: 280,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: esOscuro ? null : Colors.red,
      ),
      // 1. Quitamos el .icon y usamos el constructor normal
      // 2. El texto ahora va dentro de 'child' en lugar de 'label'
      child: Text(
        texto, 
        style: TextStyle(
          fontSize: 16,
          color: esOscuro ? null : Colors.white,
        )
      ),
      onPressed: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => destino)
      ),
    ),
  );
}
}