import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'diseñoapp.dart';
import 'dart:async'; // Para el Timer
import 'package:shared_preferences/shared_preferences.dart'; // Importante para jalar el login
//Importaciones y nombre 
class Registros extends StatefulWidget {
  const Registros({super.key});
  @override
  State<Registros> createState() => _RegistrosState();
}
//hacemos un timer para preguntar constantemente si hay registros nuevos
class _RegistrosState extends State<Registros> {
  Timer? _timerSolicitudes;
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  List<dynamic> _solicitudes = [];
  bool _cargando = true;
//Se obtienen las solicitudes aqui abajo
  @override
  void initState() {
    super.initState();
    _obtenerSolicitudes();
  }
//detiene el timer para no entrar en un bucle
  @override
  void dispose() {
    super.dispose();
  }
//  Este es el metodo para obtener las solicitudes desde el servidor
  Future<void> _obtenerSolicitudes() async {
    try {
      final response = await http.get(
        Uri.parse('$urlBase/solicitudes'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _solicitudes = json.decode(response.body);
            _cargando = false;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // --- LÓGICA DE DECISIÓN CON JALADO DE LOGIN ---
  Future<void> _decidir(Map sol, bool aprobado) async {
    final String id = sol['id_usuario'];
    final String rol = sol['id_rol'];

    try {
      // 1. Jalamos el nombre del Admin desde las preferencias que guardaste en el Login
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String adminResponsable = prefs.getString('userName') ?? "Admin Desconocido";

      if (aprobado) {
        // Enviamos el aprobado_por al Monstruo
        await http.put(
          Uri.parse('$urlBase/solicitudes/aprobar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id_usuario': id, 
            'rol': rol,
            'aprobado_por': adminResponsable // Se guarda en la DB
          }),
        );
      } else {
        await http.delete(Uri.parse('$urlBase/solicitudes/rechazar/$rol/$id'));
      }

      if (mounted) {
        Navigator.pop(context);
        _obtenerSolicitudes(); // Refrescar lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(aprobado ? "¡Aceptado por $adminResponsable!" : "Registro Rechazado"))
        );
      }
    } catch (e) {
      print("Error al procesar: $e");
    }
  }

  // --- INTERFAZ ---
  // --- INTERFAZ ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Marcos(
        contenido: Column(
          children: [
            const SizedBox(height: 40), // Espacio para la barra de estado
            
            // --- NUEVA FILA DE NAVEGACIÓN ---
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 48.0), // Compensa el ancho del botón para centrar
                    child: Text(
                      "Solicitudes de Ingreso", 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22, 
                        color: Colors.white, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            Expanded(
              child: _cargando 
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : RefreshIndicator(
                  onRefresh: _obtenerSolicitudes,
                  color: Colors.amber,
                  backgroundColor: const Color(0xFF000022),
                  child: ListView.builder(
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) {
                      final sol = _solicitudes[index];
                      return Card(
                      color: Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.person, color: Color(0xFF000022))
                        ),
                        title: Text("${sol['nombres']} ${sol['apellido_p']}", style: const TextStyle(color: Colors.white)),
                        subtitle: Text("Rol: ${sol['id_rol']} | ID: ${sol['id_usuario']}", style: const TextStyle(color: Colors.white70)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 16),
                        onTap: () => _verDetalles(sol),
                      ),
                    );
                  },
                ),
            ),
            ),
          ],
        ),
      ),
    );
  }
//Este es el metodo para que al pulsar el boton a una persona nos mande los detallesa junto con su foto y las desiciones que se pueden tomar 
  void _verDetalles(Map sol) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const Text("Revisión de Documento", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 30),
            
            if (sol['foto_url'] != null)
              GestureDetector(
                onTap: () => _abrirImagenGrande(sol['foto_url']),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    '$urlBase${sol['foto_url']}',
                    height: 250, width: double.infinity, fit: BoxFit.cover,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                  ),
                ),
              )
            else
              const Icon(Icons.no_photography, size: 100, color: Colors.grey),

            const SizedBox(height: 20),
            _datoLabel("Nombre:", "${sol['nombres']} ${sol['apellido_p']} ${sol['apellido_m']}"),
            _datoLabel("ID Usuario:", sol['id_usuario']),
            _datoLabel("Rol:", sol['id_rol']),
            _datoLabel("Turno solicitado:", sol['turno'] ?? "No especificado"),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _decidir(sol, false),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                    child: const Text("Rechazar"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _decidir(sol, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade900),
                    child: const Text("Aceptar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
//Esto enseña los datos que mando el usuario
  Widget _datoLabel(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          Expanded(child: Text(valor, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
//Esto abre la imagen de la identificacion
  void _abrirImagenGrande(String url) {
    final completaUrl = url.startsWith('http') ? url : '$urlBase$url';
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              completaUrl, 
              headers: const {'ngrok-skip-browser-warning': 'true'},
            ),
          ),
        ),
      ),
    );
  }
}