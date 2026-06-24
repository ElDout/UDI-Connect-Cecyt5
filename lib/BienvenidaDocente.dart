import 'package:flutter/material.dart';
import 'diseñoapp.dart';
import 'login_screen.dart';
import 'Reportar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'VerManuales.dart';

class PantallaDocente extends StatelessWidget {
  const PantallaDocente({super.key});

  // Función para obtener el nombre del docente.
  Future<String> _getNombre() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? "Docente";
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

            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                
                // Texto de bienvenida con nombre dinámico.
                Text(
                  "Bienvenido, Docente: $nombreMostrar", 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(
                    fontSize: 24, 
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  ),
                ),
                
                const SizedBox(height: 10),
                const Text(
                  "¿En qué podemos apoyarle hoy?", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                
                const SizedBox(height: 100),

                _botonDocente(
                  context, 
                  texto: "Hacer un reporte", 
                  destino: const PantallaReporte()
                ),

                const SizedBox(height: 20),

                _botonDocente(
                  context, 
                  texto: "Visualizar Manuales", 
                  destino: const PantallaVerManuales()
                ),

                const SizedBox(height: 20),

                // Botón de Cerrar Sesión.
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
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

  // Widget auxiliar para botones estéticos.
  Widget _botonDocente(BuildContext context, {required String texto, Widget? destino}) {
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
      if (destino != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destino));
      }
    },
  ),
);
}
}