import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:app_facturacion/page/admin/admin_page.dart';
import 'package:app_facturacion/page/admin/categories/admin_categories_list_page.dart';
import 'package:app_facturacion/page/admin/inventory/admin_view_inventory_screen.dart';
import 'package:app_facturacion/page/admin/sellers/create_user_admin_page.dart';
import 'package:app_facturacion/page/admin/sellers/user_list_admin_page.dart';
import 'package:app_facturacion/page/auth/auth_check_screen.dart';
import 'package:app_facturacion/page/auth/login_page.dart';
import 'package:app_facturacion/page/auth/new_password_page.dart';
import 'package:app_facturacion/page/superadmin/negocio/create_bussines_superadmin_page.dart';
import 'package:app_facturacion/page/superadmin/negocio/negocios_superadmin_page.dart';
import 'package:app_facturacion/page/superadmin/super_admin_page.dart';
import 'package:app_facturacion/page/superadmin/user/create_user_superadmin_page.dart';
import 'package:app_facturacion/page/superadmin/user/user_list_superadmin_page.dart';
import 'package:app_facturacion/page/superadmin/user/user_superadmin_confirm_page.dart';
import 'package:app_facturacion/page/vendedor/invoice/invoice_list_page.dart';
import 'package:app_facturacion/page/vendedor/seller_page.dart';
import 'package:flutter/material.dart';

import './routes/routes.dart';
import 'amplifyconfiguration.dart';
import 'models/ModelProvider.dart';

void main()=> runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState()=> _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAmplifyConfigured = false;

  @override
  void initState(){
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify()async {
    try {
      final api = AmplifyAPI(
        options: APIPluginOptions(modelProvider: ModelProvider.instance),
      );
      final auth = AmplifyAuthCognito();
      final storage = AmplifyStorageS3();
      await Amplify.addPlugins([auth, api, storage]);
      await Amplify.configure(amplifyconfig);
      setState((){
        _isAmplifyConfigured = true;
      });
    } on Exception catch (e){
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: _isAmplifyConfigured
          ? const AuthCheckScreen()
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
      routes: {
        Routes.loginPage: (context)=> const LoginScreen(),
        Routes.loginPageWithNewPassoword: (context)=>
            const NewPasswordScreen(),
        Routes.superAdminHome: (context)=> const SuperAdminPage(),
        Routes.superAdminHomeUsers: (context)=> const UserListSuperadminPage(),
        Routes.superAdminHomeUserCrear: (context)=>
            const CreateUserSuperadminPage(),
        Routes.superAdminHomeUserConfirm: (context)=>
            const UserSuperadminConfirmPage(),
        Routes.superAdminNegocios: (context)=> const NegociosSuperadminPage(),
        Routes.superAdminNegociosCrear: (context)=> const CrearNegocioScreen(),
        Routes.adminHome: (context)=> const AdminPage(),
        Routes.adminViewInventory: (context)=>
            const AdminViewInventoryScreen(),
        Routes.adminViewCategorias: (context)=> const AdminCategoriesListPage(),
        Routes.adminViewUsers: (context)=> const UserListAdminPage(),
        Routes.adminViewUsersCrear: (context)=> const CreateUserAdminPage(),
        Routes.vendedorHome: (context)=> const SellerPage(),
        Routes.vendedorHomeFactura: (context)=> const InvoiceListScreen(),
      },
    );
  }
}
