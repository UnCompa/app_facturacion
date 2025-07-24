import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/Categoria.dart';
import 'package:app_facturacion/models/Producto.dart';
import 'package:app_facturacion/models/ProductoPrecios.dart';
import 'package:app_facturacion/page/admin/inventory/admin__view_inventory_details_screen.dart';
import 'package:app_facturacion/page/admin/inventory/admin_create_inventory_product.dart';
import 'package:app_facturacion/routes/routes.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:app_facturacion/utils/get_image_for_bucker.dart';
import 'package:flutter/material.dart';

class AdminViewInventoryScreen extends StatefulWidget {
  const AdminViewInventoryScreen({super.key});

  @override
  _AdminViewInventoryScreenState createState() =>
      _AdminViewInventoryScreenState();
}

class _AdminViewInventoryScreenState extends State<AdminViewInventoryScreen> {
  List<Producto> _allProducts = [];
  List<Producto> _filteredProducts = [];
  List<Categoria> _categories = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String _negocioID = "";
  bool _isLoading = true;
  String _sortBy = 'nombre'; // nombre, precio, stock

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([_getProductosByNegocio(), _getCategorias()]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getProductosByNegocio() async {
    try {
      final info = await NegocioService.getCurrentUserInfo();
      final negocioId = info.negocioId;
      _negocioID = negocioId;

      final request = ModelQueries.list(
        Producto.classType,
        where: Producto.NEGOCIOID.eq(negocioId) & Producto.ISDELETED.eq(false),
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final products = response.data!.items.whereType<Producto>().toList();

        setState(() {
          _allProducts = products;
          _filteredProducts = List.from(products);
          _sortProducts();
        });
      } else if (response.errors.isNotEmpty) {
        print('Query failed: ${response.errors}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> _getCategorias() async {
    try {
      final negocioInfo = await NegocioService.getCurrentUserInfo();
      final request = ModelQueries.list(
        Categoria.classType,
        where: Categoria.NEGOCIOID.eq(negocioInfo.negocioId),
      );
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

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesName = product.nombre.toLowerCase().contains(query);
        final matchesCategory =
            _selectedCategoryId == null ||
            product.categoriaID == _selectedCategoryId;

        return matchesName && matchesCategory;
      }).toList();

      _sortProducts();
    });
  }

  void _sortProducts() {
    _filteredProducts.sort((a, b) {
      switch (_sortBy) {
        case 'precio':
          return a.precio.compareTo(b.precio);
        case 'stock':
          return a.stock.compareTo(b.stock);
        case 'nombre':
        default:
          return a.nombre.compareTo(b.nombre);
      }
    });
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return 'Sin categoría';

    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Categoria(
        nombre: 'Sin categoría',
        id: '',
        negocioID: '',
        isDeleted: false,
      ),
    );

    return category.nombre;
  }

  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 10) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStockChip(int stock) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStockColor(stock).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStockColor(stock), width: 1),
      ),
      child: Text(
        'Stock: $stock',
        style: TextStyle(
          color: _getStockColor(stock),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Gestionar Inventario'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _initializeData();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortProducts();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'nombre', child: Text('Ordenar por Nombre')),
              PopupMenuItem(value: 'precio', child: Text('Ordenar por Precio')),
              PopupMenuItem(value: 'stock', child: Text('Ordenar por Stock')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros y búsqueda
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Botón categorías
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(Routes.adminViewCategorias);
                          },
                          icon: Icon(Icons.category),
                          label: Text("Gestionar Categorías"),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      // Barra de búsqueda
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar productos...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Filtro por categoría
                      DropdownButtonFormField<String?>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Filtrar por categoría',
                          prefixIcon: Icon(Icons.filter_list),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas las categorías'),
                          ),
                          ..._categories.map((categoria) {
                            return DropdownMenuItem<String?>(
                              value: categoria.id,
                              child: Text(categoria.nombre),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                            _filterProducts();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Contador de productos
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredProducts.length} productos encontrados',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Spacer(),
                      Text(
                        'Ordenado por $_sortBy',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Lista de productos
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No se encontraron productos',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_searchController.text.isNotEmpty ||
                                  _selectedCategoryId != null)
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _selectedCategoryId = null;
                                      _filterProducts();
                                    });
                                  },
                                  child: Text('Limpiar filtros'),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AdminCreateInventoryProduct(negocioID: _negocioID),
            ),
          );

          if (result) {
            _getProductosByNegocio();
          }
        },
        label: Text("Crear Producto"),
        icon: Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(Producto product) {
    return FutureBuilder<List<ProductoPrecios>>(
      future: _getProductoPrecios(product.id),
      builder: (context, snapshot) {
        List<ProductoPrecios> precios = [];
        if (snapshot.hasData) {
          precios = snapshot.data!.where((p) => !p.isDeleted).toList();
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminViewInventoryDetailsScreen(
                    product: product,
                    negocioID: _negocioID,
                  ),
                ),
              );

              if (result == true) {
                // Refrescar la lista si se editó o eliminó un producto
                _getProductosByNegocio();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con imagen y nombre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Miniatura de la primera imagen (si existe)
                      if (product.productoImages != null &&
                          product.productoImages!.isNotEmpty)
                        FutureBuilder<List<String>>(
                          future: GetImageFromBucket.getSignedImageUrls(
                            s3Keys: [product.productoImages!.first],
                            expiresIn: Duration(minutes: 30),
                          ),
                          builder: (context, imageSnapshot) {
                            if (imageSnapshot.hasData &&
                                imageSnapshot.data!.isNotEmpty) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageSnapshot.data!.first,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey[600],
                                        size: 30,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                ),
                              );
                            }
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[600],
                                size: 30,
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[600],
                            size: 30,
                          ),
                        ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nombre,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.barCode != null &&
                                product.barCode!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Código: ${product.barCode}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStockChip(product.stock),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Descripción (si existe)
                  if (product.descripcion != null &&
                      product.descripcion!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        product.descripcion!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Información adicional
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      // Precios
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Cargando precios...',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        )
                      else if (precios.isNotEmpty)
                        ...precios.take(2).map((precio) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${precio.nombre}: \$${precio.precio.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        })
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Sin precios',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      // Categoría
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCategoryName(product.categoriaID),
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Estado
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.estado == 'activo'
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.estado?.toUpperCase() ?? 'N/A',
                          style: TextStyle(
                            color: product.estado == 'activo'
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Footer con fecha y acción
                  Row(
                    children: [
                      if (product.updatedAt != null)
                        Text(
                          'Actualizado: ${product.updatedAt!.getDateTimeInUtc().day}/${product.updatedAt!.getDateTimeInUtc().month}/${product.updatedAt!.getDateTimeInUtc().year}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<ProductoPrecios>> _getProductoPrecios(String productId) async {
    try {
      final request = ModelQueries.list(
        ProductoPrecios.classType,
        where: ProductoPrecios.PRODUCTOID
            .eq(productId)
            .and(ProductoPrecios.ISDELETED.eq(false)),
      );
      final response = await Amplify.API.query(request: request).response;
      return response.data?.items.whereType<ProductoPrecios>().toList() ?? [];
    } catch (e) {
      print('Error fetching product prices: $e');
      return [];
    }
  }
}
