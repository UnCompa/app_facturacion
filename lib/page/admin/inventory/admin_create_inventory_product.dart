import 'dart:io';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
// Importa tus modelos generados de Amplify
// import 'models/ModelProvider.dart';

class AdminCreateInventoryProduct extends StatefulWidget {
  final String negocioID; // ID del negocio al que pertenece el producto

  const AdminCreateInventoryProduct({super.key, required this.negocioID});

  @override
  State<AdminCreateInventoryProduct> createState() =>
      _AdminCreateInventoryProductState();
}

class _AdminCreateInventoryProductState
    extends State<AdminCreateInventoryProduct> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingCategorias = true;
  bool _isUploadingImages = false;

  // Listas y variables para categorías
  List<Categoria> _categorias = [];
  List<Categoria> _categoriasFiltradas = [];
  Categoria? _categoriaSeleccionada;

  // Variables para imágenes
  List<File> _imagenesSeleccionadas = [];
  final List<String> _imagenesUploadedKeys = [];
  final ImagePicker _picker = ImagePicker();

  // Estado del producto
  String _estadoSeleccionado = 'activo';
  final List<String> _estadosDisponibles = ['activo', 'inactivo', 'agotado'];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      // Cargar categorías principales (sin categoría padre)
      final request = ModelQueries.list(
        Categoria.classType,
        //where: Categoria.PARENTCATEGORIAID.ne(null),
      );
      final response = await Amplify.API.query(request: request).response;
      print(response.data?.items);
      if (response.data?.items != null) {
        setState(() {
          _categorias = response.data!.items.whereType<Categoria>().toList();
          _categoriasFiltradas = _categorias;
          _isLoadingCategorias = false;
        });
      }
    } catch (e) {
      safePrint('Error cargando categorías: $e');
      setState(() {
        _isLoadingCategorias = false;
      });
      _mostrarError('Error al cargar las categorías');
    }
  }

  Future<void> _seleccionarImagenes() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // Limitar a máximo 5 imágenes
        final imagenesAUsar = images.take(5).toList();

        setState(() {
          _imagenesSeleccionadas = imagenesAUsar
              .map((xfile) => File(xfile.path))
              .toList();
        });
      }
    } catch (e) {
      safePrint('Error seleccionando imágenes: $e');
      _mostrarError('Error al seleccionar las imágenes');
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (_imagenesSeleccionadas.length < 5) {
            _imagenesSeleccionadas.add(File(image.path));
          }
        });
      }
    } catch (e) {
      safePrint('Error tomando foto: $e');
      _mostrarError('Error al tomar la foto');
    }
  }

  void _eliminarImagen(int index) {
    setState(() {
      _imagenesSeleccionadas.removeAt(index);
    });
  }

  Future<List<String>> _subirImagenes() async {
    if (_imagenesSeleccionadas.isEmpty) {
      return [];
    }

    setState(() {
      _isUploadingImages = true;
    });

    List<String> uploadedKeys = [];
    const uuid = Uuid();

    try {
      for (int i = 0; i < _imagenesSeleccionadas.length; i++) {
        final file = _imagenesSeleccionadas[i];
        final extension = file.path.split('.').last.toLowerCase();
        final keyPath = 'productos/${uuid.v4()}.$extension';

        final uploadResult = await Amplify.Storage.uploadFile(
          localFile: AWSFile.fromPath(file.path),
          path: StoragePath.fromString(keyPath),
          options: const StorageUploadFileOptions(
            metadata: {'tipo': 'producto_imagen'},
          ),
        ).result;

        uploadedKeys.add(uploadResult.uploadedItem.path);
        safePrint('Imagen subida: ${uploadResult.uploadedItem.path}');
      }
    } catch (e) {
      safePrint('Error subiendo imágenes: $e');
      _mostrarError('Error al subir las imágenes');
      return [];
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }

    return uploadedKeys;
  }

  Future<void> _crearProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSeleccionada == null) {
      _mostrarError('Por favor selecciona una categoría');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Primero subir las imágenes
      List<String> imageKeys = [];
      if (_imagenesSeleccionadas.isNotEmpty) {
        imageKeys = await _subirImagenes();
        if (imageKeys.isEmpty && _imagenesSeleccionadas.isNotEmpty) {
          // Si falló la subida de imágenes, no continuar
          return;
        }
      }

      // Crear instancia del producto
      final categoria = Categoria(
        id: _categoriaSeleccionada!.id,
        nombre: _categoriaSeleccionada!.nombre,
      );
      final producto = Producto(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        precio: double.parse(_precioController.text),
        stock: int.parse(_stockController.text),
        negocioID: widget.negocioID,
        categoria: categoria,
        estado: _estadoSeleccionado,
        productoImages: imageKeys.isEmpty ? null : imageKeys,
      );

      // Crear la mutación
      final request = ModelMutations.create(producto);
      final response = await Amplify.API.mutate(request: request).response;

      final createdProducto = response.data;

      if (createdProducto == null) {
        safePrint('Errores al crear producto: ${response.errors}');
        _mostrarError('Error al crear el producto. Intenta de nuevo.');
        return;
      }

      safePrint('Producto creado exitosamente: ${createdProducto.nombre}');

      // Mostrar mensaje de éxito y regresar
      _mostrarExito('Producto creado exitosamente');

      // Esperar un momento para mostrar el mensaje y luego regresar
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(createdProducto);
      }
    } on ApiException catch (e) {
      safePrint('Error en la mutación: $e');
      _mostrarError(
        'Error de conexión. Verifica tu internet e intenta de nuevo.',
      );
    } catch (e) {
      safePrint('Error inesperado: $e');
      _mostrarError('Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Producto'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto *',
                  hintText: 'Ej: iPhone 15 Pro',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              // Campo Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  hintText: 'Describe las características del producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

              // Selector de Categoría
              _isLoadingCategorias
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : DropdownButtonFormField<Categoria>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      hint: const Text('Selecciona una categoría'),
                      items: _categoriasFiltradas.map((categoria) {
                        return DropdownMenuItem<Categoria>(
                          value: categoria,
                          child: Text(categoria.nombre),
                        );
                      }).toList(),
                      onChanged: (Categoria? newValue) {
                        setState(() {
                          _categoriaSeleccionada = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una categoría';
                        }
                        return null;
                      },
                    ),

              const SizedBox(height: 16),

              // Campo Precio
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  hintText: 'Ej: 999.99',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'USD',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final precio = double.tryParse(value);
                  if (precio == null) {
                    return 'Ingresa un precio válido';
                  }
                  if (precio <= 0) {
                    return 'El precio debe ser mayor a 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo Stock
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock *',
                  hintText: 'Ej: 10',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                  suffixText: 'unidades',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El stock es obligatorio';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null) {
                    return 'Ingresa un stock válido';
                  }
                  if (stock < 0) {
                    return 'El stock no puede ser negativo';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Selector de Estado
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.toggle_on),
                ),
                items: _estadosDisponibles.map((estado) {
                  return DropdownMenuItem<String>(
                    value: estado,
                    child: Text(estado.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _estadoSeleccionado = newValue!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Sección de Imágenes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Imágenes del Producto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botones para agregar imágenes
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _seleccionarImagenes,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galería'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _tomarFoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Cámara'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Vista previa de imágenes
                      if (_imagenesSeleccionadas.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imagenesSeleccionadas.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _imagenesSeleccionadas[index],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _eliminarImagen(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      if (_imagenesSeleccionadas.isEmpty)
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Sin imágenes seleccionadas\n(Máximo 5 imágenes)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón Crear
              ElevatedButton(
                onPressed: (_isLoading || _isUploadingImages)
                    ? null
                    : _crearProducto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: (_isLoading || _isUploadingImages)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isUploadingImages
                                ? 'Subiendo imágenes...'
                                : 'Creando producto...',
                          ),
                        ],
                      )
                    : const Text(
                        'Crear Producto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 12),

              // Botón Cancelar
              OutlinedButton(
                onPressed: (_isLoading || _isUploadingImages)
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
