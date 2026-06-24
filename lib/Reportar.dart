import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'diseñoapp.dart';
import 'Encuesta.dart';
import 'package:url_launcher/url_launcher.dart';
// Importaciones y nombre de pantalla
class PantallaReporte extends StatefulWidget {
  const PantallaReporte({super.key});
  @override
  State<PantallaReporte> createState() => _PantallaReporteState();
}
//Conexion al servidor
class _PantallaReporteState extends State<PantallaReporte> {
  File? _foto1, _foto2, _video;
  String? _tipoProblema;
  String? _ubicacion;
  final TextEditingController _controladorDescripcion = TextEditingController();
  final picker = ImagePicker();
  
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  final List<String> salones = [
    "Salon 101",
    "Salon 102",
    "Salon 103",
    "Salon 104",
    "Salon 105",
    "Salon 106",
    "Salon 107",
    "Salon 108",
    "Salon 109",
    "Salon 110",
    "Salon 111",
    "Salon 112",
    "Salon 113",
    "Salon 201",
    "Salon 202",
    "Salon 203",
    "Salon 204",
    "Salon 205",
    "Salon 206",
    "Salon 207",
    "Salon 208",
    "Salon 209",
    "Salon 210",
    "Salon 211",
    "Salon 212",
    "Salon 301",
    "Salon 302",
    "Salon 303",
    "Salon 304",
    "Salon 305",
    "Salon 306",
    "Salon 307",
    "Salon 308",
    "Salon 309",
    "Salon 310",
    "Salon 311",
    "Salon 312",
    "Laboratorio 1",
    "Laboratorio 2",
    "Laboratorio 3",
    "Laboratorio 4",
    "Laboratorio 5",
    "Laboratorio 6",
    "Aula interactiva de Inglés",
    "Laboratorio Ingles 2",
    "Laboratorio de Paqueteria Contable 1",
    "Paqueteria Contable 2",
    //PB
    "Salon de Usos Multiples",
    "Anexo a la biblioteca",
    "Papeleria",
    "Auditorio",
    "Biblioteca",
    "Servicios Academicos",
    "Servicios Estudiantiles",
    "Orientacion Juvenil",
    "Computacion básica",
    "Servicio Medico",
    "Deportivas",
    "Autoacceso",
    "UPIS",
    "Cubículos de área basica",
    "Extensión y apoyos educativos",
    "Rol de género",
    //P1
    "Siglo XXI",
    "Basicas",
    "Tecnológicas",
    "Subdireccion Academica",
    //P2
    "Caja",
    "Subdireccion Administrativa",
    "Cubículos de humanisticas",
    "Direccion académica"

  ];
  // --- FUNCIÓN PARA MOSTRAR EL MENÚ DORADO ---
  void _mostrarPendientesCalificar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String idUsuario = prefs.getString('userKey') ?? "";
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => FutureBuilder<http.Response>(
        // !!! AQUÍ ESTÁ EL ARREGLO: AGREGAMOS HEADERS !!!
        future: http.get(
          Uri.parse('$urlBase/reportes/usuario/$idUsuario'), 
          headers: {
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text("Error al conectar con el servidor", style: TextStyle(color: Colors.white70)));
          }
          
          try {
            List<dynamic> todosMisReportes = json.decode(snapshot.data!.body);
            
            // FILTRO: Solo los "Resueltos" que NO tengan puntuación todavía
            List<dynamic> pendientes = todosMisReportes.where((r) => 
              r['estado'] == 'Resuelto' && (r['puntuacion'] == null)
            ).toList();

            if (pendientes.isEmpty) {
              return Center(child: Text("No tienes reportes pendientes de calificar ✅", style: TextStyle(color: esOscuro ? const Color.fromARGB(179, 228, 59, 59) : Colors.black54)));
            }

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Calificar Reportes Finalizados", style: TextStyle(color: esOscuro ? Colors.amber : const Color.fromARGB(255, 255, 255, 255), fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: pendientes.length,
                    itemBuilder: (context, index) {
                      final rep = pendientes[index];
                      return Card(
                        color: Colors.white10,
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.star_half, color: Colors.amber),
                          title: Text(rep['tipo'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "ID: ${rep['id_reporte']} - Finalizado", 
                            style: TextStyle(color: esOscuro ? Colors.white54 : Colors.yellow)
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 15),
                          onTap: () {
                            Navigator.pop(context); 
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => Encuesta(idReporte: rep['id_reporte'].toString()))
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } catch (e) {
            return const Center(child: Text("Error procesando datos del servidor", style: TextStyle(color: Colors.white70)));
          }
        },
      ),
    );
  }

  void _mostrarHistorialReportes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String idUsuario = prefs.getString('userKey') ?? "";
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse('$urlBase/reportes/usuario/$idUsuario'), 
            headers: {
              'ngrok-skip-browser-warning': 'true',
              'Content-Type': 'application/json',
            },
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.statusCode != 200) {
              return const Center(child: Text("Error al cargar historial", style: TextStyle(color: Colors.white70)));
            }
            try {
              List<dynamic> todosMisReportes = json.decode(snapshot.data!.body);
              if (todosMisReportes.isEmpty) {
                return Center(child: Text("No has hecho ningún reporte aún.", style: TextStyle(color: esOscuro ? Colors.white70 : Colors.black54)));
              }
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("Mi Historial de Reportes", style: TextStyle(color: esOscuro ? Colors.amber : const Color.fromARGB(255, 255, 255, 255), fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: todosMisReportes.length,
                      itemBuilder: (context, index) {
                        final rep = todosMisReportes[index];
                        final resueltoPorNombre = rep['resuelto_por_nombre'] ?? 'Sin asignar';
                        final resueltoPorRol = rep['resuelto_por_rol'] ?? '';
                        final estado = rep['estado'] ?? 'Desconocido';
                        return Card(
                          color: Colors.white10,
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              estado == 'Resuelto' ? Icons.check_circle : Icons.access_time, 
                              color: estado == 'Resuelto' ? (esOscuro ? Colors.green : Colors.yellow) : Colors.amber
                            ),
                            title: Text("${rep['tipo']} - $estado", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              "ID: ${rep['id_reporte']}\nResuelto por: $resueltoPorNombre $resueltoPorRol", 
                              style: TextStyle(color: esOscuro ? Colors.white70 : Colors.yellow)
                            ),
                            onTap: () {
                              _mostrarDetalleReporteHistorial(rep); // Corregido el nombre a historial
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } catch (e) {
              return const Center(child: Text("Error procesando datos", style: TextStyle(color: Colors.white70)));
            }
          },
        ),
      ),
    );
  }

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
              fit: BoxFit.contain,
              headers: const {'ngrok-skip-browser-warning': 'true'},
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniaturaFoto(String url) {
    final completaUrl = url.startsWith('http') ? url : '$urlBase$url';
    return GestureDetector(
      onTap: () => _abrirImagenGrande(completaUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          completaUrl,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          headers: const {'ngrok-skip-browser-warning': 'true'},
        ),
      ),
    );
  }

  Widget _datoLabel(String label, String valor) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(valor, style: TextStyle(color: esOscuro ? Colors.white70 : Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> canalPuedeLanzar(Uri url) async {
    return await canLaunchUrl(url);
  }

  void _mostrarDetalleReporteHistorial(Map rep) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    String estado = rep['estado'] ?? 'Pendiente';
    String tiempo = "Aún no se resuelve";
    
    if (estado == 'Resuelto' || estado == 'Completado' || estado == 'Finalizado') {
       if (rep['fecha'] != null && rep['fecha_resolucion'] != null) {
          try {
             DateTime fechaInicio = DateTime.parse(rep['fecha'].toString());
             DateTime fechaFin = DateTime.parse(rep['fecha_resolucion'].toString());
             Duration diferencia = fechaFin.difference(fechaInicio);
             
             int dias = diferencia.inDays;
             int horas = diferencia.inHours % 24;
             int minutos = diferencia.inMinutes % 60;
             
             List<String> partes = [];
             if (dias > 0) partes.add("$dias días");
             if (horas > 0) partes.add("$horas horas");
             if (minutos > 0) partes.add("$minutos minutos");
             
             if (partes.isEmpty) {
                 tiempo = "Menos de un minuto";
             } else {
                 tiempo = partes.join(", ");
             }
          } catch(e) {
             tiempo = "Tiempo no calculable";
          }
       } else {
          tiempo = "Información de fechas incompleta";
       }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.88,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Reporte #${rep['id_reporte']} - ${rep['tipo']}", style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24, height: 30),

              Text(
                "Estado: $estado", 
                style: TextStyle(
                  color: estado == 'Resuelto' || estado == 'Completado' || estado == 'Finalizado' 
                    ? (esOscuro ? Colors.green : Colors.yellow) 
                    : Colors.amber, 
                  fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),

              if (rep['puntuacion'] != null) ...[
                const Text("Tu calificación del servicio:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (rep['puntuacion'] as int) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    );
                  }),
                ),
                const SizedBox(height: 15),
              ],
              if (rep['resena'] != null && rep['resena'].toString().isNotEmpty) ...[
                const Text("Tu opinión:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10)
                  ),
                  child: Text(
                    "${rep['resena']}", 
                    style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 25),
              ],

              if (rep['foto_solucion1'] != null || rep['foto_solucion2'] != null) ...[
                const Text("Evidencia de la solución:", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (rep['foto_solucion1'] != null) _miniaturaFoto(rep['foto_solucion1']),
                    if (rep['foto_solucion2'] != null) _miniaturaFoto(rep['foto_solucion2']),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (rep['descripcion_solucion'] != null && rep['descripcion_solucion'].toString().isNotEmpty) ...[
                _datoLabel("Descripción Solución:", "${rep['descripcion_solucion']}"),
                const SizedBox(height: 20),
              ],

              if (rep['foto1'] != null || rep['foto2'] != null) ...[
                const Text("Tu evidencia fotográfica:", style: TextStyle(color: Colors.amber)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (rep['foto1'] != null) _miniaturaFoto(rep['foto1']),
                    if (rep['foto2'] != null) _miniaturaFoto(rep['foto2']),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (rep['video'] != null && rep['video'].toString().isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text("Tu Evidencia en Video:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 40),
                    title: const Text("Reproducir Video de Evidencia", style: TextStyle(color: Colors.white)),
                    subtitle: const Text("Se abrirá en el navegador o reproductor externo", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () async {
                      final videoUrl = rep['video'].toString().startsWith('http') 
                          ? rep['video'] 
                          : '$urlBase${rep['video']}';
                          
                      final uri = Uri.parse(videoUrl);
                      
                      if (await canalPuedeLanzar(uri)) {
                        await launchUrl(
                          uri, 
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No se pudo abrir el video ❌"))
                        );
                      }
                    },
                  ),
                ),
              ],

              const SizedBox(height: 10),
              _datoLabel("Tipo de Falla:", "${rep['tipo']}"),
              _datoLabel("Fecha de envío:", "${rep['fecha'] ?? 'Desconocida'}"),
              
              if (rep['resuelto_por_nombre'] != null) ...[
                _datoLabel("Atendido por:", "${rep['resuelto_por_nombre']} (${rep['resuelto_por_rol'] ?? 'Sin rol'})"),
              ] else if (rep['asignado_a'] != null && rep['asignado_a'] != 0) ...[
                _datoLabel("Asignado a:", "En proceso por el área técnica"),
              ],
              
              const SizedBox(height: 20),
              const Text("Tu Descripción original:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              Text("${rep['descripcion']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
              
              const SizedBox(height: 20),
              if (estado == 'Resuelto' || estado == 'Completado' || estado == 'Finalizado') 
                 Text("Se tardó en completar:\n$tiempo", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (estado != 'Resuelto' && estado != 'Completado' && estado != 'Finalizado')
                 Text("El reporte todavía está pendiente, trabajando en ello...", style: TextStyle(color: esOscuro ? Colors.white70 : Colors.white)),
                 
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cerrar", 
                    style: TextStyle(color: esOscuro ? Colors.amber : Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Estas son funciones para capturar las fotos que manda el que reporta
  Future<void> _capturar(String tipo) async {
    XFile? temp;
    if (tipo == 'foto1' || tipo == 'foto2') {
      temp = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Comprime la imagen a la mitad de calidad (ni se nota)
        maxWidth: 1080,   // Nadie necesita resolución 4K para un reporte de una PC
        maxHeight: 1080,
      );
    }
    // if (tipo == 'foto1') temp = await picker.pickImage(source: ImageSource.camera);
    // if (tipo == 'foto2') temp = await picker.pickImage(source: ImageSource.camera);
    if (tipo == 'video') {
      temp = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30), // Limita el video a 30 segundos
      );
    }
    // if (tipo == 'video') temp = await picker.pickVideo(source: ImageSource.camera);

    if (temp != null) {
      setState(() {
        if (tipo == 'foto1') _foto1 = File(temp!.path);
        if (tipo == 'foto2') _foto2 = File(temp!.path);
        if (tipo == 'video') _video = File(temp!.path);
      });
    }
  }

  Future<void> _enviarReporte() async { //Esto envia reportes
    if (_controladorDescripcion.text.isEmpty || _tipoProblema == null || _ubicacion == null || _foto1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta descripción, tipo, ubicación o foto 1")));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idUsuario = prefs.getString('userKey');
      String? nombreUsuario = prefs.getString('userName');
      String? rolUsuario = prefs.getString('userRole');
      
      var request = http.MultipartRequest('POST', Uri.parse('$urlBase/enviar-reporte'));
      
      // HEADER PARA NGROK AQUÍ TAMBIÉN 
      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});

      request.fields['id_usuario'] = idUsuario ?? "Anonimo";
      request.fields['nombre_usuario'] = nombreUsuario ?? "Desconocido";
      request.fields['rol_usuario'] = rolUsuario ?? "Sin rol";
      request.fields['tipo'] = _tipoProblema!;
      request.fields['ubicacion'] = _ubicacion!;
      request.fields['descripcion'] = _controladorDescripcion.text;
      
      request.files.add(await http.MultipartFile.fromPath('foto1', _foto1!.path, contentType: MediaType('image', 'jpeg')));
      if (_foto2 != null) request.files.add(await http.MultipartFile.fromPath('foto2', _foto2!.path, contentType: MediaType('image', 'jpeg')));
      if (_video != null) request.files.add(await http.MultipartFile.fromPath('video', _video!.path, contentType: MediaType('video', 'mp4')));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (!mounted) return;
      Navigator.pop(context); // Quitar carga
      
      if (response.statusCode == 200) {
        Navigator.pop(context); // Salir de pantalla reporte
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reporte enviado con éxito ✅")));
      }
    } catch (e) { 
      if (mounted) Navigator.pop(context);
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión con el servidor ❌")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _mostrarPendientesCalificar, 
            child: const Text("Calificar reportes", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView( 
          child: Marcos(
            contenido: Column(
              children: [
                const Text("Levantar Reporte", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _mostrarHistorialReportes,
                  child: const Text("Ver mi historial de reportes", style: TextStyle(color: Colors.amber, decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _botonEvidencia(archivo: _foto1, icono: Icons.add_a_photo, label: "Foto 1", onTap: () => _capturar('foto1')),
                    _botonEvidencia(archivo: _foto2, icono: Icons.add_photo_alternate, label: "Foto 2", onTap: () => _capturar('foto2')),
                    _botonEvidencia(archivo: _video, icono: Icons.videocam, label: "Video", onTap: () => _capturar('video'), esVideo: true),
                  ],
                ),
                const SizedBox(height: 30),
                _campoTexto(_controladorDescripcion, "Descripción de la falla"),
                DropdownButtonFormField<String>(
                  value: _tipoProblema,
                  dropdownColor: const Color(0xFF000022),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "¿Qué falla?", labelStyle: const TextStyle(color: Colors.white70),
                    filled: true, fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Proyector', 'PC', 'Internet', 'Luz', 'Otro'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (v) => setState(() => _tipoProblema = v),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _ubicacion,
                  dropdownColor: const Color(0xFF000022),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "¿En dónde ocurrió?", labelStyle: const TextStyle(color: Colors.white70),
                    filled: true, fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: salones.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (v) => setState(() => _ubicacion = v),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.amber),
                  onPressed: _enviarReporte,
                  child: const Text("ENVIAR REPORTE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _botonEvidencia({File? archivo, required IconData icono, required String label, required VoidCallback onTap, bool esVideo = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 85, height: 85,
            clipBehavior: Clip.hardEdge, 
            decoration: BoxDecoration(
              color: archivo != null ? Colors.green.withOpacity(0.2) : Colors.white12,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: archivo != null ? Colors.green : Colors.white30, width: 2),
            ),
            child: archivo != null 
              ? (esVideo 
                  ? const Icon(Icons.play_circle, color: Colors.white, size: 40)
                  : Image.file(archivo, fit: BoxFit.cover)
                )
              : Icon(icono, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
//Esto es para que tenga la descripcion de la falla
  Widget _campoTexto(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.white70),
          filled: true, fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}