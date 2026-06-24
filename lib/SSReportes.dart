import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'diseñoapp.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class PantallaGestReportesSS extends StatefulWidget {
  const PantallaGestReportesSS({super.key});
  @override
  State<PantallaGestReportesSS> createState() => _PantallaGestReportesSSState();
}

class _PantallaGestReportesSSState extends State<PantallaGestReportesSS> {
  Timer? _timerConsulta;
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  List<dynamic> _reportes = [];
  bool _cargando = true;
  String? miId;

  @override
  void initState() {
    super.initState();
    _cargarDatosYReportes();
  }

  Future<void> _cargarDatosYReportes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      miId = prefs.getString('userKey');
    });
    if (miId != null && miId!.isNotEmpty) {
      await _obtenerReportes();
    } else if (mounted) {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _timerConsulta?.cancel();
    super.dispose();
  }

  Future<void> _obtenerReportes() async {
    if (miId == null || miId!.isEmpty) {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$urlBase/reportes/ss/$miId'),
            headers: {'ngrok-skip-browser-warning': 'true'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> listaReportes = [];

        if (decoded is List) {
          listaReportes = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('reportes')) {
            listaReportes = List<dynamic>.from(decoded['reportes']);
          } else if (decoded.containsKey('data')) {
            listaReportes = List<dynamic>.from(decoded['data']);
          } else {
            listaReportes = [decoded];
          }
        }

        if (mounted) {
          setState(() {
            _reportes = listaReportes;
            _cargando = false;
          });
        }
      } else {
        print('Error HTTP SSReportes: ${response.statusCode} ${response.body}');
        if (mounted) {
          setState(() {
            _reportes = [];
            _cargando = false;
          });
        }
      }
    } catch (e) {
      print("Error en actualización SS: $e");
      if (mounted) {
        setState(() {
          _reportes = [];
          _cargando = false;
        });
      }
    }
  }

 List<dynamic> _filtrar(String tipoMenu) {
  return _reportes.where((r) {
    // Convertimos el estado a minúsculas y le quitamos espacios para que la comparación sea exacta
    final String estado = r['estado']?.toString().toLowerCase().trim() ?? "";

    if (tipoMenu == "Recibidos") {
      // Al SS le deben aparecer los que tiene que trabajar o los que están pausados
      // Aceptamos 'abierto', 'asignado' y también 'en espera'
      return estado == 'abierto' || estado == 'asignado';
    }
    
    if (tipoMenu == "Completados") {
      // Aquí está el truco: debe coincidir con 'resuelto' o 'completado'
      return estado == 'resuelto' || estado == 'completado';
    }
    
    return false;
  }).toList();
}

  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
          title: const Text("Mis Reportes Asignados", style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.assignment_late), text: "Recibidos"),
              Tab(icon: Icon(Icons.assignment_turned_in), text: "Completados"),
            ],
          ),
        ),
        body: Marcos(
          contenido: TabBarView(
            children: [
              _construirLista("Recibidos"),
              _construirLista("Completados"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirLista(String tipo) {
    final listaFiltrada = _filtrar(tipo);
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (listaFiltrada.isEmpty) {
      return const Center(
        child: Text("Sin reportes", style: TextStyle(color: Colors.white54)),
      );
    }

    return RefreshIndicator(
      onRefresh: _obtenerReportes,
      child: ListView.builder(
        itemCount: listaFiltrada.length,
        itemBuilder: (context, index) {
          final reporte = listaFiltrada[index];
          final id = reporte['id_reporte'].toString();
          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: ListTile(
              leading: Icon(
                reporte['estado'] == 'Abierto' || reporte['estado'] == 'Asignado'
                    ? Icons.pending
                    : Icons.check_circle,
                color: reporte['estado'] == 'Abierto' || reporte['estado'] == 'Asignado'
                    ? Colors.orange
                    : Colors.green,
              ),
              title: Text(
                "${reporte['tipo']}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "ID: $id | Turno: ${reporte['turno'] ?? 'N/A'} | Estado: ${reporte['estado']}",
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.remove_red_eye, color: Colors.amber),
              onTap: () => _verDetalles(reporte, id),
            ),
          );
        },
      ),
    );
  }

  void _verDetalles(Map datos, String id) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.88,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detalles del Reporte",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white24, height: 30),

              // --- SECCIÓN DE CALIFICACIÓN (ESTO ES LO QUE AGREGAMOS) ---
              if (datos['puntuacion'] != null) ...[
                const Text(
                  "Calificación del usuario:",
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (datos['puntuacion'] as int) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    );
                  }),
                ),
                const SizedBox(height: 15),
              ],
              if (datos['resena'] != null && datos['resena'].toString().isNotEmpty) ...[
                const Text(
                  "Opinión del usuario:",
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    "${datos['resena']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontStyle: FontStyle.italic, // <--- Cursiva correcta
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],

              // --- EVIDENCIA SOLUCIÓN ---
              if (datos['foto_solucion1'] != null || datos['foto_solucion2'] != null) ...[
                const Text(
                  "Evidencia de la solución:",
                  style: TextStyle(color: Colors.greenAccent),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (datos['foto_solucion1'] != null) _miniaturaFoto(datos['foto_solucion1']),
                    if (datos['foto_solucion2'] != null) _miniaturaFoto(datos['foto_solucion2']),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (datos['descripcion_solucion'] != null && datos['descripcion_solucion'].toString().isNotEmpty) ...[
                _datoLabel("Descripción Solución:", "${datos['descripcion_solucion']}"),
                const SizedBox(height: 20),
              ],

              // --- EVIDENCIA ---
              if (datos['foto1'] != null || datos['foto2'] != null) ...[
                const Text(
                  "Evidencia fotográfica:",
                  style: TextStyle(color: Colors.amber),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (datos['foto1'] != null) _miniaturaFoto(datos['foto1']),
                    if (datos['foto2'] != null) _miniaturaFoto(datos['foto2']),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (datos['video'] != null) ...[
                const Text(
                  "Evidencia en video:",
                  style: TextStyle(color: Colors.amber),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final String videoUrl = '$urlBase${datos['video']}';
                    final Uri uri = Uri.parse(videoUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_fill, color: Colors.blueAccent),
                        SizedBox(width: 10),
                        Text("Ver Video del Reporte", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],

              _datoLabel("Tipo de Falla:", "${datos['tipo']}"),
              _datoLabel("Turno del Reporte:", "${datos['turno'] ?? 'N/A'}"),
              _datoLabel("Ubicación:", "${datos['ubicacion'] ?? 'No especificada'}"),
              _datoLabel("Descripción:", "${datos['descripcion']}"),
              

              const SizedBox(height: 40),

              if (datos['estado'] != 'Resuelto') ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                            ),
                            builder: (context) => FormularioResolucion(
                              idReporte: id,
                              urlBase: urlBase,
                              onSuccess: () {
                                Navigator.pop(context); // Cierra detalles
                                _obtenerReportes();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reporte marcado como Resuelto ✅")));
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade900,
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Text("Marcar Completado", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _cambiarEstado(id, "Pendiente"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade900,
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Text("Marcar Pendiente", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ] else
                const Center(
                  child: Text(
                    "✅ Reporte finalizado",
                    style: TextStyle(color: Colors.green, fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNCIONES DE APOYO ---
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

  void _abrirImagenGrande(String url) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              url,
              headers: const {'ngrok-skip-browser-warning': 'true'},
            ),
          ),
        ),
      ),
    );
  }

  Widget _datoLabel(String label, String valor) {
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
            child: Text(valor, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(String id, String nuevoEstado) async {
    try {
      final response = await http.put(
        Uri.parse('$urlBase/reportes/$id'),
        headers: {'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({"estado": nuevoEstado}),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState (() {
            final index = _reportes.indexWhere((r) => r['id_reporte'].toString() == id);
            if (index != -1) {
              _reportes[index]['estado'] = nuevoEstado;
            }
          });
          Navigator.pop(context);
          _obtenerReportes();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Movido a $nuevoEstado ✅")));
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  } 
}

class FormularioResolucion extends StatefulWidget {
  final String idReporte;
  final String urlBase;
  final VoidCallback onSuccess;

  const FormularioResolucion({
    super.key,
    required this.idReporte,
    required this.urlBase,
    required this.onSuccess,
  });

  @override
  State<FormularioResolucion> createState() => _FormularioResolucionState();
}

class _FormularioResolucionState extends State<FormularioResolucion> {
  File? _foto1, _foto2;
  final TextEditingController _controladorDescripcion = TextEditingController();
  final picker = ImagePicker();
  bool _enviando = false;

  Future<void> _capturar(String tipo) async {
    final XFile? temp = await picker.pickImage(source: ImageSource.camera);
    if (temp != null) {
      setState(() {
        if (tipo == 'foto1') _foto1 = File(temp.path);
        if (tipo == 'foto2') _foto2 = File(temp.path);
      });
    }
  }

  Future<void> _resolverReporte() async {
    if (_controladorDescripcion.text.isEmpty || _foto1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falta descripción de la solución o al menos una foto")),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String idResolutor = prefs.getString('userKey') ?? "";

      var request = http.MultipartRequest(
        'PUT', 
        Uri.parse('${widget.urlBase}/resolver-reporte/${widget.idReporte}')
      );
      
      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});
      request.fields['descripcion_solucion'] = _controladorDescripcion.text;

      if (idResolutor.isNotEmpty) {
        request.fields['id_resolutor'] = idResolutor;
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        'foto_solucion1', _foto1!.path, 
        contentType: MediaType('image', 'jpeg')
      ));
      
      if (_foto2 != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto_solucion2', _foto2!.path, 
          contentType: MediaType('image', 'jpeg')
        ));
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        Navigator.pop(context); // Cerrar el formulario
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al resolver: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión")),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resolver Reporte", style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          const Text("Evidencia de la solución:", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botonEvidencia(archivo: _foto1, icono: Icons.add_a_photo, label: "Foto 1 (Req)", onTap: () => _capturar('foto1')),
              _botonEvidencia(archivo: _foto2, icono: Icons.add_photo_alternate, label: "Foto 2 (Opc)", onTap: () => _capturar('foto2')),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _controladorDescripcion,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "¿Cómo se solucionó?", 
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true, fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          _enviando 
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), 
                  backgroundColor: Colors.green.shade900
                ),
                onPressed: _resolverReporte,
                child: const Text("MARCAR COMO RESUELTO", style: TextStyle(color: Colors.white)),
              ),
        ],
      ),
    );
  }

  Widget _botonEvidencia({File? archivo, required IconData icono, required String label, required VoidCallback onTap}) {
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
              ? Image.file(archivo, fit: BoxFit.cover)
              : Icon(icono, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}