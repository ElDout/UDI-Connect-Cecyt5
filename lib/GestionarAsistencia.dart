import 'package:flutter/material.dart';
import 'diseñoapp.dart';
class PantallaGestionAsistencia extends StatelessWidget {
  const PantallaGestionAsistencia({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Marcos(
        contenido: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text("Gestionar Asistencia", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: Color.fromARGB(255, 255, 255, 255),),),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () { }, child: const Text("Cerrar Sesion"),),
          ],
        ),),
    );
  }
}