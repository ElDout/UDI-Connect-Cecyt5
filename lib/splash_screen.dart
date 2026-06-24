import 'package:flutter/material.dart';

class PantallaPresentacion extends StatefulWidget {
  const PantallaPresentacion({super.key});
  @override 
  State<PantallaPresentacion> createState() => _PantallaPresentacionState();
}

class _PantallaPresentacionState extends State<PantallaPresentacion> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Animación de aparición
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    bool esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: esOscuro ? const Color(0xFF000033) : const Color(0xFF800000),
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 2),
          child: const Text(
            "UDI CONNECT",
            style: TextStyle(
              fontSize: 40,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}