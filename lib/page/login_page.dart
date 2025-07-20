import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/page/admin_page.dart';
import 'package:app_facturacion/views/login_form.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> signInUser(
    BuildContext context,
    String username,
    String password,
  ) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      print(session);
      // Si ya hay un usuario autenticado, cerramos sesión primero
      if (session.isSignedIn) {
        await Amplify.Auth.signOut();
      }

      final result = await Amplify.Auth.signIn(
        username: username,
        password: password,
      );

      if (result.isSignedIn) {
        await _navigateByUserRole(context);
      } else {
        await _handleSignInResult(context, result);
      }
    } on AuthException catch (e) {
      _showErrorDialog(context, 'Error al iniciar sesión: ${e.message}');
    }
  }

  Future<void> _handleSignInResult(
    BuildContext context,
    SignInResult result,
  ) async {
    switch (result.nextStep.signInStep) {
      case AuthSignInStep.confirmSignInWithSmsMfaCode:
      case AuthSignInStep.confirmSignInWithNewPassword:
      case AuthSignInStep.confirmSignInWithCustomChallenge:
      case AuthSignInStep.confirmSignUp:
      case AuthSignInStep.resetPassword:
        _showErrorDialog(
          context,
          'Se requiere acción adicional: ${result.nextStep.signInStep.name}',
        );
        break;

      case AuthSignInStep.done:
        await _navigateByUserRole(context);
        break;

      default:
        _showErrorDialog(
          context,
          'Paso de autenticación no implementado: ${result.nextStep.signInStep.name}',
        );
    }
  }

  Future<void> _navigateByUserRole(BuildContext context) async {
    try {
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
          _showErrorDialog(context, 'Rol no autorizado: $role');
      }
    } on AuthException catch (e) {
      _showErrorDialog(
        context,
        'No se pudieron obtener los atributos del usuario: ${e.message}',
      );
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginForm(
        onLogin: (email, password) {
          debugPrint("Intentando login con: $email / $password");
          signInUser(context, email, password);
        },
      ),
    );
  }
}
