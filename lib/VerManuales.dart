import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'diseñoapp.dart';

class PantallaVerManuales extends StatefulWidget {
  const PantallaVerManuales({super.key});

  @override
  State<PantallaVerManuales> createState() => _PantallaVerManualesState();
}

class _PantallaVerManualesState extends State<PantallaVerManuales> {
  String _rol = "";
  bool _cargandoRol = true;

  @override
  void initState() {
    super.initState();
    _obtenerRol();
  }

  Future<void> _obtenerRol() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _rol = prefs.getString('userRole')?.toLowerCase() ?? "alumno";
      _cargandoRol = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoRol) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    // Definición de permisos por rol
    bool verBasicos = ["alumno", "alumnos", "docente", "docentes", "directivo", "directivos", "admin", "administradores", "paae"].contains(_rol);
    bool verAvanzados = ["ss", "servicio social", "admin", "administradores", "paae"].contains(_rol);

    // Configuramos las pestañas dinámicamente
    List<Tab> misTabs = [];
    List<Widget> misVistas = [];

    if (verBasicos) {
      misTabs.add(const Tab(icon: Icon(Icons.book), text: 'Básicos'));
      misVistas.add(const ListaPublicaManuales(categoria: 'Básicos'));
    }
    if (verAvanzados) {
      misTabs.add(const Tab(icon: Icon(Icons.terminal), text: 'Avanzados'));
      misVistas.add(const ListaPublicaManuales(categoria: 'Avanzados'));
    }

    return DefaultTabController(
      length: misTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manuales Institucionales', style: TextStyle(color: Colors.white)),
          backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: misTabs.length > 1 ? TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            tabs: misTabs,
          ) : null, // Si solo hay una categoría, no mostramos la barra de pestañas
        ),
        body: Marcos(
          contenido: TabBarView(children: misVistas),
        ),
      ),
    );
  }
}

class ListaPublicaManuales extends StatefulWidget {
  final String categoria;
  const ListaPublicaManuales({super.key, required this.categoria});

  @override
  State<ListaPublicaManuales> createState() => _ListaPublicaManualesState();
}

class _ListaPublicaManualesState extends State<ListaPublicaManuales> {
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  List<dynamic> _manuales = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _fetchManuales();
  }

  Future<void> _fetchManuales() async {
    try {
      final response = await http.get(
        Uri.parse('$urlBase/manuales/${widget.categoria}'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _manuales = json.decode(response.body);
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    if (_manuales.isEmpty) return const Center(child: Text("No hay manuales en esta categoría", style: TextStyle(color: Colors.white54)));

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _manuales.length,
      itemBuilder: (context, index) {
        final m = _manuales[index];
        return Card(
          color: Colors.white10,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.amber),
            title: Text(m['nombre'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("Categoría: ${widget.categoria}", style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.download, color: Colors.white54),
            onTap: () async {
              final url = Uri.parse('$urlBase${m['url_pdf']}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No se pudo abrir el PDF")),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}