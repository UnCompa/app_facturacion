import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:app_facturacion/page/vendedor/invoice/invoice_create_page.dart';
import 'package:app_facturacion/page/vendedor/invoice/invoice_edit_page.dart';
import 'package:app_facturacion/page/vendedor/order/invoice_edit_page.dart';
import 'package:app_facturacion/services/caja_service.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:app_facturacion/services/user_service.dart';
import 'package:app_facturacion/utils/get_image_for_bucker.dart';
import 'package:app_facturacion/utils/get_token.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _roleUser = '';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _getRoleUser();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final negocio = await NegocioService.getCurrentUserInfo();
      final request = ModelQueries.list(
        Invoice.classType,
        where:
            Invoice.ISDELETED.eq(false) &
            Invoice.NEGOCIOID.eq(negocio.negocioId),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        setState(() {
          _invoices = response.data!.items.whereType<Invoice>().toList();
          _invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar facturas: ${response.errors}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getRoleUser() async {
    final roleUser = await UserService.getRolUser();
    setState(() {
      _roleUser = roleUser;
    });
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la factura ${invoice.invoiceNumber}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      // Verificar permisos
      if (_roleUser != 'admin') {
        throw Exception('Solo los administradores pueden eliminar facturas');
      }

      // Obtener caja y usuario
      final caja = await CajaService.getCurrentCaja();
      if (!caja.isActive) {
        throw Exception('La caja no está activa');
      }
      final userData = await NegocioService.getCurrentUserInfo();

      // Cargar ítems de la factura
      final itemRequest = ModelQueries.list(
        InvoiceItem.classType,
        where: InvoiceItem.INVOICEID.eq(invoice.id),
      );
      final itemResponse = await Amplify.API
          .query(request: itemRequest)
          .response;
      if (itemResponse.data == null) {
        throw Exception('Error al cargar ítems de la factura');
      }
      final items = itemResponse.data!.items.whereType<InvoiceItem>().toList();

      // Marcar ítems como eliminados y ajustar stock
      for (var item in items) {
        final updatedItem = item.copyWith(isDeleted: true);
        final updateItemRequest = ModelMutations.update(updatedItem);
        final itemResponse = await Amplify.API
            .mutate(request: updateItemRequest)
            .response;
        if (itemResponse.data == null) {
          throw Exception(
            'Error al marcar ítem como eliminado: ${itemResponse.errors}',
          );
        }

        // Obtener producto y actualizar stock
        final productRequest = ModelQueries.get(
          Producto.classType,
          ProductoModelIdentifier(id: item.productoID),
        );
        final productResponse = await Amplify.API
            .query(request: productRequest)
            .response;
        final producto = productResponse.data;
        if (producto != null) {
          final updatedProduct = producto.copyWith(
            stock: producto.stock + item.quantity,
          );
          final updateProductRequest = ModelMutations.update(updatedProduct);
          final productUpdateResponse = await Amplify.API
              .mutate(request: updateProductRequest)
              .response;
          if (productUpdateResponse.data == null) {
            throw Exception(
              'Error al actualizar stock: ${productUpdateResponse.errors}',
            );
          }
        }
      }

      // Marcar factura como eliminada
      final updatedInvoice = invoice.copyWith(isDeleted: true);
      final updateInvoiceRequest = ModelMutations.update(updatedInvoice);
      final invoiceResponse = await Amplify.API
          .mutate(request: updateInvoiceRequest)
          .response;
      if (invoiceResponse.data == null) {
        throw Exception(
          'Error al marcar factura como eliminada: ${invoiceResponse.errors}',
        );
      }

      // Actualizar saldo de la caja
      final cajaActualizada = caja.copyWith(
        saldoInicial: caja.saldoInicial - invoice.invoiceTotal,
      );
      final updateCajaRequest = ModelMutations.update(cajaActualizada);
      final cajaResponse = await Amplify.API
          .mutate(request: updateCajaRequest)
          .response;
      if (cajaResponse.data == null) {
        throw Exception('Error al actualizar caja: ${cajaResponse.errors}');
      }

      // Registrar movimiento de caja
      final movement = CajaMovimiento(
        cajaID: caja.id,
        tipo: 'EGRESO',
        origen: 'ANULACION_FACTURA',
        monto: invoice.invoiceTotal,
        negocioID: userData.negocioId,
        descripcion: 'Anulación de factura ID: ${invoice.id}',
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura eliminada correctamente')),
      );
      _loadInvoices();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar factura: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _generatePDF(Invoice invoice) async {
    try {
      final negocio = await NegocioService.getNegocioById(invoice.negocioID);
      if (negocio == null) throw Exception('Negocio no encontrado');

      // Obtener los ítems de la factura
      final itemRequest = ModelQueries.list(
        InvoiceItem.classType,
        where: InvoiceItem.INVOICEID.eq(invoice.id),
      );
      final itemResponse = await Amplify.API
          .query(request: itemRequest)
          .response;
      if (itemResponse.data == null) throw Exception('Error al cargar ítems');

      // Obtener los IDs de los productos de los ítems
      final productoIds = itemResponse.data!.items
          .whereType<InvoiceItem>()
          .map((item) => item.productoID)
          .toSet()
          .toList();

      // Consultar los productos en paralelo
      final productoResponses = await Future.wait(
        productoIds.map(
          (id) => Amplify.API
              .query(
                request: ModelQueries.get(
                  Producto.classType,
                  ProductoModelIdentifier(id: id),
                ),
              )
              .response,
        ),
      );

      // Crear un mapa de productos para acceso rápido
      final productoMap = <String, String>{};
      for (var i = 0; i < productoIds.length; i++) {
        final response = productoResponses[i];
        final producto = response.data;
        productoMap[productoIds[i]] = producto != null
            ? producto.nombre
            : 'Producto no encontrado';
      }

      // Mapear los ítems de la factura
      final invoiceItemsData = itemResponse.data!.items
          .whereType<InvoiceItem>()
          .map((item) {
            final productoNombre =
                productoMap[item.productoID] ?? 'Producto no encontrado';
            return {
              'productoNombre': productoNombre,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
              'total': item.total,
            };
          })
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
      if (token == null) throw Exception('No se pudo obtener el token');

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

      final pdfUrl = jsonDecode(lambdaResponse.body)['pdfUrl'];
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generado exitosamente')),
      );
      final urlFirmada = await GetImageFromBucket.getSignedImageUrls(
        s3Keys: [pdfUrl],
      );
      return urlFirmada.first;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      return null;
    }
  }

  Future<void> _printPDF(String? pdfUrl) async {
    print("IMPRIMIENDO PDF");
    print(pdfUrl);
    if (pdfUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay PDF disponible para imprimir')),
      );
      return;
    }

    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al imprimir: $e')));
    }
  }

  Color _getStatusBadgeColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pagada':
        return Colors.green[600]!;
      case 'pendiente':
        return Colors.orange[600]!;
      case 'vencida':
        return Colors.red[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
          if (result == true) {
            _loadInvoices();
          }
        },
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        tooltip: 'Nueva Factura',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando facturas...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(
              'Error al cargar facturas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvoices,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No hay facturas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una nueva factura con el botón +',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        itemCount: _invoices.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final invoice = _invoices[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Factura #${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      invoice.invoiceStatus ?? 'Sin estado',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _getStatusBadgeColor(
                      invoice.invoiceStatus,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fecha: ${dateFormat.format(invoice.invoiceDate.getDateTimeInUtc())}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    '\$${invoice.invoiceTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (_roleUser == 'admin')
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                InvoiceEditScreen(invoice: invoice),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _loadInvoices();
                          }
                        });
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                        side: BorderSide(color: Colors.blue[600]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  if (_roleUser == 'admin')
                    OutlinedButton.icon(
                      onPressed: () => _deleteInvoice(invoice),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[600]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pdfUrl = await _generatePDF(invoice);
                      if (pdfUrl != null) {
                        setState(() {}); // Actualizar UI si es necesario
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Generar PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      side: BorderSide(color: Colors.blue[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pdfUrl = await _generatePDF(invoice);
                      if (pdfUrl != null) {
                        await _printPDF(pdfUrl);
                      }
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Imprimir PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      side: BorderSide(color: Colors.blue[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
