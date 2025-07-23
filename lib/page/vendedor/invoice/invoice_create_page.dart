import 'dart:io';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:app_facturacion/services/caja_service.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:app_facturacion/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _scrollController = ScrollController();

  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'Pagada';
  List<Producto> _productos = [];
  Map<String, List<ProductoPrecios>> _productoPrecios = {};
  final List<InvoiceItemData> _invoiceItems = [];
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  final List<File> _invoiceImagesFiles = [];

  final List<String> _statusOptions = [
    'Pendiente',
    'Pagada',
    'Vencida',
    'Cancelada',
  ];

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    _loadProducts();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMddHHmm').format(now);
    _invoiceNumberController.text = 'INV-$timestamp';
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final userData = await NegocioService.getCurrentUserInfo();
      final request = ModelQueries.list(
        Producto.classType,
        where: Producto.NEGOCIOID
            .eq(userData.negocioId)
            .and(Producto.STOCK.gt(0)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final productos = response.data!.items.whereType<Producto>().toList();
        final preciosMap = <String, List<ProductoPrecios>>{};
        for (var producto in productos) {
          final precioRequest = ModelQueries.list(
            ProductoPrecios.classType,
            where: ProductoPrecios.PRODUCTOID
                .eq(producto.id)
                .and(ProductoPrecios.ISDELETED.eq(false)),
          );
          final precioResponse = await Amplify.API
              .query(request: precioRequest)
              .response;
          preciosMap[producto.id] =
              precioResponse.data?.items
                  .whereType<ProductoPrecios>()
                  .toList() ??
              [];
        }

        setState(() {
          _productos = productos;
          _productoPrecios = preciosMap;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar productos: $e')));
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  double _calculateTotal() {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.total);
  }

  void _addInvoiceItem() {
    if (_productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles')),
      );
      return;
    }

    final producto = _productos.first;
    final precios = _productoPrecios[producto.id] ?? [];
    final precioSeleccionado = precios.isNotEmpty ? precios.first : null;

    setState(() {
      _invoiceItems.add(
        InvoiceItemData(
          producto: producto,
          precio: precioSeleccionado,
          quantity: 1,
          tax: 0,
        ),
      );
    });
  }

  void _removeInvoiceItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe agregar al menos un producto')),
      );
      return;
    }

    for (var item in _invoiceItems) {
      if (item.precio == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Todos los productos deben tener un precio seleccionado',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener información del usuario y caja activa
      final userData = await NegocioService.getCurrentUserInfo();
      final caja = await CajaService.getCurrentCaja();

      // Validar que la caja esté activa
      if (!caja.isActive) {
        throw Exception('La caja no está activa');
      }

      // Subir imágenes a S3 (asumiendo que tienes una lista de archivos _invoiceImagesFiles)
      List<String> invoiceImages = [];
      if (_invoiceImagesFiles.isNotEmpty) {
        for (var imageFile in _invoiceImagesFiles) {
          final imageUrl = await StorageService.uploadFile(
            imageFile,
            'invoices/${userData.negocioId}/${caja.id}/${DateTime.now().toIso8601String()}',
          );
          invoiceImages.add(imageUrl);
        }
      }

      // Crear la factura
      final invoice = Invoice(
        invoiceNumber: _invoiceNumberController.text,
        invoiceDate: TemporalDateTime(_selectedDate),
        invoiceTotal: _calculateTotal(),
        invoiceStatus: _selectedStatus,
        sellerID: userData.userId,
        negocioID: userData.negocioId,
        cajaID: caja.id,
        invoiceImages: invoiceImages,
        isDeleted: false,
      );

      // Guardar la factura
      final createInvoiceRequest = ModelMutations.create(invoice);
      final invoiceResponse = await Amplify.API
          .mutate(request: createInvoiceRequest)
          .response;
      if (invoiceResponse.data == null) {
        throw Exception('Error al crear la factura: ${invoiceResponse.errors}');
      }
      final createdInvoice = invoiceResponse.data!;

      // Crear los items de la factura
      for (final itemData in _invoiceItems) {
        final invoiceItem = InvoiceItem(
          invoiceID: createdInvoice.id,
          productoID: itemData.producto.id,
          quantity: itemData.quantity,
          tax: itemData.tax,
          subtotal: itemData.subtotal,
          total: itemData.total,
        );

        final createItemRequest = ModelMutations.create(invoiceItem);
        final itemResponse = await Amplify.API
            .mutate(request: createItemRequest)
            .response;
        if (itemResponse.data == null) {
          throw Exception(
            'Error al crear item de factura: ${itemResponse.errors}',
          );
        }

        // Actualizar el stock del producto
        final updatedProduct = itemData.producto.copyWith(
          stock: itemData.producto.stock - itemData.quantity,
        );
        final updateProductRequest = ModelMutations.update(updatedProduct);
        final productResponse = await Amplify.API
            .mutate(request: updateProductRequest)
            .response;
        if (productResponse.data == null) {
          throw Exception(
            'Error al actualizar stock del producto: ${productResponse.errors}',
          );
        }
      }

      // Generar movimiento de caja
      final movement = CajaMovimiento(
        cajaID: caja.id,
        tipo: 'INGRESO',
        origen: 'FACTURA', // Usar el campo propuesto
        monto: _calculateTotal(),
        negocioID: userData.negocioId,
        descripcion: 'Ingreso por factura ID: ${createdInvoice.id}',
        isDeleted: false,
      );
      final createMovementRequest = ModelMutations.create(movement);
      final movementResponse = await Amplify.API
          .mutate(request: createMovementRequest)
          .response;
      if (movementResponse.data == null) {
        throw Exception(
          'Error al crear movimiento de caja: ${movementResponse.errors}',
        );
      }
      final createdMovement = movementResponse.data!;

      // Actualizar la factura con el ID del movimiento
      final updatedInvoice = createdInvoice.copyWith(
        cajaMovimientoID: createdMovement.id,
      );
      final updateInvoiceRequest = ModelMutations.update(updatedInvoice);
      final updateInvoiceResponse = await Amplify.API
          .mutate(request: updateInvoiceRequest)
          .response;
      if (updateInvoiceResponse.data == null) {
        throw Exception(
          'Error al actualizar factura con movimiento: ${updateInvoiceResponse.errors}',
        );
      }

      // TODO: Recalcular monedas (CajaMoneda)
      // Ejemplo (depende de tu lógica de negocio):
      // for (var moneda in _selectedMonedas) {
      //   final cajaMoneda = CajaMoneda(
      //     cajaID: caja.id,
      //     negocioID: userData.negocioId,
      //     moneda: 'USD',
      //     denominacion: moneda.denominacion,
      //     cantidad: moneda.cantidad,
      //     isDeleted: false,
      //   );
      //   final createMonedaRequest = ModelMutations.create(cajaMoneda);
      //   await Amplify.API.mutate(request: createMonedaRequest).response;
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura creada exitosamente')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear la factura: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanBarcode(BuildContext context) async {
    try {
      final result = await SimpleBarcodeScanner.scanBarcode(
        context,
        barcodeAppBar: const BarcodeAppBar(
          appBarTitle: 'Escanear Código de Barras',
          centerTitle: false,
          enableBackButton: true,
          backButtonIcon: Icon(Icons.arrow_back_ios),
        ),
        isShowFlashIcon: true,
        delayMillis: 2000,
        cameraFace: CameraFace.front,
      );
      if (result != null && result != '-1') {
        await _getProductByBarCode(result);
      }
    } catch (e) {
      print('Error al escanear: $e');
    }
  }

  Future<void> _getProductByBarCode(String barCode) async {
    try {
      final request = ModelQueries.list(
        Producto.classType,
        where: Producto.BARCODE.eq(barCode),
      );
      final response = await Amplify.API.query(request: request).response;

      final productos = response.data?.items.whereType<Producto>().toList();

      if (productos != null && productos.isNotEmpty) {
        final producto = productos.first;

        // Verifica si ya fue agregado
        final yaAgregado = _invoiceItems.any(
          (item) => item.producto.id == producto.id,
        );
        if (yaAgregado) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Este producto ya fue agregado')),
          );
          return;
        }

        if (producto.stock <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Este producto no tiene stock disponible')),
          );
          return;
        }

        final precios = _productoPrecios[producto.id] ?? [];
        final precioSeleccionado = precios.isNotEmpty ? precios.first : null;

        setState(() {
          _invoiceItems.add(
            InvoiceItemData(
              producto: producto,
              precio: precioSeleccionado,
              quantity: 1,
              tax: 0,
            ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto agregado: ${producto.nombre}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró ningún producto con ese código de barras',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error al obtener el producto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener el producto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Factura'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveInvoice,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      buildItemsSection(),
                      const SizedBox(height: 24),
                      buildTotalSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addInvoiceItem,
        tooltip: 'Agregar producto',
        label: const Text('Agregar producto'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información básica',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(
                labelText: 'Número de factura',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el número de factura';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de factura',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Productos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${_invoiceItems.length} items',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await _scanBarcode(context);
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Escanear código de barras',
                ),
                Text(
                  'Código de barras',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_invoiceItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay productos agregados',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Presiona el botón + para agregar productos',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoiceItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return buildInvoiceItemCard(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget buildInvoiceItemCard(int index) {
    final item = _invoiceItems[index];
    final precios = _productoPrecios[item.producto.id] ?? [];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Producto>(
                    value: item.producto,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 24,
                      ),
                    ),
                    items: _productos.map((producto) {
                      return DropdownMenuItem(
                        value: producto,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Stock: ${producto.stock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (producto) {
                      final nuevosPrecios =
                          _productoPrecios[producto!.id] ?? [];
                      final precioSeleccionado = nuevosPrecios.isNotEmpty
                          ? nuevosPrecios.first
                          : null;
                      setState(() {
                        _invoiceItems[index] = item.copyWith(
                          producto: producto,
                          precio: precioSeleccionado,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeInvoiceItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductoPrecios>(
              value: item.precio,
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: precios.map((precio) {
                return DropdownMenuItem(
                  value: precio,
                  child: Text(
                    '${precio.nombre}: \$${precio.precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (precio) {
                setState(() {
                  _invoiceItems[index] = item.copyWith(precio: precio);
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Seleccione un precio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 1;
                      if (quantity > item.producto.stock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Stock insuficiente. Disponible: ${item.producto.stock}',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _invoiceItems[index] = item.copyWith(
                          quantity: quantity,
                        );
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese la cantidad';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'La cantidad debe ser mayor a 0';
                      }
                      if (quantity > item.producto.stock) {
                        return 'Stock insuficiente';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.tax.toString(),
                    decoration: const InputDecoration(
                      labelText: 'IVA (%)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final tax = int.tryParse(value) ?? 0;
                      setState(() {
                        _invoiceItems[index] = item.copyWith(tax: tax);
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el IVA';
                      }
                      final tax = int.tryParse(value);
                      if (tax == null || tax < 0) {
                        return 'El IVA debe ser un número no negativo';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTotalSection() {
    final total = _calculateTotal();

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total de la factura:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceItemData {
  final Producto producto;
  final ProductoPrecios? precio;
  final int quantity;
  final int tax;

  InvoiceItemData({
    required this.producto,
    this.precio,
    required this.quantity,
    required this.tax,
  });

  double get subtotal => precio != null ? precio!.precio * quantity : 0.0;
  double get total => subtotal + (subtotal * tax / 100);

  InvoiceItemData copyWith({
    Producto? producto,
    ProductoPrecios? precio,
    int? quantity,
    int? tax,
  }) {
    return InvoiceItemData(
      producto: producto ?? this.producto,
      precio: precio ?? this.precio,
      quantity: quantity ?? this.quantity,
      tax: tax ?? this.tax,
    );
  }
}
