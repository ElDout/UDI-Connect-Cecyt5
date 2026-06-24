import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'diseñoapp.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Importamos y damos nombre a la pantalla
class PantallaAsistencia extends StatefulWidget {
  const PantallaAsistencia({super.key});
  @override
  State<PantallaAsistencia> createState() => _PantallaAsistenciaState();
}

// Acá abajo va toda la lógica de asistencias
class _PantallaAsistenciaState extends State<PantallaAsistencia> {
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  List<dynamic> _usuariosSS = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerUsuariosSS();
  } // Llamamos a la función de obtener usuarios de servicio social

  Future<void> _obtenerUsuariosSS() async { // Esta función se conecta al servidor para pedirle los usuarios SS
    try {
      final response = await http.get(
        Uri.parse('$urlBase/usuarios-todos'), 
        headers: {'ngrok-skip-browser-warning': 'true'}
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _usuariosSS = decoded is Map ? (decoded['ss'] ?? []) : decoded;
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

// Esta lógica dibuja el menú de las asistencias
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Marcos(
        contenido: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text("Control de Asistencias", 
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _cargando 
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : ListView.builder(
                    itemCount: _usuariosSS.length,
                    itemBuilder: (context, index) {
                      final user = _usuariosSS[index];
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.amber, 
                            child: Icon(Icons.person, color: Color(0xFF000022))),
                          title: Text("${user['nombres']} ${user['apellido_p']}", style: const TextStyle(color: Colors.white)),
                          
                          // --- AQUÍ ESTÁ EL CAMBIO: Se agregó la columna para el ID y el Turno ---
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ID: ${user['id_usuario']}", style: const TextStyle(color: Colors.white70)),
                              Text("Turno: ${user['turno'] ?? 'No especificado'}", 
                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          // ------------------------------------------------------------------------

                          onTap: () => _consultarEstadoYMenu(user),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

// Este método consulta el historial
  void _consultarEstadoYMenu(Map user) async {
    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));
    try {
      final response = await http.get(
        Uri.parse('$urlBase/asistencia/hoy/${user['id_usuario']}'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      Navigator.pop(context);
      final registroHoy = (response.body == "null" || response.body.isEmpty) ? null : json.decode(response.body);
      _mostrarMenuAcciones(user, registroHoy);
    } catch (e) {
      Navigator.pop(context);
    }
  }

// Este método muestra toda la tarjeta con un menú pequeño para saber si darle asistencia y reportar salida
  void _mostrarMenuAcciones(Map user, dynamic registroHoy) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: 380,
        child: Column(
          children: [
            Text(user['nombres'], style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 30),
            _botonMenu(context, "Marcar Entrada", Icons.login, Colors.green, () {
              Navigator.pop(context);
              _marcarTiempo(user['id_usuario'], 'entrada');
            }),
            const SizedBox(height: 10),
            _botonMenu(context, "Marcar Retiro", Icons.logout, Colors.orange, () {
              Navigator.pop(context);
              _marcarTiempo(user['id_usuario'], 'salida');
            }),
            const SizedBox(height: 10),
            _botonMenu(context, "Historial de Asistencias", Icons.history, Colors.amber, () {
              Navigator.pop(context);
              _verHistorial(user);
            }),
          ],
        ),
      ),
    );
  }

// Esto es lo que activa el menú 
  Widget _botonMenu(BuildContext context, String texto, IconData icono, Color color, VoidCallback tap) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icono, color: color),
      title: Text(texto, style: const TextStyle(color: Colors.white)),
      onTap: tap,
      tileColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

// Le marca el tiempo a la base de datos y la muestra en el historial
  Future<void> _marcarTiempo(String id, String tipo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String adminActual = prefs.getString('userName') ?? "Admin";

    final response = await http.post(
      Uri.parse('$urlBase/asistencia/registrar'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'id_usuario': id, 'tipo': tipo, 'responsable': adminActual}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${tipo.toUpperCase()} registrada ✅")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al registrar ❌")));
    }
  }
  
  //Esto enseña la tarjeta para mostrar el historial
  void _verHistorial(Map user) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Historial - ${user['nombres']}", style: const TextStyle(color: Colors.amber, fontSize: 18)),
            const Divider(color: Colors.white24),
            Expanded(
              child: FutureBuilder(
                future: http.get(
                  Uri.parse('$urlBase/asistencia/historial/${user['id_usuario']}'),
                  headers: {'ngrok-skip-browser-warning': 'true'}
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  
                  List logs = json.decode(snapshot.data!.body);
                  if (logs.isEmpty) return const Center(child: Text("Sin registros", style: TextStyle(color: Colors.white54)));

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final item = logs[index];
                      return Card(
                        color: Colors.white10,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: Icon(
                            item['tipo'] == 'ENTRADA' ? Icons.login : Icons.logout,
                            color: item['tipo'] == 'ENTRADA' ? Colors.green : Colors.orange,
                          ),
                          title: Text("${item['tipo']} - ${item['hora']}", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Fecha: ${item['fecha'].toString().split('T')[0]}", style: const TextStyle(color: Colors.white70)),
                              Text("Responsable: ${item['responsable']}", style: const TextStyle(color: Colors.amber, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}