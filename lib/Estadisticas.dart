import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'diseñoapp.dart';

class PantallaEstadisticas extends StatefulWidget {
  const PantallaEstadisticas({super.key});

  @override
  State<PantallaEstadisticas> createState() => _PantallaEstadisticasState();
}

class _PantallaEstadisticasState extends State<PantallaEstadisticas> {
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev'; // Recuerda actualizar tu ngrok.
  
  List<dynamic> _globales = [];
  List<dynamic> _topSalones = [];
  List<dynamic> _desempenoEquipo = [];
  List<dynamic> _reportesTurno = [];
  String _tiempoGlobal = "0";
  
  bool _cargando = true;
  String _vistaSeleccionada = "Top Salones"; // "Top Salones", "Top Problemas", "Equipo Técnico"
  String _filtroRol = "Todos"; // "Todos", "Admin", "PAAE", "Servicio Social"

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  // --- TRADUCTOR DE TIEMPO (De minutos a días/horas/mins) ---
  String _formatearTiempo(dynamic minutosObj) {
    if (minutosObj == null) return "0 min";
    double? minsDouble = double.tryParse(minutosObj.toString());
    if (minsDouble == null) return "0 min";
    
    int minutosTotales = minsDouble.toInt();
    if (minutosTotales == 0) return "Menos de 1 min";

    int dias = minutosTotales ~/ 1440;
    int horas = (minutosTotales % 1440) ~/ 60;
    int minutos = minutosTotales % 60;

    List<String> partes = [];
    if (dias > 0) partes.add("$dias día${dias > 1 ? 's' : ''}");
    if (horas > 0) partes.add("$horas hr${horas > 1 ? 's' : ''}");
    if (minutos > 0) partes.add("$minutos min");

    return partes.join(" ");
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _cargando = true);
    try {
      final response = await http.get(
        Uri.parse('$urlBase/estadisticas'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _globales = data['problemas_generales'] ?? [];
            _topSalones = data['top_salones'] ?? [];
            _desempenoEquipo = data['desempeno_equipo'] ?? [];
            _reportesTurno = data['reportes_turno'] ?? [];
            _tiempoGlobal = data['tiempo_global']?.toString() ?? "0";
            _cargando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Estadísticas", style: TextStyle(color: Colors.white)),
        backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
        elevation: 0,
      ),
      body: Marcos(
        contenido: _cargando 
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TIEMPO PROMEDIO GLOBAL ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: esOscuro 
                            ? [Colors.blue.shade900, const Color(0xFF000033)]
                            : [Colors.red.shade400, const Color(0xFF800000)]
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: esOscuro ? Colors.blueAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5))
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.timer, color: Colors.amber, size: 40),
                        const SizedBox(height: 10),
                        const Text("Tiempo Promedio General de Solución", style: TextStyle(color: Colors.white70)),
                        Text(_formatearTiempo(_tiempoGlobal), 
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- SELECTOR DE VISTA ---
                  const Text("¿Qué deseas analizar?", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _vistaSeleccionada,
                    dropdownColor: const Color(0xFF000022),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ["Top Salones", "Top Problemas", "Equipo Técnico", "Reportes por Turno"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _vistaSeleccionada = v!),
                  ),
                  const SizedBox(height: 20),

                  // --- RENDERIZADO DINÁMICO ---
                  if (_vistaSeleccionada == "Top Salones")
                    _construirTop3("Ubicaciones con más fallas", _topSalones, "ubicacion"),
                    
                  if (_vistaSeleccionada == "Top Problemas")
                    _construirTop3("Fallas más recurrentes", _globales, "tipo"),

                  if (_vistaSeleccionada == "Reportes por Turno")
                    _construirTop3("Reportes por Turno", _reportesTurno, "turno"),

                  if (_vistaSeleccionada == "Equipo Técnico") ...[
                    // Chips para filtrar a los usuarios.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ["Todos", "Admin", "PAAE", "Servicio Social"].map((rol) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(rol, style: TextStyle(color: _filtroRol == rol ? Colors.black : Colors.white)),
                              selectedColor: Colors.amber,
                              backgroundColor: Colors.white10,
                              selected: _filtroRol == rol,
                              onSelected: (bool selected) {
                                setState(() => _filtroRol = rol);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._desempenoEquipo.where((u) => _filtroRol == "Todos" || u['rol'] == _filtroRol).map((u) => _construirTarjetaUsuario(u)).toList(),
                  ]
                ],
              ),
            ),
      ),
    );
  }

  // --- WIDGET PARA DIBUJAR EL TOP 3 Y LOS DEMÁS ---
  Widget _construirTop3(String titulo, List<dynamic> datos, String llaveNombre) {
    if (datos.isEmpty) return const Center(child: Text("Sin datos registrados.", style: TextStyle(color: Colors.white54)));

    List<Widget> listaElementos = [];
    
    // Top 3 con medallas.
    for (int i = 0; i < datos.length; i++) {
      String medalla = "";
      Color colorFondo = Colors.transparent;
      
      if (i == 0) { medalla = "🥇"; colorFondo = Colors.amber.withOpacity(0.1); }
      else if (i == 1) { medalla = "🥈"; colorFondo = Colors.grey.withOpacity(0.1); }
      else if (i == 2) { medalla = "🥉"; colorFondo = Colors.brown.withOpacity(0.1); }

      if (i < 3) {
        listaElementos.add(
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: colorFondo,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10)
            ),
            child: ListTile(
              leading: Text(medalla, style: const TextStyle(fontSize: 28)),
              title: Text("${datos[i][llaveNombre]}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              trailing: Text("${datos[i]['total']} reportes", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          )
        );
      }
    }

    // Los demás (del 4to en adelante).
    if (datos.length > 3) {
      listaElementos.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text("Otras incidencias:", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
      ));
      
      for (int i = 3; i < datos.length; i++) {
        listaElementos.add(
          ListTile(
            dense: true,
            leading: const Icon(Icons.arrow_right, color: Colors.white54),
            title: Text("${datos[i][llaveNombre]}", style: const TextStyle(color: Colors.white70)),
            trailing: Text("${datos[i]['total']}", style: const TextStyle(color: Colors.white54)),
          )
        );
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: listaElementos);
  }

  // --- WIDGET PARA EL DESEMPEÑO DEL USUARIO ---
  Widget _construirTarjetaUsuario(Map<String, dynamic> usuario) {
    String nombre = usuario['nombre_resolutor'] ?? 'Desconocido';
    String rol = usuario['rol'] ?? 'Sin rol';
    int total = int.tryParse(usuario['total_resueltos'].toString()) ?? 0;

    // 1️⃣ SI EL USUARIO TIENE 0 REPORTES RESUELTOS:
    if (total == 0) {
      return Card(
        color: Colors.white.withOpacity(0.05),
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(15),
          leading: CircleAvatar(
            backgroundColor: Colors.grey.withOpacity(0.2),
            child: const Icon(Icons.person_off, color: Colors.grey),
          ),
          title: Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Rol: $rol", style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                const SizedBox(height: 5),
                const Text("No tiene ningún reporte completado 😴", style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ),
      );
    }

    // 2️⃣ SI EL USUARIO SÍ TIENE REPORTES (Se muestra todo normal):
    String promedioEstrellas = usuario['calificacion_promedio']?.toString() == '0' ? 'S/N' : usuario['calificacion_promedio'].toString();
    String tiempoFormateado = _formatearTiempo(usuario['minutos_promedio']);
    List<dynamic> comentarios = usuario['comentarios'] ?? [];

    double mins = double.tryParse(usuario['minutos_promedio']?.toString() ?? "0") ?? 0;
    Color colorTiempo = mins > 2880 ? Colors.redAccent : Colors.greenAccent;

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Colors.amber.withOpacity(0.2),
          child: const Icon(Icons.person, color: Colors.amber),
        ),
        title: Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Rol: $rol", style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
              const SizedBox(height: 5),
              Text("✅ Resueltos: $total reportes", style: const TextStyle(color: Colors.white70)),
              Text("⭐ Calificación: $promedioEstrellas", style: const TextStyle(color: Colors.white70)),
              Text("⏱️ Tarda aprox: $tiempoFormateado", style: TextStyle(color: colorTiempo, fontWeight: FontWeight.bold)), 
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.forum, color: Colors.blueAccent),
          tooltip: "Ver opiniones",
          onPressed: () => _mostrarOpiniones(nombre, comentarios),
        ),
      ),
    );
  }

  // --- PANEL DE RESEÑAS ---
  void _mostrarOpiniones(String nombre, List<dynamic> comentarios) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF000022),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Opiniones sobre $nombre", style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24, height: 30),
              
              if (comentarios.isEmpty)
                const Expanded(child: Center(child: Text("Sin reseñas escritas aún.", style: TextStyle(color: Colors.white54))))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: comentarios.length,
                    itemBuilder: (context, index) {
                      final com = comentarios[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (s) => Icon(s < (com['puntos'] ?? 0) ? Icons.star : Icons.star_border, color: Colors.amber, size: 18)),
                            ),
                            const SizedBox(height: 8),
                            Text("\"${com['opinion']}\"", style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                          ],
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
  }
}