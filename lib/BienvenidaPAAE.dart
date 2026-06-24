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

class PantallaPAAE extends StatelessWidget {
  const PantallaPAAE({super.key});

  // Función para obtener el nombre del personal PAAE.
  Future<String> _getNombre() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? "Personal PAAE";
  }

  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Marcos(
        contenido: FutureBuilder<String>(
          future: _getNombre(),
          builder: (context, snapshot) {
            String nombreMostrar = snapshot.data ?? "Cargando...";

            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    "Bienvenido, PAAE: $nombreMostrar", 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(
                      fontSize: 24, 
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "¿Qué deseas realizar?", 
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  
                  const SizedBox(height: 60), 

                  _botonPAAE(
                    context, 
                    texto: "Gestionar Reportes", 
                    icono: Icons.assignment_turned_in,
                    destino: const PantallaGestReportes()
                  ),
                  
                  const SizedBox(height: 15),

                  _botonPAAE(
                    context, 
                    texto: "Visualizar Manuales", 
                    icono: Icons.menu_book,
                    destino: const PantallaVerManuales()
                  ),
                  
                  const SizedBox(height: 15),
                  _botonPAAE(
                    context, 
                    texto: "Gestionar Manuales", 
                    icono: Icons.edit_document,
                    destino: const PantallaGestionarManuales()
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _botonPAAE(
                    context, 
                    texto: "Gestionar Asistencia", 
                    icono: Icons.fact_check,
                    destino: const PantallaAsistencia()
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _botonPAAE(
                    context, 
                    texto: "Gestionar Registros", 
                    icono: Icons.app_registration,
                    destino: const Registros()
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _botonPAAE(
                    context, 
                    texto: "Gestionar Usuarios", 
                    icono: Icons.supervised_user_circle,
                    destino: const PantallaGestionUsuarios()
                  ),

                  const SizedBox(height: 15),

                  _botonPAAE(
                    context, 
                    texto: "Visualizar Estadísticas", 
                    icono: Icons.analytics,
                    destino: const PantallaEstadisticas()
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Botón de Cerrar Sesión.
                  SizedBox(
                    width: 250,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esOscuro ? null : Colors.red.shade900,
                        foregroundColor: esOscuro ? null : Colors.white,
                      ),
                      onPressed: () async { 
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context, 
                            MaterialPageRoute(builder: (context) => const PantallaLogin()), 
                            (Route<dynamic> route) => false
                          );
                        }
                      }, 
                      icon: Icon(Icons.exit_to_app, color: esOscuro ? null : Colors.white),
                      label: const Text("Cerrar Sesión"),
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

  // Widget para botones de PAAE con iconos personalizados.
  Widget _botonPAAE(BuildContext context, {required String texto, required IconData icono, required Widget destino}) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: esOscuro ? null : Colors.red,
        ),
        child: Text(
          texto,
          style: TextStyle(color: esOscuro ? null : Colors.white),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destino));
        },
      ),
    );
  }
}
