import 'package:flutter/material.dart';
import 'main.dart';
class Marcos extends StatelessWidget {
  final Widget contenido; //Final es una variable inmutable donde solo puede asignarse una vez y no puede ser reasignado despues
  final String version;

  const Marcos({super.key, required this.contenido, this.version = "v1.35.2"}); // Este método muestra la versión en toda la app
  //-
 void _mostrarPreferencias(BuildContext context) { /* Este método da las instrucciones del botón inferior izquierdo del engranaje */
    showModalBottomSheet( //Muestra el panel de control
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, //dependiendo el contexto dibuja de un color o otro
      // 1. IMPORTANTE: Evitamos que se rompa el contexto al tocar afuera
      isDismissible: true, 
      shape: const RoundedRectangleBorder( //Controla los bordes del panel
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) { // En caso de que se pulse el botón se cambiará el color de todo
            bool esOscuroActual = temaGlobal.value == ThemeMode.dark;
            // Este es el diseño en general de este apartado del Panel para configurar todo
            return Container(
              padding: const EdgeInsets.all(25), // Los bordes que se tienen
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Configuración", //la palabra Configuracion y abajo o bueno despues de Style se elige la fuente, su tamaño y color
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const SizedBox(height: 20), // Para separar todo usamos este código 
                  SwitchListTile(
                    title: const Text(
                      "¿Activar modo oscuro?", // Este es el título del botón 
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      esOscuroActual ? "El modo oscuro está activo" : "El modo claro está activo", //Esto dice que esta activo usando un : que funciona como un IF
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: Icon( //Esto es la logica que se usa al presionar el boton y cambia de estilos
                      esOscuroActual ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.amber,
                    ),
                    value: esOscuroActual,
                    onChanged: (bool valor) {
                      // 2. Cambiamos el tema
                      setModalState(() {
                        temaGlobal.value = valor ? ThemeMode.dark : ThemeMode.light;
                      });
                     // Esto arregla un bug que había en la app, cierra la pestaña para evitar dobles toques 
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // Esta es la lógica para todo el diseño de la aplicación
  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark; // Si el tema es Oscuro entonces hacer todo oscuro
    Color colorContraste = Colors.white; 

    return Center(
      child: Container( // Esto dibuja el cuadrado que cubre la app que está en todas las pantallas
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: esOscuro ? Colors.black : Colors.white, 
            width: 10,
          ),
        ),
        child: Stack(
          children: [
            // Esto es el nombre para todo el diseño que vamos a usar en todo
            contenido, 
            
            // Esto es para el botón de engranaje
            Positioned(
              bottom: -10, // Ajustado para que pegue al borde como la versión
              left: -10,   // Ajustado a la izquierda
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  size: 20,
                  color: colorContraste.withOpacity(0.5),
                ),
                onPressed: () => _mostrarPreferencias(context),
              ),
            ),

            // Esto dibuja la version
            Positioned(
              bottom: -1, 
              right: 2,  
              child: Text(
                version,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorContraste.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}