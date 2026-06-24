import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // IMPORTANTE: Agregamos http.
import 'dart:convert';
import 'diseñoapp.dart';

class Encuesta extends StatefulWidget {
  final String idReporte; // <--- Necesitamos el ID del reporte para saber cuál actualizar.

  const Encuesta({super.key, required this.idReporte});

  @override
  State<Encuesta> createState() => _EncuestaState();
}

class _EncuestaState extends State<Encuesta> {
  int _puntuacion = 0;
  final TextEditingController _comentarioController = TextEditingController();
  bool _enviando = false; // Para mostrar carga en el botón.

  // Tu URL de Ngrok.
  final String urlBase = 'https://purposely-enlisted-overboard.ngrok-free.dev';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Marcos(
        contenido: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              const Text(
                "Encuesta de Servicio",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                "Calificando Reporte #${widget.idReporte}",
                style: const TextStyle(color: Colors.amber, fontSize: 14),
              ),
              const SizedBox(height: 60),

              // --- SECCIÓN DE ESTRELLAS ---
              const Text(
                "¿Cómo calificarías el servicio?",
                style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      index < _puntuacion ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => _puntuacion = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // --- CUADRO DE TEXTO ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(" Cuéntanos más detalles:", style: TextStyle(color: Colors.white70, fontSize: 15)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _comentarioController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Escribe tu reseña aquí...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.amber)),
                ),
              ),

              const SizedBox(height: 50),

              // --- BOTÓN DE ENVIAR ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: const Color(0xFF000033),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                onPressed: _enviando ? null : _enviarEncuesta, // Bloqueamos si está enviando.
                  child: _enviando 
                    ? const CircularProgressIndicator(color: Color(0xFF000033)) 
                    : const Text("ENVIAR ENCUESTA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LÓGICA DE CONEXIÓN AL BACKEND ---
  Future<void> _enviarEncuesta() async {
    if (_puntuacion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, selecciona una puntuación.")));
      return;
    }

    setState(() => _enviando = true);

    try {
      final response = await http.put(
        Uri.parse('$urlBase/reportes/encuesta/${widget.idReporte}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'puntuacion': _puntuacion,
          'resena': _comentarioController.text,
        }),
      );

      if (response.statusCode == 200) {
        _mostrarDialogoExito();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar la encuesta ❌")));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de conexión con el Monstruo 👾")));
    } finally {
      setState(() => _enviando = false);
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000033),
        title: const Text("¡Gracias!", style: TextStyle(color: Colors.white)),
        content: const Text("Tu opinión nos ayuda a mejorar el servicio de UDI Connect.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra la alerta.
              Navigator.pop(context); // Regresa a la pantalla anterior (Lista de reportes).
            },
            child: const Text("Finalizar", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}