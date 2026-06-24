import 'package:http/http.dart' as http;

class ApiService {
  // 1. Cambiamos la IP local por tu URL de Ngrok (asegúrate de que sea la actual)
  static const String baseURL = 'https://purposely-enlisted-overboard.ngrok-free.dev';

  Future<void> testConexion() async {
    try {
      // 2. Agregamos el header para saltar el aviso de Ngrok
      final response = await http.get(
        Uri.parse('$baseURL/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // <-- La llave maestra
        },
      );

      if (response.statusCode == 200) {
        print('Conexión exitosa: ${response.body}');
      } else {
        print('Error al conectar: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}