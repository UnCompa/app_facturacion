import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UsersSuperadminPage extends StatefulWidget {
  const UsersSuperadminPage({super.key});

  @override
  State<UsersSuperadminPage> createState() => _UsersSuperadminPageState();
}

class _UsersSuperadminPageState extends State<UsersSuperadminPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _roles = ['superadmin', 'admin', 'vendedor'];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> signUpUser({
    required String username,
    required String password,
    required String email,
    String? phoneNumber,
    required String role,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userAttributes = {
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          AuthUserAttributeKey.phoneNumber: phoneNumber,
        CognitoUserAttributeKey.custom('role'): role,
      };
      print("REGISTRANDO USUARIO");
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );
      print("ASIGNANDO ROL");
      print(role);
      print(email);
      await assignUserToGroup(email, role);
      print("MANEJANDO RESULTADO");
      await _handleSignUpResult(result);
    } on AuthException catch (e) {
      safePrint('Error signing up user: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar usuario: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<JsonWebToken?> getIdTokenSimple() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (session.isSignedIn) {
        final cognitoSession = session as CognitoAuthSession;
        final tokens = cognitoSession.userPoolTokensResult.value;
        return tokens.idToken;
      }
      return null;
    } catch (e) {
      print('Error al obtener ID token: $e');
      return null;
    }
  }

  Future<void> assignUserToGroup(String email, String group) async {
    var idToken = await getIdTokenSimple();

    if (idToken == null) {
      print('No se pudo obtener el token');
      return;
    }

    final uri = Uri.parse(
      "https://hwmfv41ks4.execute-api.us-east-1.amazonaws.com/dev/admin-assign",
    );
    print(idToken.raw);
    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        'Authorization': idToken.raw,
      }, // El valor crudo del token},
      body: jsonEncode({"username": email, "groupName": group}),
    );

    if (response.statusCode == 200) {
      print("Usuario asignado correctamente");
    } else {
      print("Error al asignar usuario: ${response.body}");
    }
  }

  Future<void> _handleSignUpResult(SignUpResult result) async {
    switch (result.nextStep.signUpStep) {
      case AuthSignUpStep.confirmSignUp:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se requiere confirmación. Revisa tu email.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pushNamed("/superadmin/users/confirm");
        }
        break;
      case AuthSignUpStep.done:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario registrado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _clearForm();
        }
        break;
    }
  }

  void _clearForm() {
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    setState(() {
      _selectedRole = null;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await signUpUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _selectedRole!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Crear Nuevo Usuario',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El email es requerido';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.length < 8) {
                    return 'Mínimo 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value.trim())) {
                      return 'Formato de teléfono inválido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role[0].toUpperCase() + role.substring(1)),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Rol del usuario *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.supervised_user_circle),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Debe seleccionar un rol' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Registrando...'),
                        ],
                      )
                    : const Text(
                        'Registrar Usuario',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _isLoading ? null : _clearForm,
                child: const Text('Limpiar Formulario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
