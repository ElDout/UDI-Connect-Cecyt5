import 'package:flutter/material.dart';
import 'package:udi_connect/GestionarUsuarios.dart';
import 'package:udi_connect/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diseñoapp.dart';
import 'Reportar.dart';
import 'Estadisticas.dart';
import 'VerManuales.dart';

class PantallaDirectivo extends StatelessWidget {
  const PantallaDirectivo({super.key});

  // Función para obtener el nombre del Directivo.
  Future<String> _getNombre() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? "Directivo";
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
                  "Bienvenido, Directiv@: $nombreMostrar", 
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
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  
                  const SizedBox(height: 100),

                  _botonDirectivo(
                    context, 
                    texto: "Hacer un reporte", 
                    icono: Icons.edit_note,
                    destino: const PantallaReporte()
                  ),
                  
                  const SizedBox(height: 20),

                  _botonDirectivo(
                    context, 
                    texto: "Visualizar Manuales", 
                    icono: Icons.menu_book,
                    destino: const PantallaVerManuales()
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _botonDirectivo(
                    context, 
                    texto: "Gestionar Usuarios", 
                    icono: Icons.manage_accounts,
                    destino: const PantallaGestionUsuarios()
                  ),

                  const SizedBox(height: 20),

                  _botonDirectivo(
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
                    icon: Icon(Icons.logout, color: esOscuro ? null : Colors.white),
                      label: const Text("Cerrar Sesión"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: esOscuro ? null : Colors.red.shade900,
                      foregroundColor: esOscuro ? null : Colors.white,
                    ),
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

  // Widget para botones de directivo estandarizados.
  Widget _botonDirectivo(BuildContext context, {required String texto, required IconData icono, required Widget destino}) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: esOscuro ? null : Colors.red,
        ),
        // 1. Usamos el constructor normal 'ElevatedButton' en lugar de '.icon'.
        // 2. Cambiamos 'label' por 'child'.
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