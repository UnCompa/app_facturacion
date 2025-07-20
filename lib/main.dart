import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/page/admin/negocio/create_bussines_superadmin_page.dart';
import 'package:app_facturacion/page/admin/negocio/negocios_superadmin_page.dart';
import 'package:app_facturacion/page/admin/user/create_user_superadmin_page.dart';
import 'package:app_facturacion/page/admin/user/user_superadmin_confirm_page.dart';
import 'package:app_facturacion/page/admin_page.dart';
import 'package:app_facturacion/page/auth/new_password_page.dart';
import 'package:app_facturacion/page/login_page.dart';
import 'package:app_facturacion/page/super_admin_page.dart';
import 'package:flutter/material.dart';

import './routes/routes.dart';
import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';

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
    final api = AmplifyAPI(
      options: APIPluginOptions(modelProvider: ModelProvider.instance),
    );
    await Amplify.addPlugin(api);
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);
    try {
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
      home: const LoginScreen(),
      routes: {
        Routes.loginPage: (context) => const LoginScreen(),
        Routes.loginPageWithNewPassoword: (context) =>
            const NewPasswordScreen(),
        Routes.superAdminHome: (context) => const SuperAdminPage(),
        Routes.superAdminHomeUsers: (context) => const UsersSuperadminPage(),
        Routes.superAdminHomeUserConfirm: (context) =>
            const UserSuperadminConfirmPage(),
        Routes.adminHome: (context) => const AdminPage(),
        Routes.superAdminNegocios: (context) => const NegociosSuperadminPage(),
        Routes.superAdminNegociosCrear: (context) => const CrearNegocioScreen(),
      },
    );
  }
}
