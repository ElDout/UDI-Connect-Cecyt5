import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'dart:io';
import 'login_screen.dart';
import 'diseñoapp.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // <--- ESTA ES LA QUE TE FALTA
//Importaciones arriba y nombre abajo

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});
  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> { //declaramos los controladores y la conexion al servidor
  File? _foto;
  String? tipo_Usuario;
  String? _turnoSeleccionado;
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';
  // 🎮 Controladores (Fuera del build, ¡Perfecto!)
  final TextEditingController _controladorUsuario = TextEditingController();
  final TextEditingController _controladorApellidoPa = TextEditingController();
  final TextEditingController _controladorApellidoMa = TextEditingController();
  final TextEditingController _controladorNombres = TextEditingController();
  final TextEditingController _controladorCorreo = TextEditingController();
  final TextEditingController _controladorPassword = TextEditingController();
  final TextEditingController _ControladorConPassword = TextEditingController();

  // ☁️ Referencia a la Base de Datos

  bool _Oscurecer1 = true;
  bool _Oscurecer2 = true;

  // Lógica para tomar foto
  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final XFile? imagenTomada = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Comprime la imagen a la mitad de calidad (ni se nota)
      maxWidth: 1080,   // Nadie necesita resolución 4K para un reporte de una PC
      maxHeight: 1080,
    );
    if (imagenTomada != null) {
      setState(() {
        _foto = File(imagenTomada.path);
      });
    }
  }

  // Lógica para ver la foto en grande
  void _mostrarFoto(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(child: Image.file(_foto!, fit: BoxFit.contain)),
              Positioned(
                bottom: 50, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text("Salir"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _tomarFoto();
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Retomar"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
//Dibujo para toda la pantalla
  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Marcos(
            contenido: Column(
              children: [
                const Text("Registro de Usuario", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("Toma una foto a tu identificación expedida por la Institución", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white)),
                const SizedBox(height: 20),
                
                // --- SECCIÓN DE FOTO ---
                GestureDetector(
                  onTap: () => _foto == null ? _tomarFoto() : _mostrarFoto(context),
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _foto == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white, size: 50)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(_foto!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // --- CAMPOS DE TEXTO ---
                _campoTexto(_controladorUsuario, "Escribe tu Boleta/ID de trabajador", esOscuro),
                _campoTexto(_controladorApellidoPa, "Escribe Apellido Paterno", esOscuro),
                _campoTexto(_controladorApellidoMa, "Escribe Apellido Materno", esOscuro),
                _campoTexto(_controladorNombres, "Escribe tu Nombre(s)", esOscuro),
                _campoTexto(_controladorCorreo, "Escribe tu Correo", esOscuro),

                // Contraseñas
                _campoPassword(_controladorPassword, "Crea una Contraseña", _Oscurecer1, () => setState(() => _Oscurecer1 = !_Oscurecer1), esOscuro),
                _campoPassword(_ControladorConPassword, "Confirma tu contraseña", _Oscurecer2, () => setState(() => _Oscurecer2 = !_Oscurecer2), esOscuro),

                const SizedBox(height: 20),

                // Menú de Selección de Rol
                DropdownButtonFormField<String>(
                  value: tipo_Usuario,
                  decoration: InputDecoration(
                    labelText: "¿Eres?",
                    filled: true,
                    fillColor: esOscuro ? Colors.black : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Docente', 'Alumno', "PAAE", "Directivo"].map((String cargo) {
                    return DropdownMenuItem(value: cargo, child: Text(cargo));
                  }).toList(),
                  onChanged: (valor) => setState(() => tipo_Usuario = valor),
                ),

                const SizedBox(height: 20),

                // Menú de Selección de Turno
                DropdownButtonFormField<String>(
                  value: _turnoSeleccionado,
                  decoration: InputDecoration(
                    labelText: "¿En qué turno estás?",
                    filled: true,
                    fillColor: esOscuro ? Colors.black : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Matutino', 'Vespertino'].map((String turno) {
                    return DropdownMenuItem(value: turno, child: Text(turno));
                  }).toList(),
                  onChanged: (valor) => setState(() => _turnoSeleccionado = valor),
                ),

                const SizedBox(height: 20),

                // --- BOTÓN ENVIAR ---
                ElevatedButton(
  onPressed: () async {
    if (_validarCampos()) {
      // 1. Mostrar círculo de carga para saber que está trabajando
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        print("Iniciando envío a: $urlBase/registro");
        var request = http.MultipartRequest('POST', Uri.parse('$urlBase/registro'));
        
        // Headers necesarios
        request.headers.addAll({
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        });

        // Campos de texto
        request.fields['id_usuario'] = _controladorUsuario.text.trim();
        request.fields['password'] = _controladorPassword.text.trim();
        request.fields['rol'] = tipo_Usuario!;
        request.fields['nombres'] = _controladorNombres.text.trim();
        request.fields['apellido_p'] = _controladorApellidoPa.text.trim();
        request.fields['apellido_m'] = _controladorApellidoMa.text.trim();
        request.fields['correo'] = _controladorCorreo.text.trim();
        request.fields['turno'] = _turnoSeleccionado!;

        // Manejo de la foto
        if (_foto != null) {
          print("Adjuntando foto...");
          request.files.add(await http.MultipartFile.fromPath(
            'foto', 
            _foto!.path,
            contentType: MediaType('image', 'jpeg'),
          ));
        }

        // Enviar y esperar respuesta
        var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
        var response = await http.Response.fromStream(streamedResponse);

        // Quitar círculo de carga
        if (mounted) Navigator.pop(context);

        if (response.statusCode == 200) {
          print("Registro exitoso");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Solicitud enviada con éxito")),
          );
          Navigator.pop(context); // Regresa al Login
        } else {
          print("Error del servidor: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Error del servidor: ${response.statusCode}")),
          );
        }
      } catch (e) {
        // Quitar círculo de carga si hay error
        if (mounted) Navigator.pop(context);
        
        print("Error de conexión: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📡 Error de conexión: Verifica tu servidor")),
        );
      }
    }
  },
  child: const Text("Enviar Registro"),
),
                
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const PantallaLogin()), (Route<dynamic> route) => false),
                  child: const Text("¿Ya tienes cuenta? Inicia Sesión", style: TextStyle(color: Color(0xFFFFD700))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Métodos de apoyo para limpiar el build
  Widget _campoTexto(TextEditingController controller, String label, bool esOscuro) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        style: TextStyle(color: esOscuro ? Colors.white : Colors.black),
        decoration: InputDecoration(labelText: label, filled: true, fillColor: esOscuro ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _campoPassword(TextEditingController controller, String label, bool obscure, VoidCallback toggle, bool esOscuro) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: esOscuro ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label, filled: true, fillColor: esOscuro ? Colors.black : Colors.white,
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: toggle),
        ),
      ),
    );
  }

//Esto valida que todos los campos esten llenos 
  bool _validarCampos() {
    if (_controladorUsuario.text.isEmpty || tipo_Usuario == null || _turnoSeleccionado == null || _controladorPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, llena los campos básicos, selecciona un rol y turno")));
      return false;
    }
    if (_controladorPassword.text != _ControladorConPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Las contraseñas no coinciden")));
      return false;
    }
    return true;
  }
}