import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/page/admin/admin_page.dart';
import 'package:flutter/material.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAuth();
  }

  Future<void> _checkUserAuth() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (session.isSignedIn) {
        final userAttributes = await Amplify.Auth.fetchUserAttributes();

        final roleAttr = userAttributes.firstWhere(
          (attr) => attr.userAttributeKey.key == 'custom:role',
          orElse: () => const AuthUserAttribute(
            userAttributeKey: CognitoUserAttributeKey.custom('role'),
            value: 'unknown',
          ),
        );

        final role = roleAttr.value.toLowerCase();

        switch (role) {
          case 'superadmin':
            Navigator.of(context).pushReplacementNamed('/superadmin');
            break;
          case 'admin':
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminPage()),
            );
            break;
          default:
            _goToLogin(); // Rol inválido
        }
      } else {
        _goToLogin();
      }
    } on AuthException catch (e) {
      debugPrint("Error verificando sesión: ${e.message}");
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
