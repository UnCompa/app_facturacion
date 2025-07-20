import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/page/admin/user/create_user_superadmin_page.dart';
import 'package:app_facturacion/page/admin/user/user_superadmin_confirm_page.dart';
import 'package:app_facturacion/page/auth_check_screen.dart';
import 'package:app_facturacion/page/login_page.dart';
import 'package:app_facturacion/page/super_admin_page.dart';
import 'package:flutter/material.dart';

import './routes/routes.dart';
import 'amplifyconfiguration.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);

      // call Amplify.configure to use the initialized categories in your app
      await Amplify.configure(amplifyconfig);
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const AuthCheckScreen(),
      routes: {
        Routes.loginPage: (context) => const LoginScreen(),
        Routes.superAdminHome: (context) => const SuperAdminPage(),
        Routes.superAdminHomeUsers: (context) => const UsersSuperadminPage(),
        Routes.superAdminHomeUserConfirm: (context) => const UserSuperadminConfirmPage(),
      },
    );
  }
}
