import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/routes/routes.dart';
import 'package:app_facturacion/services/device_session_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      debugPrint('CERRANDO SESION');
      await DeviceSessionService.closeCurrentSession();
      await Amplify.Auth.signOut();
      Navigator.of(context).pushReplacementNamed(Routes.loginPage);
    } catch (e) {
      debugPrint('ERROR AL CERRAR SESION');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        _logout(context);
      },
      child: Text(
        "Cerrar sesión",
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
      ),
    );
  }
}
