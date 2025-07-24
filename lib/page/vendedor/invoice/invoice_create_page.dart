import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/entities/invoice_item_data.dart';
import 'package:app_facturacion/entities/pago_moneda.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:app_facturacion/services/caja_service.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:app_facturacion/utils/get_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
  bool _isLoadingCaja = false;
  Caja? _caja;
  List<CajaMoneda> _cajaMonedas = [];
  final List<PagoMoneda> _pagoMonedas = [];
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
    _loadCajaData();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCajaData() async {
    setState(() => _isLoadingCaja = true);
    try {
      final caja = await CajaService.getCurrentCaja();
      final request = ModelQueries.list(
        CajaMoneda.classType,
        where: CajaMoneda.CAJAID
            .eq(caja.id)
            .and(CajaMoneda.ISDELETED.eq(false)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        setState(() {
          _caja = caja;
          _cajaMonedas = response.data!.items.whereType<CajaMoneda>().toList();
          _pagoMonedas.clear();
          for (var moneda in _cajaMonedas) {
            _pagoMonedas.add(PagoMoneda(moneda: moneda, cantidad: 0));
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de caja: $e')),
      );
    } finally {
      setState(() => _isLoadingCaja = false);
    }
  }

  Future<void> _updateMonedaPago(int index, int change) async {
    final pagoMoneda = _pagoMonedas[index];
    final maxMonedas =
        (pagoMoneda.moneda.monto / pagoMoneda.moneda.denominacion).floor();
    final newCantidad = pagoMoneda.cantidad + change;

    if (newCantidad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad no puede ser negativa')),
      );
      return;
    }

    setState(() {
      _pagoMonedas[index] = PagoMoneda(
        moneda: pagoMoneda.moneda,
        cantidad: newCantidad,
      );
    });
    _validatePagoVsFactura();
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMddHHmm').format(now);
    _invoiceNumberController.text = 'INV-$timestamp';
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
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
      setState(() => _isLoadingProducts = false);
    }
  }

  double _calculateTotal() {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double _calculateTotalCaja() {
    return _cajaMonedas.fold(0.0, (sum, moneda) => sum + moneda.monto);
  }

  double _calculateTotalPago() {
    return _pagoMonedas.fold(
      0.0,
      (sum, pago) => sum + (pago.cantidad * pago.moneda.denominacion),
    );
  }

  bool _validatePagoVsFactura() {
    final totalFactura = _calculateTotal();
    final totalPago = _calculateTotalPago();
    return totalPago.toStringAsFixed(2) == totalFactura.toStringAsFixed(2);
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
    _validatePagoVsFactura();
  }

  void _removeInvoiceItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
    _validatePagoVsFactura();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<String?> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return null;

    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe agregar al menos un producto')),
      );
      return null;
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
        return null;
      }
    }

    final totalFactura = _calculateTotal();
    final totalPago = _calculateTotalPago();

    if (totalPago.toStringAsFixed(2) != totalFactura.toStringAsFixed(2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El pago (\$${totalPago.toStringAsFixed(2)}) debe coincidir con la factura (\$${totalFactura.toStringAsFixed(2)})',
          ),
        ),
      );
      return null;
    }

    setState(() => _isLoading = true);
    try {
      final userData = await NegocioService.getCurrentUserInfo();
      final caja = await CajaService.getCurrentCaja();
      final negocio = await NegocioService.getNegocioById(userData.negocioId);

      if (!caja.isActive) throw Exception('La caja no está activa');

      final invoice = Invoice(
        invoiceNumber: _invoiceNumberController.text,
        invoiceDate: TemporalDateTime(_selectedDate),
        invoiceTotal: totalFactura,
        invoiceStatus: _selectedStatus,
        sellerID: userData.userId,
        negocioID: userData.negocioId,
        cajaID: caja.id,
        isDeleted: false,
      );

      final createInvoiceRequest = ModelMutations.create(invoice);
      final invoiceResponse = await Amplify.API
          .mutate(request: createInvoiceRequest)
          .response;
      if (invoiceResponse.data == null) {
        throw Exception('Error al crear la factura: ${invoiceResponse.errors}');
      }
      final createdInvoice = invoiceResponse.data!;

      for (final itemData in _invoiceItems) {
        final invoiceItem = InvoiceItem(
          invoiceID: createdInvoice.id,
          productoID: itemData.producto.id,
          quantity: itemData.quantity,
          tax: itemData.tax,
          subtotal: itemData.subtotal,
          total: double.parse(itemData.total.toStringAsFixed(2)),
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

        final updatedProduct = itemData.producto.copyWith(
          stock: itemData.producto.stock - itemData.quantity,
        );
        final updateProductRequest = ModelMutations.update(updatedProduct);
        final productResponse = await Amplify.API
            .mutate(request: updateProductRequest)
            .response;
        if (productResponse.data == null) {
          throw Exception(
            'Error al actualizar stock: ${productResponse.errors}',
          );
        }
      }

      // Sumar el dinero recibido a las monedas en la caja
      for (final pago in _pagoMonedas) {
        if (pago.cantidad > 0) {
          final moneda = pago.moneda;
          final montoRecibido = pago.cantidad * moneda.denominacion;
          final updatedMoneda = moneda.copyWith(
            monto:
                moneda.monto + double.parse(montoRecibido.toStringAsFixed(2)),
          );
          final updateMonedaRequest = ModelMutations.update(updatedMoneda);
          final monedaResponse = await Amplify.API
              .mutate(request: updateMonedaRequest)
              .response;
          if (monedaResponse.data == null) {
            throw Exception(
              'Error al actualizar moneda: ${monedaResponse.errors}',
            );
          }
        }
      }

      final cajaActualizada = caja.copyWith(
        saldoInicial: caja.saldoInicial + totalFactura,
      );
      final updateCajaRequest = ModelMutations.update(cajaActualizada);
      final cajaResponse = await Amplify.API
          .mutate(request: updateCajaRequest)
          .response;
      if (cajaResponse.data == null) {
        throw Exception('Error al actualizar caja: ${cajaResponse.errors}');
      }

      final movement = CajaMovimiento(
        cajaID: caja.id,
        tipo: 'INGRESO',
        origen: 'FACTURA',
        monto: totalFactura,
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

      final updatedInvoice = createdInvoice.copyWith(
        cajaMovimientoID: createdMovement.id,
      );
      final updateInvoiceRequest = ModelMutations.update(updatedInvoice);
      final updateInvoiceResponse = await Amplify.API
          .mutate(request: updateInvoiceRequest)
          .response;
      if (updateInvoiceResponse.data == null) {
        throw Exception(
          'Error al actualizar factura: ${updateInvoiceResponse.errors}',
        );
      }

      setState(() {
        _pagoMonedas.clear();
        for (var moneda in _cajaMonedas) {
          _pagoMonedas.add(PagoMoneda(moneda: moneda, cantidad: 0));
        }
      });
      await _generatePDF(invoice, negocio!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura creada y PDF generado')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear la factura: $e')));
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
    return null;
  }

  Future<String?> _generatePDF(Invoice invoice, Negocio negocio) async {
    try {
      final invoiceItemsData = _invoiceItems
          .map(
            (item) => ({
              'productoNombre': item.producto.nombre,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
              'total': item.total,
            }),
          )
          .toList();

      final lambdaInput = {
        'invoice': {
          'id': invoice.id,
          'invoiceNumber': invoice.invoiceNumber,
          'invoiceDate': invoice.invoiceDate.toString(),
          'invoiceTotal': invoice.invoiceTotal,
        },
        'invoiceItems': invoiceItemsData,
        'negocio': {
          'nombre': negocio.nombre,
          'ruc': negocio.ruc,
          'telefono': negocio.telefono,
          'direccion': negocio.direccion,
        },
      };
      final token = await GetToken.getIdTokenSimple();
      if (token == null) {
        print('No se pudo obtener el token');
        return null;
      }
      final lambdaResponse = await http.post(
        Uri.parse(
          'https://hwmfv41ks4.execute-api.us-east-1.amazonaws.com/dev/generate-invoice-pdf',
        ),
        body: Uint8List.fromList(jsonEncode(lambdaInput).codeUnits),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.raw,
        },
      );
      return jsonDecode(lambdaResponse.body)['pdfUrl'];
    } catch (e) {
      print('Error al generar PDF: $e');
      return null;
    }
  }

  Future<void> _scanBarcode() async {
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
        if (_invoiceItems.any((item) => item.producto.id == producto.id)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Producto ${producto.nombre} ya agregado')),
          );
          return;
        }
        if (producto.stock <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Producto ${producto.nombre} sin stock')),
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
        _validatePagoVsFactura();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto ${producto.nombre} agregado')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto no encontrado')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener producto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Factura'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _validatePagoVsFactura() ? _saveInvoice : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
        ],
      ),
      body: _isLoadingProducts || _isLoadingCaja
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildBasicInfoSection(),
                    const SizedBox(height: 16),
                    buildItemsSection(),
                    const SizedBox(height: 16),
                    buildTotalAndPagoSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _scanBarcode,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            tooltip: 'Escanear código',
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: _addInvoiceItem,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            label: const Text('Agregar Producto'),
            icon: const Icon(Icons.add),
            tooltip: 'Agregar producto',
          ),
        ],
      ),
    );
  }

  Widget buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _invoiceNumberController,
              decoration: InputDecoration(
                labelText: 'Número de Factura',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingrese número de factura'
                  : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: _statusOptions
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItemsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_invoiceItems.length} ítems',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _invoiceItems.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay productos',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Agrega productos con el botón +',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _invoiceItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        buildInvoiceItemCard(index),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                DropdownButtonFormField<Producto>(
                  value: item.producto,
                  decoration: InputDecoration(
                    labelText: 'Producto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: _productos.map((producto) {
                    return DropdownMenuItem(
                      value: producto,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w500),
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
                    final nuevosPrecios = _productoPrecios[producto!.id] ?? [];
                    final precioSeleccionado = nuevosPrecios.isNotEmpty
                        ? nuevosPrecios.first
                        : null;
                    setState(() {
                      _invoiceItems[index] = item.copyWith(
                        producto: producto,
                        precio: precioSeleccionado,
                      );
                      _validatePagoVsFactura();
                    });
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProductoPrecios>(
                  value: item.precio,
                  decoration: InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: precios
                      .map(
                        (precio) => DropdownMenuItem(
                          value: precio,
                          child: Text(
                            '${precio.nombre}: \$${precio.precio.toStringAsFixed(2)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (precio) {
                    setState(() {
                      _invoiceItems[index] = item.copyWith(precio: precio);
                      _validatePagoVsFactura();
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Seleccione un precio' : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: InputDecoration(
                    labelText: 'Cant.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final quantity = int.tryParse(value) ?? 1;
                    if (quantity > item.producto.stock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Stock insuficiente: ${item.producto.stock}',
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _invoiceItems[index] = item.copyWith(quantity: quantity);
                      _validatePagoVsFactura();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese cantidad';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Cantidad debe ser mayor a 0';
                    }
                    if (quantity > item.producto.stock) {
                      return 'Stock insuficiente';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: item.tax.toString(),
                  decoration: InputDecoration(
                    labelText: 'IVA (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final tax = int.tryParse(value) ?? 0;
                    setState(() {
                      _invoiceItems[index] = item.copyWith(tax: tax);
                      _validatePagoVsFactura();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese IVA';
                    final tax = int.tryParse(value);
                    if (tax == null || tax < 0) return 'IVA no válido';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _removeInvoiceItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTotalAndPagoSection() {
    final total = _calculateTotal();
    print(total);
    final totalPago = _calculateTotalPago();
    print(totalPago);
    final totalCaja = _calculateTotalCaja();
    print(totalCaja);
    final isValid = totalPago.toStringAsFixed(2) == total.toStringAsFixed(2);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen y Pago',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Inicial:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '\$${_caja?.saldoInicial.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Monedas:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '\$${totalCaja.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Factura:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pagado:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '\$${totalPago.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
            if (!isValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'El pago debe coincidir con la factura',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text(
                'Seleccionar Monedas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              children: [
                _isLoadingCaja
                    ? const Center(child: CircularProgressIndicator())
                    : _pagoMonedas.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No hay monedas disponibles'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pagoMonedas.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final pago = _pagoMonedas[index];
                          final maxMonedas =
                              (pago.moneda.monto / pago.moneda.denominacion)
                                  .floor();
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pago.moneda.moneda} - ${pago.moneda.denominacion.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Disponible: $maxMonedas',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Seleccionado: ${pago.cantidad}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Total: ${(pago.cantidad * pago.moneda.denominacion).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _updateMonedaPago(index, -1),
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Restar',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _updateMonedaPago(index, 1),
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.green,
                                      ),
                                      tooltip: 'Sumar',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
