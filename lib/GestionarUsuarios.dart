import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'diseñoapp.dart';
import 'package:intl/intl.dart';
import 'dart:async'; 
import 'package:shared_preferences/shared_preferences.dart'; // <--- Importante
//Importaciones y Nombre
class PantallaGestionUsuarios extends StatefulWidget {
  const PantallaGestionUsuarios({super.key});

  @override
  State<PantallaGestionUsuarios> createState() => _PantallaGestionUsuariosState();
}
//Pide el rol de quiien esta iniciando para evitar que paae tenga acceso a admin y directivos
class _PantallaGestionUsuariosState extends State<PantallaGestionUsuarios> {
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  Map<String, List<dynamic>> _usuariosPorRol = {
    'admin': [], 'docente': [], 'alumno': [], 'paae': [], 'directivo': [], 'ss': []
  };
  bool _cargando = true;
  Timer? _timerUsuarios;
  String _miRol = ""; // <--- Para guardar el rol del que está usando la app
//Carga todo el rol // --- CONTROLADORES PARA EL NUEVO ADMIN ---
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidoCtrl = TextEditingController();
  final TextEditingController _usuarioCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _apellidoMCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarMiRolYUsuarios(); // Cargamos rol y usuarios al iniciar
    _timerUsuarios = Timer.periodic(const Duration(seconds: 15), (timer) { 
      if (mounted) {
        _obtenerTodosLosUsuarios();
      }
    });
  }

  // --- NUEVA FUNCIÓN PARA SABER QUIÉN SOY ---
  Future<void> _cargarMiRolYUsuarios() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _miRol = prefs.getString('userRole')?.toLowerCase() ?? "";
    });
    _obtenerTodosLosUsuarios();
  }

  @override
  void dispose() {
    _timerUsuarios?.cancel();
    super.dispose();
  }

  // --- PETICIONES AL SERVIDOR (Se mantienen igual) ---
  Future<void> _obtenerTodosLosUsuarios() async {
    try {
      final response = await http.get(
        Uri.parse('$urlBase/usuarios-todos'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _usuariosPorRol = Map<String, List<dynamic>>.from(json.decode(response.body));
            _cargando = false;
          });
        }
      }
    } catch (e) {
      print("Error obteniendo usuarios: $e");
    }
  }

  // ... (Las funciones _eliminarUsuario y _gestionarServicioSocial se quedan igual)
  Future<void> _eliminarUsuario(String id, String rol) async {
    try {
      final response = await http.delete(Uri.parse('$urlBase/usuarios/$rol/$id'));
      if (response.statusCode == 200) {
        _obtenerTodosLosUsuarios();
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario eliminado del sistema 🗑️")));
      }
    } catch (e) { print("Error al eliminar: $e"); }
  }

  Future<void> _gestionarServicioSocial(String id, bool esAlta) async {
    final ruta = esAlta ? 'promover-ss' : 'degradar-alumno';
    try {
      final response = await http.post(
        Uri.parse('$urlBase/usuarios/$ruta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_usuario': id}),
      );
      if (response.statusCode == 200) {
        _obtenerTodosLosUsuarios();
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(esAlta ? "¡Alta en Servicio Social exitosa! 🎓" : "Baja de Servicio Social realizada 📉")));
      }
    } catch (e) { print("Error en trámite de SS: $e"); }
  }

  // --- INTERFAZ DINÁMICA ---

  @override
  Widget build(BuildContext context) {
    // Si el rol es paae, solo mostramos 3 pestañas. Si no, mostramos las 6.
    bool esPaae = _miRol == "paae";
    int numeroDePestanas = esPaae ? 3 : 6;
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: numeroDePestanas,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
          elevation: 0,
          title: const Text("Control de Usuarios", style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(text: "Alumnos"),
              const Tab(text: "Docentes"),
              if (!esPaae) const Tab(text: "Directivos"), // OCULTAR SI ES PAAE
              if (!esPaae) const Tab(text: "Admins"),      // OCULTAR SI ES PAAE
              if (!esPaae) const Tab(text: "PAAE"),        // OCULTAR SI ES PAAE
              const Tab(text: "S. Social"),
            ],
          ),
        ),
        body: Marcos(
          contenido: TabBarView(
            children: [
              _listaUsuarios('alumno'),
              _listaUsuarios('docente'),
              if (!esPaae) _listaUsuarios('directivo'), // OCULTAR SI ES PAAE
              if (!esPaae) _listaUsuarios('admin'),      // OCULTAR SI ES PAAE
              if (!esPaae) _listaUsuarios('paae'),       // OCULTAR SI ES PAAE
              _listaUsuarios('ss'),
            ],
          ),
        ),
      ),
    );
  }

  // ... (El resto de funciones _listaUsuarios, _mostrarPanelUsuario, etc. se quedan igual)
 Widget _listaUsuarios(String rol) {
    final lista = _usuariosPorRol[rol] ?? [];
    if (_cargando) return const Center(child: CircularProgressIndicator(color: Colors.amber));

    return Column(
      children: [
        // --- BOTÓN EXCLUSIVO PARA DIRECTIVOS EN LA PESTAÑA DE ADMINS ---
        if (rol == 'admin' && _miRol == 'directivo')
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ElevatedButton.icon(
              onPressed: _mostrarDialogoCrearAdmin,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text("Añadir Administrador", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        
        // --- LISTA DE USUARIOS ---
        if (lista.isEmpty) 
          const Expanded(child: Center(child: Text("No hay usuarios activos", style: TextStyle(color: Colors.white54)))),
        
        if (lista.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final user = lista[index];
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    title: Text("${user['nombres']} ${user['apellido_p']}", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("ID: ${user['id_usuario']}", style: const TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.info_outline, color: Colors.amber),
                    onTap: () => _mostrarPanelUsuario(user, rol),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  // Función HTTP para mandar los datos al servidor
  Future<void> _actualizarTurnoUsuario(String id, String rol, String nuevoTurno) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String adminEditor = prefs.getString('userName') ?? "Admin Desconocido";

      final response = await http.put(
        Uri.parse('$urlBase/usuarios/cambiar-turno'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_usuario': id,
          'rol': rol,
          'nuevo_turno': nuevoTurno,
          'admin_editor': adminEditor
        }),
      );

      if (response.statusCode == 200) {
        _obtenerTodosLosUsuarios(); // Recargar la lista completa
        if (mounted) {
          Navigator.pop(context); // Cierra el modal de detalles
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("¡Turno actualizado a $nuevoTurno por $adminEditor! ⏱️"))
          );
        }
      }
    } catch (e) {
      print("Error al cambiar turno: $e");
    }
  }
  // --- FUNCIONES PARA AÑADIR ADMIN ---
  Future<void> _crearAdministradorDirecto() async {
    if (_nombreCtrl.text.isEmpty || _apellidoCtrl.text.isEmpty || _usuarioCtrl.text.isEmpty || _passCtrl.text.isEmpty || _correoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Llena todos los campos necesarios ⚠️")));
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String creador = prefs.getString('userName') ?? "Directivo";

    try {
      final response = await http.post(
        Uri.parse('$urlBase/usuarios/crear-admin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_usuario': _usuarioCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
          'nombres': _nombreCtrl.text.trim(),
          'apellido_p': _apellidoCtrl.text.trim(),
          'apellido_m': _apellidoMCtrl.text.trim(),
          'correo': _correoCtrl.text.trim(),
          'creado_por': creador
        }),
      );

      if (response.statusCode == 200) {
        _obtenerTodosLosUsuarios(); 
        if (mounted) Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Administrador creado con éxito! 🚀")));
        
        _nombreCtrl.clear(); _apellidoCtrl.clear(); _apellidoMCtrl.clear(); 
        _usuarioCtrl.clear(); _passCtrl.clear(); _correoCtrl.clear();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: El ID ya existe.")));
      }
    } catch (e) {
      print("Error al crear admin: $e");
    }
  }

 void _mostrarDialogoCrearAdmin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000033),
        title: const Text("Nuevo Administrador", style: TextStyle(color: Colors.amber)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nombreCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nombre(s)", labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: _apellidoCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Apellido Paterno", labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: _apellidoMCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Apellido Materno", labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: _correoCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Correo Electrónico", labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: _usuarioCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "ID Usuario", labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Contraseña", labelStyle: TextStyle(color: Colors.white54))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: _crearAdministradorDirecto,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text("Crear", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  // Cuadro de diálogo para seleccionar el nuevo turno de forma limpia
  void _mostrarDialogoCambiarTurno(String id, String rol, String turnoActual) {
    String? seleccion = turnoActual;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF000033),
          title: const Text("Modificar Turno", style: TextStyle(color: Colors.white)),
          content: DropdownButtonFormField<String>(
            value: seleccion,
            dropdownColor: const Color(0xFF000033),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: "Selecciona el nuevo turno", labelStyle: TextStyle(color: Colors.amber)),
            items: ['Matutino', 'Vespertino'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setDialogState(() => seleccion = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _actualizarTurnoUsuario(id, rol, seleccion!);
              },
              child: const Text("Guardar", style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      ),
    );
  }
//Esto muestra la informacion del perfil seleccionado
  void _mostrarPanelUsuario(Map user, String rol) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    // Convertimos la fecha fea a una fecha bonita (el truco que implementamos antes)
    String fechaAlta = "No registrada";
    if (user['fecha_aprobacion'] != null) {
      try {
        DateTime dt = DateTime.parse(user['fecha_aprobacion'].toString()).toLocal();
        fechaAlta = DateFormat('dd/MM/yyyy - hh:mm a').format(dt);
      } catch (e) {
        fechaAlta = user['fecha_aprobacion'].toString();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.82, // Le damos un poquito más de altura
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Información de Perfil", style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24, height: 30),
              _datoInfo("Nombre Completo:", "${user['nombres']} ${user['apellido_p']} ${user['apellido_m']}"),
              _datoInfo("ID Usuario:", "${user['id_usuario']}"),
              _datoInfo("Correo:", "${user['correo']}"),
              _datoInfo("Rol actual:", rol.toUpperCase()),
              _datoInfo("Turno asignado:", user['turno'] ?? "Sin Turno"),
              
              // --- NUEVO: HISTORIAL DE CAMBIO DE TURNOS ---
              if (user['turno_anterior'] != null) ...[
                _datoInfo("Turno anterior:", "${user['turno_anterior']}"),
                _datoInfo("Turno editado por:", "${user['editado_por'] ?? 'N/A'}"),
              ],
              
              const SizedBox(height: 20),
              const Text("DATOS DE APROBACIÓN", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              _datoInfo("Aprobado por:", user['aprobado_por'] ?? "Sistema (Manual)"),
              _datoInfo("Fecha de alta:", fechaAlta),
              const SizedBox(height: 30),

              // --- NUEVO BOTÓN PARA CAMBIAR TURNO ---
              _botonAccion("Cambiar Turno del Usuario", Colors.orange.shade800, Icons.edit_calendar, 
                () => _mostrarDialogoCambiarTurno(user['id_usuario'].toString(), rol, user['turno'] ?? 'Matutino')),

              if (rol == 'alumno') 
                _botonAccion("Dar de alta en Servicio Social", Colors.green, Icons.school, 
                  () => _gestionarServicioSocial(user['id_usuario'], true)),
              if (rol == 'ss')
                _botonAccion("Dar de baja en Servicio Social", Colors.orange, Icons.history_edu, 
                  () => _gestionarServicioSocial(user['id_usuario'], false)),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarBorrado(user['id_usuario'], rol),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("ELIMINAR USUARIO TOTALMENTE"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, padding: const EdgeInsets.all(15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
//muestra la info
  Widget _datoInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(valor, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
//Estas son las acciones que se dibujan para ahorrar tiempo
  Widget _botonAccion(String texto, Color color, IconData icono, VoidCallback accion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: accion,
          icon: Icon(icono),
          label: Text(texto),
          style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.8), padding: const EdgeInsets.all(15)),
        ),
      ),
    );
  }
//Esto confirma que se borre el usuario de la BDD
  void _confirmarBorrado(String id, String rol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000033),
        title: const Text("¿Eliminar usuario?", style: TextStyle(color: Colors.white)),
        content: Text("¿Estás seguro de eliminar a $id? Esta acción no se puede deshacer.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => _eliminarUsuario(id, rol), 
            child: const Text("Eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}