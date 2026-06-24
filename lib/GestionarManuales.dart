import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';

import 'diseñoapp.dart';

class PantallaGestionarManuales extends StatelessWidget {
  const PantallaGestionarManuales({super.key});

  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Manuales', style: TextStyle(color: Colors.white)),
          backgroundColor: esOscuro ? const Color(0xFF000022) : const Color(0xFF800000),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.book), text: 'Básicos'),
              Tab(icon: Icon(Icons.terminal), text: 'Avanzados'),
            ],
          ),
        ),
        body: const Marcos(
          contenido: TabBarView(
            children: [
              VistaCategoriaManuales(categoria: 'Básicos'),
              VistaCategoriaManuales(categoria: 'Avanzados'),
            ],
          ),
        ),
      ),
    );
  }
}

class VistaCategoriaManuales extends StatefulWidget {
  final String categoria;
  const VistaCategoriaManuales({super.key, required this.categoria});

  @override
  State<VistaCategoriaManuales> createState() => _VistaCategoriaManualesState();
}

class _VistaCategoriaManualesState extends State<VistaCategoriaManuales> {
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  List<dynamic> manuales = [];
  bool _cargando = true;
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? "Admin";
    _obtenerManuales();
  }

  Future<void> _obtenerManuales() async {
    try {
      final response = await http.get(
        Uri.parse('$urlBase/manuales/${widget.categoria}'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        setState(() {
          manuales = json.decode(response.body);
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _agregarManual() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      String fileName = result.files.single.name;
      String? filePath = result.files.single.path;
      
      setState(() => _cargando = true);

      try {
        var request = http.MultipartRequest('POST', Uri.parse('$urlBase/subir-manual'));
        request.headers.addAll({'ngrok-skip-browser-warning': 'true'});
        
        request.fields['nombre'] = fileName;
        request.fields['categoria'] = widget.categoria;
        request.fields['nombre_usuario'] = _userName;

        request.files.add(await http.MultipartFile.fromPath(
          'pdf', filePath!,
          contentType: MediaType('application', 'pdf'),
        ));

        var response = await request.send();
        if (response.statusCode == 200) {
          _obtenerManuales();
        }
      } catch (e) {
        setState(() => _cargando = false);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manual "$fileName" agregado a ${widget.categoria}.')),
        );
      }
    }
  }

  Future<void> _editarManual(String id, String nombreActual) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _cargando = true);
      String newFileName = result.files.single.name;
      String? newFilePath = result.files.single.path;

      try {
        var request = http.MultipartRequest('PUT', Uri.parse('$urlBase/manuales/$id'));
        request.headers.addAll({'ngrok-skip-browser-warning': 'true'});
        request.fields['nombre'] = newFileName;
        request.fields['nombre_usuario'] = _userName;
        request.files.add(await http.MultipartFile.fromPath('pdf', newFilePath!));

        var response = await request.send();
        if (response.statusCode == 200) {
          _obtenerManuales();
        }
      } catch (e) {
        setState(() => _cargando = false);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manual actualizado. Nuevo archivo: $newFileName')),
        );
      }
    }
  }

  Future<void> _eliminarManual(String id) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Manual'),
        content: const Text('¿Estás seguro de que deseas eliminar este manual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmar) {
      setState(() => _cargando = true);
      try {
        final response = await http.delete(Uri.parse('$urlBase/manuales/$id'));
        if (response.statusCode == 200) {
          _obtenerManuales();
        }
      } catch (e) { setState(() => _cargando = false); }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manual eliminado exitosamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: const Color(0xFF000022),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _agregarManual,
            icon: const Icon(Icons.upload_file),
            label: Text(
              "Agregar Manual a ${widget.categoria}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _cargando ? const Center(child: CircularProgressIndicator(color: Colors.amber)) :
          manuales.isEmpty
              ? const Center(
                  child: Text(
                    "No hay manuales registrados.",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: manuales.length,
                  itemBuilder: (context, index) {
                    final manual = manuales[index];
                    final id = manual["id_manual"].toString();
                    return Card(
                      color: esOscuro ? Colors.lightBlue : Colors.red.shade300,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                        title: Text(
                          manual["nombre"] ?? "Sin nombre",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Subido por: ${manual["creado_por"] ?? 'Sist.'}"),
                        onTap: () async {
                          final url = '$urlBase${manual["url_pdf"]}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          }
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Reemplazar/Editar PDF',
                              onPressed: () => _editarManual(
                                id, 
                                manual["nombre"] ?? ""
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar PDF',
                              onPressed: () => _eliminarManual(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}