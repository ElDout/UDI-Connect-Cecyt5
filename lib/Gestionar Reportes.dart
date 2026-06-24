import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'diseñoapp.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Realizamos las importaciones
class PantallaGestReportes extends StatefulWidget {
  const PantallaGestReportes({super.key});
  @override
  State<PantallaGestReportes> createState() => _PantallaGestReportesState();
}

class _PantallaGestReportesState extends State<PantallaGestReportes> {
  Timer? _timerConsulta;
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  List<dynamic> _reportes = [];
  List<dynamic> _usuariosSS = [];
  bool _cargando = true;
  bool _cargandoUsuarios = true;
  String _idActual = "";
  // Variables nuevas para la paginación
  final ScrollController _scrollController = ScrollController();
  int _paginaActual = 1;
  final int _limitePorPagina = 10;
  bool _cargandoMas = false; // Para saber si estamos pidiendo más datos
  bool _hayMasDatos = true;  // Para saber si ya llegamos al final de todos los reportes
  // Aquí declaramos unos booleanos y un Timer que va a preguntar constantemente al servidor por actualizaciones
@override
  void initState() {
    super.initState();
    _cargarUsuario();
    _obtenerUsuariosSS();
    
    // Traemos la primera página de reportes al abrir la pantalla
    _obtenerReportes(recargar: true); 

    // ❌ ADIÓS AL TIMER QUE GASTABA DATOS:
    // _timerConsulta = Timer.periodic(const Duration(seconds: 15), (timer) { ... });

    // ✅ HOLA AL SENSOR DE SCROLL (PAGINACIÓN):
    _scrollController.addListener(() {
      // Detectamos si el usuario ya llegó hasta el fondo de la pantalla
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        
        // Si no estamos ya cargando y el servidor nos dijo que aún hay más reportes...
        if (!_cargandoMas && _hayMasDatos) {
           // ...pedimos la siguiente página
          _obtenerReportes(recargar: false);
        }
      }
    });
  }

  Future<void> _cargarUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _idActual = prefs.getString('userKey') ?? "";
      });
    }
  }
  // Aquí llamamos a todos los métodos

  @override
  void dispose() {
    _timerConsulta?.cancel();
    super.dispose();
  } // Cancelamos el timer para que no sea infinito

  // Le agregamos el parámetro 'recargar' por si el usuario jala la lista hacia abajo (RefreshIndicator)
  Future<void> _obtenerReportes({bool recargar = false}) async { 
    if (recargar) {
      _paginaActual = 1;
      _hayMasDatos = true;
      if (mounted) setState(() => _cargando = true);
    } else {
      if (mounted) setState(() => _cargandoMas = true);
    }

    try {
      // Le mandamos al servidor la página y el límite por la URL
      final response = await http.get(
        Uri.parse('$urlBase/reportes?page=$_paginaActual&limit=$_limitePorPagina'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> nuevosReportes = json.decode(response.body);

        if (mounted) {
          setState(() {
            if (recargar) {
              _reportes = nuevosReportes; // Si es recarga, reemplazamos la lista
            } else {
              _reportes.addAll(nuevosReportes); // Si es paginación, los agregamos al final de la lista
            }

            // Si el servidor nos mandó menos de 10, significa que ya no hay más en la BD
            if (nuevosReportes.length < _limitePorPagina) {
              _hayMasDatos = false;
            } else {
              _paginaActual++; // Preparamos la siguiente página
            }

            _cargando = false;
            _cargandoMas = false;
          });
        }
      }
    } catch (e) {
      print("Error en actualización: $e");
      if (mounted) {
        setState(() {
          _cargando = false;
          _cargandoMas = false;
        });
      }
    }
  }

  Future<void> _obtenerUsuariosSS() async { // Esto es lo mismo para obtener los usuarios de Servicio Social
    try {
      final response = await http.get(
        Uri.parse('$urlBase/usuarios-todos'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> listaSS = [];
        if (decoded is Map) {
          if (decoded.containsKey('ss')) { 
            listaSS = List<dynamic>.from(decoded['ss']);
          } else {
            for (final entry in decoded.entries) {
              if (entry.key.toString().toLowerCase().contains('ss')) {
                listaSS = List<dynamic>.from(entry.value);
                break;
              }
            }
          }
        } else if (decoded is List) {
          listaSS = decoded.where((u) {
            final rol =
                u['rol']?.toString().toLowerCase() ??
                u['tipo']?.toString().toLowerCase();
            return rol == 'ss' ||
                rol == 'servicio social' ||
                rol == 'servicio_social';
          }).toList();
        }
        if (mounted) {
          setState(() {
            _usuariosSS = listaSS;
            _cargandoUsuarios = false;
          });
        }
      }
    } catch (e) {
      print('Error al obtener usuarios SS: $e');
      if (mounted) {
        setState(() {
          _cargandoUsuarios = false;
        });
      }
    }
  }

  // --- FILTRADO CORREGIDO ---
List<dynamic> _filtrar(String tipoMenu) {
  return _reportes.where((r) {
    final estado = r['estado']?.toString().toLowerCase().trim() ?? "";
    // Checamos si el reporte tiene un ID de servicio social asignado
    final bool tieneAsignado = r['asignado_a'] != null && r['asignado_a'] != 0;

    switch (tipoMenu) {
      case "Recibidos":
        // SOLO lo que está pendiente Y no tiene a nadie asignado
        return estado == 'pendiente' && !tieneAsignado;

      case "Asignados":
        // Lo que está en proceso y tiene un responsable
        return (estado == 'abierto' || estado == 'asignado') && tieneAsignado;

      case "Pendientes":
        // AQUÍ ES donde debe caer: 
        // Si tú lo marcaste como pendiente pero YA tenía alguien asignado
        // o si el estado es 'en espera'
        return (estado == 'pendiente' && tieneAsignado) || estado == 'en espera';

      case "Completados":
        return estado == 'resuelto' || estado == 'completado' || estado == 'finalizado';

      default:
        return false;
    }
  }).toList();
}
  
// Esto dibuja el menú de los reportes que hay 
  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
          elevation: 0,
          title: const Text(
            "Gestión de Reportes",
            style: TextStyle(color: Colors.white),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.all_inbox), text: "Recibidos"),
              Tab(icon: Icon(Icons.assignment), text: "Asignados"),
              Tab(icon: Icon(Icons.pending_actions), text: "Pendientes"),
              Tab(icon: Icon(Icons.check_circle), text: "Completados"),
            ],
          ),
        ),
        body: Marcos( // Importamos el diseño con Marcos y construimos las listas 
          contenido: TabBarView(
            children: [
              _construirLista("Recibidos"),
              _construirLista("Asignados"),
              _construirLista("Pendientes"),
              _construirLista("Completados"),
            ],
          ),
        ),
      ),
    );
  }
  // Este es un widget para construir las listas, definimos el color y sus bordes
  Widget _construirLista(String tipo) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    final listaFiltrada = _filtrar(tipo);

    if (_cargando) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    
    if (listaFiltrada.isEmpty) {
      return const Center(
        child: Text("No hay reportes aquí", style: TextStyle(color: Colors.grey)),
      );
    }
    // Refrescamos las listas llamando a obtener reportes
    return RefreshIndicator(
      onRefresh: () => _obtenerReportes(recargar: true), // Actualizamos para que recargue desde cero
      child: ListView.builder(
        controller: _scrollController, // <--- AQUÍ LE CONECTAS EL SENSOR
        itemCount: listaFiltrada.length + (_cargandoMas ? 1 : 0), // Sumamos 1 si estamos cargando para mostrar la bolita
        itemBuilder: (context, index) {
          if (index == listaFiltrada.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: Colors.amber)),
            );
          }
          final reporte = listaFiltrada[index];
          final id = reporte['id_reporte'].toString();
          
          // Lógica de colores e iconos según el estado real
          IconData icono;
          Color colorIcono;
          
          switch (reporte['estado']) {
            case 'Pendiente':
              icono = Icons.notification_important; // Icono de Reportes recibidos
              colorIcono = Colors.redAccent;
              break;
            case 'Resuelto':
              icono = Icons.check_circle;
              colorIcono = Colors.green;
              break;
            case 'Asignado':
            case 'Abierto':
              icono = Icons.engineering;
              colorIcono = Colors.blue;
              break;
            default:
              icono = Icons.help_outline;
              colorIcono = Colors.grey;
          }

          return Card( // Esto es el reporte cuando lo abres para ver toda la información del reporte
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: ListTile(
              leading: Icon(icono, color: colorIcono),
             title: Text(
                "${reporte['tipo']}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      TextSpan(text: "ID: $id | Turno: ${reporte['turno'] ?? 'N/A'} | Estado: ${reporte['estado']}\n"),
                      TextSpan(text: "Reportó: ${reporte['nombre_usuario'] ?? reporte['id_usuario']} (${reporte['rol_usuario'] ?? 'Sin rol'})"),
                      // Mostramos al técnico si ya hay uno asignado
                      if (reporte['resuelto_por_nombre'] != null)
                        TextSpan(
                          text: "\nAtendido por: ${reporte['resuelto_por_nombre']}",
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
              trailing: const Icon(Icons.remove_red_eye, color: Colors.amber),
              onTap: () => _verDetalles(reporte, id, tipo),
            ),
          );
        },
      ),
    );
  }
  // Este método lo llamamos más abajo pero es para abrir la imagen del reporte recibido comunicándose con la base de datos
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
  // Este es todo el método para ver los detalles del reporte
  void _verDetalles(Map datos, String id, String menuActual) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    // Se abre una tarjeta con toda la información del reporte 
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
              Text("Detalles - $menuActual", style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)), // Aquí da los detalles
              const Divider(color: Colors.white24, height: 30),

              // Esta es la puntuación y reseña pero solo se muestra cuando se ha completado el reporte
              if (datos['puntuacion'] != null) ...[
                const Text("Calificación del servicio:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
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
              ], // Esto enseña el texto de la reseña
              if (datos['resena'] != null && datos['resena'].toString().isNotEmpty) ...[
                const Text("Opinión del usuario:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
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
  "${datos['resena']}", 
  style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
),
                ),
                const SizedBox(height: 25),
              ],
              // ------------------------------------------

              // --- Muestra la evidencia de la solución ---
              if (datos['foto_solucion1'] != null || datos['foto_solucion2'] != null) ...[
                const Text("Evidencia de la solución:", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (datos['foto_solucion1'] != null) _miniaturaFoto(datos['foto_solucion1']), // Muestra las 2 fotos que se suben para completar el reporte
                    if (datos['foto_solucion2'] != null) _miniaturaFoto(datos['foto_solucion2']),
                  ],
                ),
                const SizedBox(height: 20),
              ], // Da la descripción de la solución
              if (datos['descripcion_solucion'] != null && datos['descripcion_solucion'].toString().isNotEmpty) ...[
                _datoLabel("Descripción Solución:", "${datos['descripcion_solucion']}"),
                const SizedBox(height: 20),
              ],

              // Esto es para ver las miniaturas de las fotos que se enviaron 
              if (datos['foto1'] != null || datos['foto2'] != null) ...[
                const Text("Evidencia fotográfica:", style: TextStyle(color: Colors.amber)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (datos['foto1'] != null) _miniaturaFoto(datos['foto1']),
                    if (datos['foto2'] != null) _miniaturaFoto(datos['foto2']),
                  ],
                ),
                const SizedBox(height: 20),
              ], // Esto es el video que se manda por parte de la persona que está reportando y se abre en la web
              if (datos['video'] != null && datos['video'].toString().isNotEmpty) ...[
  const SizedBox(height: 20),
  const Text("Evidencia en Video:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
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
        final videoUrl = datos['video'].toString().startsWith('http') 
            ? datos['video'] 
            : '$urlBase${datos['video']}';
            
        final uri = Uri.parse(videoUrl);
        
        // Intentamos abrir el video
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
              // Estos son los datos que el usuario reportó 
             _datoLabel("Tipo de Falla:", "${datos['tipo']}"),
             _datoLabel("Turno del Reporte:", "${datos['turno'] ?? 'N/A'}"),
              _datoLabel(
                "Enviado por:", 
                "${datos['nombre_usuario'] ?? 'Sin nombre'} " 
                "[ID: ${datos['id_usuario'] ?? '??'}] "       
                "(${datos['rol_usuario'] ?? 'Sin rol'})"      
              ),
              _datoLabel("Ubicación:", "${datos['ubicacion'] ?? 'No especificada'}"),
              if (datos['resuelto_por_nombre'] != null)
                _datoLabel(
                  "Atendido/Resuelto por:", 
                  "${datos['resuelto_por_nombre']} (${datos['resuelto_por_rol'] ?? 'Sin rol'})"
                ),
              Builder(
                builder: (context) {
                  String inicioStr = "Desconocida";
                  String finStr = "Aún en proceso";
                  
                  
                  if (datos['fecha'] != null) {
                    DateTime dt = DateTime.parse(datos['fecha'].toString()).toLocal();
                    inicioStr = DateFormat('dd/MM/yyyy - hh:mm a').format(dt);
                  }
                  
                  if (datos['fecha_resolucion'] != null) {
                    DateTime dt = DateTime.parse(datos['fecha_resolucion'].toString()).toLocal();
                    finStr = DateFormat('dd/MM/yyyy - hh:mm a').format(dt);
                  }

                  return Column(
                    children: [
                      _datoLabel("Iniciado:", inicioStr),
                      if (datos['estado'] == 'Resuelto' || datos['estado'] == 'Completado')
                        _datoLabel("Solucionado:", finStr),
                    ],
                  );
                }
              ),
              
              const SizedBox(height: 20),
              const Text("Descripción original:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              Text("${datos['descripcion']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
              
              const SizedBox(height: 40),

              // Estos son los botones que tiene cada menú
              Column(
                children: [
                  if (menuActual == "Recibidos") ...[
                    _botonAction("Marcar como Completado", Colors.green.shade900, () {
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
                    }),
                    _botonAction("Asignar a Servicio Social", Colors.blue.shade900, () => _mostrarModalAsignarServicioSocial(datos, id)),
                    _botonAction("Borrar Reporte", Colors.red.shade900, () => _eliminarReporte(id)),
                  ],
                  if (menuActual == "Asignados") ...[
                    _botonAction("Marcar como Completado", Colors.green.shade900, () {
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
                    }),
                    _botonAction("Asignar a alguien más", Colors.blue.shade900, () => _mostrarModalAsignarServicioSocial(datos, id)),
                    _botonAction("Marcar como Pendiente", Colors.orange.shade900, () => _cambiarEstado(id, "Pendiente")),
                    _botonAction("Borrar Reporte", Colors.red.shade900, () => _eliminarReporte(id)),
                  ],
                  if (menuActual == "Pendientes") ...[
                    _botonAction("Marcar como Completado", Colors.green.shade900, () {
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
                    }),
                    _botonAction("Asignar a alguien más", Colors.blue.shade900, () => _mostrarModalAsignarServicioSocial(datos, id)),
                    _botonAction("Borrar Reporte", Colors.red.shade900, () => _eliminarReporte(id)),
                  ],
                  if (menuActual == "Completados")
                    _botonAction("Eliminar del Historial", Colors.red.shade900, () => _eliminarReporte(id)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
// Este widget dibuja los botones de las acciones
  Widget _botonAction(String texto, Color color, VoidCallback funcion) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: funcion,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(texto, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
// Este método hace que nos muestre la lista de los de servicio social que tengan asistencia
  void _mostrarModalAsignarServicioSocial(Map reporte, String id) {
  bool esOscuro = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) {
      // Usamos un FutureBuilder para llamar a la nueva ruta filtrada
      return FutureBuilder<http.Response>(
        future: http.get(
          Uri.parse('$urlBase/usuarios/ss-disponibles'), // <--- LA NUEVA RUTA FILTRADA
          headers: {'ngrok-skip-browser-warning': 'true'},
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          
          List<dynamic> ssDisponibles = json.decode(snapshot.data!.body);

          if (ssDisponibles.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  "No hay nadie con asistencia hoy 😴", 
                  style: TextStyle(color: Colors.white70)
                ),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Asignar a SS Disponible (Con Asistencia)", 
                  style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: ssDisponibles.length,
                    itemBuilder: (context, index) {
                      final user = ssDisponibles[index];
                      final nombre = "${user['nombres']} ${user['apellido_p']}";
                      return Card(
                        color: Colors.white10,
                        child: ListTile(
                          title: Text(nombre, style: const TextStyle(color: Colors.white)),
                          subtitle: Text("ID: ${user['id_usuario']}", style: const TextStyle(color: Colors.white70)),
                          trailing: const Icon(Icons.send, color: Colors.amber),
                          onTap: () => _confirmarAsignacion(reporte, user),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
// Esto es para confirmar la asignación de servicio social, si es que estamos seguros.
  void _confirmarAsignacion(Map reporte, Map usuario) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    final nombre = "${usuario['nombres'] ?? ''} ${usuario['apellido_p'] ?? ''}"
        .trim();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: esOscuro ? const Color(0xFF000033) : const Color(0xFF800000),
        title: const Text(
          "Confirmar asignación",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Asignar este reporte a $nombre?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Cierra la lista de SS
              // IMPORTANTE: Cerramos también el panel de detalles para evitar bugs visuales
              Navigator.pop(context); 
              _asignarReporte(reporte['id_reporte'].toString(), usuario);
            },
            child: const Text("Asignar", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
// Esto es para los reportes que ya fueron asignados
  Future<void> _asignarReporte(String id, Map usuario) async {
    try {
      final response = await http.put(
        Uri.parse('$urlBase/reportes/asignar/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_ss': usuario['id_usuario'],
          // Cambiamos el estado a Abierto al reasignar para asegurarnos que caiga en 'Asignados'
          'estado': 'Abierto', 
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          _obtenerReportes(); // Refrescamos todo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Reporte asignado y movido ✅"),
            ),
          );
        }
      } else {
        print('Error al asignar reporte: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al asignar reporte: $e');
    }
  }
  // Esto es para ver la fotografía 
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
// Estos son los datos que se pusieron 
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
  // Aquí cambiamos el estado de los reportes para moverlos a otras pestañas
  Future<void> _cambiarEstado(String id, String nuevoEstado) async {
    try {
      final response = await http.put(
        Uri.parse('$urlBase/reportes/$id'),
        headers: {'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',},
        body: jsonEncode({"estado": nuevoEstado}),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); // Cerramos el panel
          _obtenerReportes();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Movido a $nuevoEstado ✅")));
        }
      }
    } catch (e) {
      print("Error al actualizar: $e");
    }
  }
  Future<bool> canalPuedeLanzar(Uri url) async {
  return await canLaunchUrl(url);
}
// Esto simplemente borra los reportes de la base de datos y servidor
  Future<void> _eliminarReporte(String id) async {
    try {
      final response = await http.delete(Uri.parse('$urlBase/reportes/$id'));
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); // Cerramos el panel
          _obtenerReportes();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Reporte eliminado 🗑️")));
        }
      }
    } catch (e) {
      print("Error al eliminar: $e");
    }
  }
}
// Esto es toda la visualización de la pantalla
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
    final XFile? temp = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Comprime la imagen a la mitad de calidad (ni se nota)
      maxWidth: 1080,   // Nadie necesita resolución 4K para un reporte de una PC
      maxHeight: 1080,
    );
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
      // --- NUEVO: Extraemos la sesión de quien presionó el botón ---
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String idResolutor = prefs.getString('userKey') ?? "";

      var request = http.MultipartRequest(
        'PUT', 
        Uri.parse('${widget.urlBase}/resolver-reporte/${widget.idReporte}')
      );
      
      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});
      request.fields['descripcion_solucion'] = _controladorDescripcion.text;
      
      // --- NUEVO: Enviamos el ID al servidor ---
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
