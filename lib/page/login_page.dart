import 'package:app_facturacion/page/admin_page.dart';
import 'package:app_facturacion/page/super_admin_page.dart';
import 'package:app_facturacion/views/login_form.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void navigateByRole(BuildContext context, String role) {
    if (role == 'superadmin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SuperAdminPage()),
      );
    } else if (role == 'admin') {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AdminPage()));
    }
  }


  @override
  Widget build(BuildContext context) {
    void loginHandler(String email, String password) {
      // Aquí haces el login con tu backend o Firebase
      debugPrint("Intentando login con: $email / $password");
      if (email == "superadmin@gmail.com" && password == "123456") {
        final role = "superadmin";
        navigateByRole(context, role);
      }
      if (email == "admin@gmail.com" && password == "123456") {
        final role = "admin";
        navigateByRole(context, role);
      }
    }

    return Scaffold(body: LoginForm(onLogin: loginHandler));
  }
}
