import 'package:flutter/material.dart';
import 'diseñoapp.dart';
import 'login_screen.dart';
import 'Reportar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'VerManuales.dart';

// Importaciones arriba, nombre abajo
class PantallaAlumno extends StatelessWidget {
  const PantallaAlumno({super.key});

  // --- FUNCIÓN PEQUEÑA PARA OBTENER EL NOMBRE ---
  Future<String> _getNombre() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? "Alumno";
  }
  // Esto dibuja toda la pantalla
  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Marcos(
        contenido: FutureBuilder<String>(
          future: _getNombre(), // Llamamos a la función
          builder: (context, snapshot) {
            // Mientras espera el nombre, ponemos un texto genérico o vacío
            String nombreMostrar = snapshot.data ?? "Cargando...";

            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                
                // --- AQUÍ SE MUESTRA EL NOMBRE REAL ---
                Text(
                  "Bienvenido, Alumno: $nombreMostrar", 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(
                    fontSize: 24, 
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                ),
                
                const SizedBox(height: 10),
                const Text(
                  "¿Qué deseas hacer hoy?", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                
                const SizedBox(height: 100), // Espacio para que no se vea amontonado

                _botonMenu(
                  context, 
                  texto: "Hacer un reporte", 
                  destino: const PantallaReporte()
                ),

                const SizedBox(height: 20),

                _botonMenu(
                  context, 
                  texto: "Visualizar Manuales", 
                  destino: const PantallaVerManuales()
                ),

                const SizedBox(height: 20),

                // Botón Cerrar Sesión
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
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
                    child: const Text("Cerrar Sesión"),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget auxiliar para mantener el estilo de los botones
  Widget _botonMenu(BuildContext context, {required String texto, Widget? destino}) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: esOscuro ? null : Colors.red,
        ),
        onPressed: () {
          if (destino != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => destino));
          }
        },
        child: Text(
          texto,
          style: TextStyle(color: esOscuro ? null : Colors.white),
        ),
      ),
    );
  }
}