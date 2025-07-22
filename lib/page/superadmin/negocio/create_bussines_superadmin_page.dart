import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CrearNegocioScreen extends StatefulWidget {
  const CrearNegocioScreen({super.key});

  @override
  State<CrearNegocioScreen> createState()=> _CrearNegocioScreenState();
}

class _CrearNegocioScreenState extends State<CrearNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _rucController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _durationController = TextEditingController();
  final _movilAccessController = TextEditingController();
  final _pcAccessController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose(){
    _nombreController.dispose();
    _rucController.dispose();
    _telefonoController.dispose();
    _durationController.dispose();
    _movilAccessController.dispose();
    _pcAccessController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _crearNegocio()async {
    if (!_formKey.currentState!.validate())return;

    setState((){
      _isLoading = true;
    });

    try {
      const graphQLDocument = '''
        mutation CreateNegocio(\$input: CreateNegocioInput!){
          createNegocio(input: \$input){
            id
            nombre
            ruc
            telefono
            duration
            movilAccess
            pcAccess
            direccion
            createdAt
            updatedAt
          }
        }
      ''';

      final variables = <String, dynamic>{
        'input': {
          'nombre': _nombreController.text.trim(),
          'ruc': _rucController.text.trim(),
          if (_telefonoController.text.isNotEmpty)
            'telefono': _telefonoController.text.trim(),
          if (_durationController.text.isNotEmpty)
            'duration': int.tryParse(_durationController.text),
          if (_movilAccessController.text.isNotEmpty)
            'movilAccess': int.tryParse(_movilAccessController.text),
          if (_pcAccessController.text.isNotEmpty)
            'pcAccess': int.tryParse(_pcAccessController.text),
          if (_direccionController.text.isNotEmpty)
            'direccion': _direccionController.text.trim(),
        },
      };

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors){
        throw Exception('Error al crear negocio: ${response.errors}');
      }

      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Negocio creado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Limpiar formulario o navegar hacia atrás
        _limpiarFormulario();
        Navigator.of(context).pop(true); // Indica que se creó exitosamente
      }
    } catch (e){
      safePrint('Error creating business: $e');
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear negocio: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted){
        setState((){
          _isLoading = false;
        });
      }
    }
  }

  void _limpiarFormulario(){
    _nombreController.clear();
    _rucController.clear();
    _telefonoController.clear();
    _durationController.clear();
    _movilAccessController.clear();
    _pcAccessController.clear();
    _direccionController.clear();
  }

  String? _validarCampoRequerido(String? valor, String campo){
    if (valor == null || valor.trim().isEmpty){
      return '$campo es requerido';
    }
    return null;
  }

  String? _validarRuc(String? valor){
    if (valor == null || valor.trim().isEmpty){
      return 'RUC es requerido';
    }
    final ruc = valor.trim();
    if (ruc.length != 13){
      return 'RUC debe tener 13 dígitos';
    }
    if (!RegExp(r'^\d+$').hasMatch(ruc)){
      return 'RUC solo debe contener números';
    }
    return null;
  }

  String? _validarTelefono(String? valor){
    if (valor != null && valor.isNotEmpty){
      if (!RegExp(r'^\d{10}$').hasMatch(valor.trim())){
        return 'Teléfono debe tener 10 dígitos';
      }
    }
    return null;
  }

  String? _validarNumeroEntero(String? valor, String campo){
    if (valor != null && valor.isNotEmpty){
      if (int.tryParse(valor)== null){
        return '$campo debe ser un número entero';
      }
      if (int.parse(valor)< 0){
        return '$campo debe ser mayor o igual a 0';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Negocio'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado
                Card(
                  elevation: 4,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.business,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nuevo Negocio',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete la información del negocio',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Información básica
                _buildSectionTitle('Información Básica'),
                const SizedBox(height: 16),

                _buildTextFormField(
                  controller: _nombreController,
                  labelText: 'Nombre del Negocio *',
                  icon: Icons.store,
                  validator: (value)=> _validarCampoRequerido(value, 'Nombre'),
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 16),

                _buildTextFormField(
                  controller: _rucController,
                  labelText: 'RUC *',
                  icon: Icons.receipt_long,
                  validator: _validarRuc,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTextFormField(
                  controller: _telefonoController,
                  labelText: 'Teléfono',
                  icon: Icons.phone,
                  validator: _validarTelefono,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTextFormField(
                  controller: _direccionController,
                  labelText: 'Dirección',
                  icon: Icons.location_on,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 24),

                // Configuración de acceso
                _buildSectionTitle('Configuración de Acceso'),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _durationController,
                        labelText: 'Duración (días)',
                        icon: Icons.schedule,
                        validator: (value)=>
                            _validarNumeroEntero(value, 'Duración'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextFormField(
                        controller: _movilAccessController,
                        labelText: 'Acceso Móvil',
                        icon: Icons.smartphone,
                        validator: (value)=>
                            _validarNumeroEntero(value, 'Acceso Móvil'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTextFormField(
                  controller: _pcAccessController,
                  labelText: 'Acceso PC',
                  icon: Icons.computer,
                  validator: (value)=>
                      _validarNumeroEntero(value, 'Acceso PC'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                const SizedBox(height: 32),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _limpiarFormulario,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text(
                          'Limpiar',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _crearNegocio,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Creando...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
)
                            : const Text(
                                'Crear Negocio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los campos marcados con (*)son obligatorios',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title){
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }){
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
