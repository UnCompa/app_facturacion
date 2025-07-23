import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/Categoria.dart';
import 'package:app_facturacion/models/Producto.dart';
import 'package:app_facturacion/models/ProductoPrecios.dart';
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
  final _barCodeController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _stockController = TextEditingController();
  List<Map<String, TextEditingController>> _preciosControllers = [];
  List<String> _signedImageUrls = [];
  List<Categoria> _categories = [];
  List<ProductoPrecios> _productoPrecios = [];
  String? _selectedCategoryId;
  String? _selectedEstado;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoadingImages = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadProductData();
  }

  void _loadProductData() {
    _nombreController.text = widget.product.nombre;
    _descripcionController.text = widget.product.descripcion ?? '';
    _stockController.text = widget.product.stock.toString();
    _selectedEstado = widget.product.estado ?? 'activo';
    _barCodeController.text = widget.product.barCode ?? '';
    _selectedCategoryId = widget.product.categoriaID;
  }

  Future<void> _initializeData() async {
    await _getCategorias();
    await _getProductoPrecios();
    if (widget.product.productoImages != null &&
        widget.product.productoImages!.isNotEmpty) {
      final urls = await GetImageFromBucket.getSignedImageUrls(
        s3Keys: widget.product.productoImages!,
        expiresIn: Duration(minutes: 30),
      );
      if (urls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron cargar las imágenes'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _signedImageUrls = urls;
        _isLoadingImages = false;
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

  Future<void> _getProductoPrecios() async {
    try {
      final request = ModelQueries.list(
        ProductoPrecios.classType,
        where: ProductoPrecios.PRODUCTOID
            .eq(widget.product.id)
            .and(ProductoPrecios.ISDELETED.eq(false)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final precios = response.data!.items
            .whereType<ProductoPrecios>()
            .toList();
        setState(() {
          _productoPrecios = precios;
          _preciosControllers = precios.map((precio) {
            return {
              'id': TextEditingController(text: precio.id),
              'nombre': TextEditingController(text: precio.nombre),
              'precio': TextEditingController(text: precio.precio.toString()),
            };
          }).toList();
          if (_preciosControllers.isEmpty) {
            _agregarPrecio();
          }
        });
      }
    } catch (e) {
      print('Error fetching product prices: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los precios'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _agregarPrecio() {
    setState(() {
      _preciosControllers.add({
        'id': TextEditingController(),
        'nombre': TextEditingController(),
        'precio': TextEditingController(),
      });
    });
  }

  void _eliminarPrecio(int index) {
    setState(() {
      _preciosControllers[index]['id']!.dispose();
      _preciosControllers[index]['nombre']!.dispose();
      _preciosControllers[index]['precio']!.dispose();
      _preciosControllers.removeAt(index);
    });
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
      // Actualizar el producto
      final updatedProduct = widget.product.copyWith(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        stock: int.parse(_stockController.text),
        estado: _selectedEstado,
        categoriaID: _selectedCategoryId,
        barCode: _barCodeController.text.trim().isEmpty
            ? null
            : _barCodeController.text.trim(),
        createdAt: widget.product.createdAt,
        updatedAt: TemporalDateTime(DateTime.now()),
      );

      final productRequest = ModelMutations.update(updatedProduct);
      final productResponse = await Amplify.API
          .mutate(request: productRequest)
          .response;

      if (productResponse.data == null) {
        throw Exception(
          'Error al actualizar el producto: ${productResponse.errors}',
        );
      }

      // Validar precios
      for (var precio in _preciosControllers) {
        if (precio['nombre']!.text.trim().isEmpty ||
            precio['precio']!.text.trim().isEmpty) {
          throw Exception('Todos los campos de precios deben estar completos');
        }
        final valorPrecio = double.tryParse(precio['precio']!.text);
        if (valorPrecio == null || valorPrecio <= 0) {
          throw Exception('Todos los precios deben ser válidos y mayores a 0');
        }
      }

      // Actualizar o crear precios
      for (var precio in _preciosControllers) {
        final precioId = precio['id']!.text;
        final productoPrecio = ProductoPrecios(
          id: precioId.isNotEmpty ? precioId : null,
          nombre: precio['nombre']!.text.trim(),
          precio: double.parse(precio['precio']!.text),
          negocioID: widget.negocioID,
          productoID: widget.product.id,
          isDeleted: false,
        );

        final precioRequest = precioId.isNotEmpty
            ? ModelMutations.update(productoPrecio)
            : ModelMutations.create(productoPrecio);
        final precioResponse = await Amplify.API
            .mutate(request: precioRequest)
            .response;

        if (precioResponse.data == null) {
          throw Exception(
            'Error al guardar el precio: ${precioResponse.errors}',
          );
        }
      }

      // Eliminar precios que ya no están en la lista
      for (var precioExistente in _productoPrecios) {
        if (!_preciosControllers.any(
          (p) => p['id']!.text == precioExistente.id,
        )) {
          final deleteRequest = ModelMutations.delete(
            precioExistente.copyWith(isDeleted: true),
          );
          final deleteResponse = await Amplify.API
              .mutate(request: deleteRequest)
              .response;
          if (deleteResponse.data == null) {
            throw Exception(
              'Error al eliminar el precio: ${deleteResponse.errors}',
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto y precios actualizados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isEditing = false;
      });

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Detalles del Producto'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
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
                  _getProductoPrecios();
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
                            if (_isLoadingImages)
                              Center(child: CircularProgressIndicator())
                            else if (_signedImageUrls.isNotEmpty && !_isLoadingImages) ...[
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
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
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
                            SizedBox(height: 16),
                            // Campo código de barras
                            TextFormField(
                              controller: _barCodeController,
                              decoration: InputDecoration(
                                labelText: 'Código de barras',
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
                                prefixIcon: Icon(Icons.barcode_reader),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Card de precios y stock
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
                              'Precios y Stock',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            // Lista de precios
                            if (_isEditing)
                              Column(
                                children: [
                                  ..._preciosControllers.asMap().entries.map((
                                    entry,
                                  ) {
                                    int index = entry.key;
                                    var controllers = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: controllers['nombre'],
                                              decoration: InputDecoration(
                                                labelText: 'Nombre del Precio',
                                                hintText: 'Ej: Público',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.blue,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                prefixIcon: Icon(Icons.label),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'El nombre es obligatorio';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: controllers['precio'],
                                              decoration: InputDecoration(
                                                labelText: 'Precio',
                                                hintText: 'Ej: 999.99',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.blue,
                                                        width: 2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                prefixIcon: Icon(
                                                  Icons.attach_money,
                                                ),
                                                suffixText: 'USD',
                                              ),
                                              keyboardType:
                                                  TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'El precio es obligatorio';
                                                }
                                                final precio = double.tryParse(
                                                  value,
                                                );
                                                if (precio == null) {
                                                  return 'Ingresa un precio válido';
                                                }
                                                if (precio <= 0) {
                                                  return 'El precio debe ser mayor a 0';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            onPressed:
                                                _preciosControllers.length > 1
                                                ? () => _eliminarPrecio(index)
                                                : null,
                                            icon: Icon(Icons.delete),
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  ElevatedButton.icon(
                                    onPressed: _agregarPrecio,
                                    icon: Icon(Icons.add),
                                    label: Text('Agregar otro precio'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _productoPrecios.isNotEmpty
                                    ? _productoPrecios.map((precio) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                precio.nombre,
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              Text(
                                                '\$${precio.precio.toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList()
                                    : [
                                        Text(
                                          'Sin precios disponibles',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                              ),
                            SizedBox(height: 16),
                            // Campo stock
                            TextFormField(
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
                                if (value == null || value.trim().isEmpty) {
                                  return 'El stock es requerido';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Ingresa un stock válido';
                                }
                                if (int.parse(value) < 0) {
                                  return 'El stock no puede ser negativo';
                                }
                                return null;
                              },
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
    _stockController.dispose();
    _barCodeController.dispose();
    for (var precio in _preciosControllers) {
      precio['id']!.dispose();
      precio['nombre']!.dispose();
      precio['precio']!.dispose();
    }
    super.dispose();
  }
}
