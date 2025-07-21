import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/Categoria.dart';
import 'package:app_facturacion/models/Producto.dart';
import 'package:app_facturacion/utils/get_image_for_bucker.dart';
import 'package:flutter/material.dart';

class AdminViewInventoryDetailsScreen extends StatefulWidget {
  final Producto product;
  final String negocioID;

  const AdminViewInventoryDetailsScreen({
    super.key,
    required this.product,
    required this.negocioID,
  });

  @override
  _AdminViewInventoryDetailsScreenState createState() =>
      _AdminViewInventoryDetailsScreenState();
}

class _AdminViewInventoryDetailsScreenState
    extends State<AdminViewInventoryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  List<String> _signedImageUrls = [];
  List<Categoria> _categories = [];
  String? _selectedCategoryId;
  String? _selectedEstado;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadProductData();
  }

  void _loadProductData() {
    _nombreController.text = widget.product.nombre;
    _descripcionController.text = widget.product.descripcion ?? '';
    _precioController.text = widget.product.precio.toString();
    _stockController.text = widget.product.stock.toString();
    _selectedEstado = widget.product.estado ?? 'activo';
  }

  Future<void> _initializeData() async {
    await _getCategorias();
    if (widget.product.productoImages != null &&
        widget.product.productoImages!.isNotEmpty) {
      final urls = await GetImageFromBucket.getSignedImageUrls(
        s3Keys: widget.product.productoImages!,
        expiresIn: Duration(
          minutes: 30,
        ), // Opcional: ajusta el tiempo de expiración
      );
      if (urls.isEmpty) {
        // Manejar el error en el contexto de la UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron cargar las imágenes'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _signedImageUrls = urls;
      });
    }
  }

  Future<void> _getCategorias() async {
    try {
      final request = ModelQueries.list(Categoria.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final categories = response.data!.items.whereType<Categoria>().toList();

        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return 'Sin categoría';

    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Categoria(nombre: 'Sin categoría', id: '', negocioID: ''),
    );

    return category.nombre;
  }

  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 10) return Colors.orange;
    return Colors.green;
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProduct = widget.product.copyWith(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        precio: double.parse(_precioController.text),
        stock: int.parse(_stockController.text),
        estado: _selectedEstado,
      );

      final request = ModelMutations.update(updatedProduct);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isEditing = false;
        });

        Navigator.of(context).pop(true);
      } else {
        throw Exception('Error al actualizar el producto');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = ModelMutations.delete(widget.product);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      } else {
        throw Exception('Error al eliminar el producto');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Detalles del Producto'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (!_isEditing) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: Icon(Icons.edit),
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: _deleteProduct,
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Eliminar',
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadProductData();
                });
              },
              icon: Icon(Icons.close),
              tooltip: 'Cancelar',
            ),
            IconButton(
              onPressed: _updateProduct,
              icon: Icon(Icons.save),
              tooltip: 'Guardar',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card para imágenes e información general
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título de la sección
                            Text(
                              'Información General',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            // Carrusel de imágenes
                            if (_signedImageUrls.isNotEmpty) ...[
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _signedImageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _signedImageUrls[index],
                                          width: 180,
                                          height: 180,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 180,
                                                  height: 180,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey[600],
                                                    size: 50,
                                                  ),
                                                );
                                              },
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  width: 180,
                                                  height: 180,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 16),
                            ] else ...[
                              // Placeholder si no hay imágenes
                              Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Sin imágenes disponibles',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                            // Indicador de stock (visible solo en modo no edición)
                            if (!_isEditing)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStockColor(
                                      widget.product.stock,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStockColor(
                                        widget.product.stock,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    'Stock: ${widget.product.stock}',
                                    style: TextStyle(
                                      color: _getStockColor(
                                        widget.product.stock,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 16),
                            // Campo nombre
                            TextFormField(
                              controller: _nombreController,
                              decoration: InputDecoration(
                                labelText: 'Nombre del producto',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabled: _isEditing,
                                prefixIcon: Icon(Icons.label),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            // Campo descripción
                            TextFormField(
                              controller: _descripcionController,
                              decoration: InputDecoration(
                                labelText: 'Descripción',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabled: _isEditing,
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Card de precio y stock
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Precio y Stock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _precioController,
                                    decoration: InputDecoration(
                                      labelText: 'Precio (\$)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: Icon(Icons.attach_money),
                                      enabled: _isEditing,
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'El precio es requerido';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Ingrese un precio válido';
                                      }
                                      if (double.parse(value) < 0) {
                                        return 'El precio no puede ser negativo';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stockController,
                                    decoration: InputDecoration(
                                      labelText: 'Stock',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: Icon(Icons.inventory),
                                      enabled: _isEditing,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'El stock es requerido';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Ingrese un stock válido';
                                      }
                                      if (int.parse(value) < 0) {
                                        return 'El stock no puede ser negativo';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Card de clasificación
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clasificación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.category),
                                enabled: _isEditing,
                              ),
                              items: _categories.map((categoria) {
                                return DropdownMenuItem<String>(
                                  value: categoria.id,
                                  child: Text(categoria.nombre),
                                );
                              }).toList(),
                              onChanged: _isEditing
                                  ? (value) {
                                      setState(() {
                                        _selectedCategoryId = value;
                                      });
                                    }
                                  : null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor selecciona una categoría';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedEstado,
                              decoration: InputDecoration(
                                labelText: 'Estado',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.toggle_on),
                                enabled: _isEditing,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'activo',
                                  child: Text('Activo'),
                                ),
                                DropdownMenuItem(
                                  value: 'inactivo',
                                  child: Text('Inactivo'),
                                ),
                              ],
                              onChanged: _isEditing
                                  ? (value) {
                                      setState(() {
                                        _selectedEstado = value;
                                      });
                                    }
                                  : null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor selecciona un estado';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botón de guardar cambios (visible en modo edición)
                    if (_isEditing) ...[
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProduct,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}
