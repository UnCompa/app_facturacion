import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:flutter/material.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  List<InvoiceItem> _invoiceItems = [];
  final Map<String, Producto> _productCache = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetails();
  }

  Future<void> _loadInvoiceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cargar los items de la factura
      final itemsRequest = ModelQueries.list(
        InvoiceItem.classType,
        where: InvoiceItem.INVOICEID.eq(widget.invoice.id),
      );
      final itemsResponse = await Amplify.API
          .query(request: itemsRequest)
          .response;

      if (itemsResponse.data != null) {
        final items = itemsResponse.data!.items
            .whereType<InvoiceItem>()
            .toList();

        // Cargar productos para cada item
        for (final item in items) {
          if (!_productCache.containsKey(item.productoID)) {
            try {
              final productRequest = ModelQueries.get(
                Producto.classType,
                ProductoModelIdentifier(id: item.productoID),
              );

              final productResponse = await Amplify.API
                  .query(request: productRequest)
                  .response;

              if (productResponse.data != null) {
                _productCache[item.productoID] = productResponse.data!;
              } else {
                print('Producto no encontrado para ID: ${item.productoID}');
              }
            } catch (e) {
              print('Error al cargar producto ${item.productoID}: $e');
              // Continuar con el siguiente producto en lugar de fallar completamente
            }
          }
        }

        setState(() {
          _invoiceItems = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudieron cargar los detalles de la factura';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los detalles: $e';
        _isLoading = false;
      });
    }
  }

  double get _totalAmount {
    return _invoiceItems.fold(0.0, (total, item) {
      final producto = _productCache[item.productoID];
      if (producto != null) {
        // Usar item.subtotal si existe, o calcular con producto.precio
        return total +
            (item.quantity * (item.subtotal ?? producto.precio ?? 0.0));
      }
      // Si no hay producto, usar solo item.subtotal si existe
      return total + (item.quantity * (item.subtotal ?? 0.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Factura #${widget.invoice.invoiceNumber}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(fontSize: 16, color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInvoiceDetails,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la factura
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información de la Factura',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Número:',
                            widget.invoice.invoiceNumber,
                          ),
                          _buildInfoRow(
                            'Total:',
                            '\$${_totalAmount.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de productos
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Productos',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          if (_invoiceItems.isEmpty)
                            const Text(
                              'No hay productos en esta factura',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _invoiceItems.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final item = _invoiceItems[index];
                                final producto = _productCache[item.productoID];

                                // Manejar casos donde el producto puede ser null
                                final productName =
                                    producto?.nombre ?? 'Producto desconocido';
                                final subtotal = _calculateItemSubtotal(
                                  item,
                                  producto,
                                );

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: producto == null
                                      ? const Text(
                                          'Producto no disponible',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      : Text('Cantidad: ${item.quantity}'),
                                  trailing: Text(
                                    '\$${subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Método helper para calcular el subtotal de un item
  double _calculateItemSubtotal(InvoiceItem item, Producto? producto) {
    // Prioridad: usar item.subtotal si existe
    return item.quantity * item.subtotal;

    // Si no hay subtotal en el item, usar precio del producto
    if (producto?.precio != null) {
      return item.quantity * producto!.precio;
    }

    // Si no hay precio disponible, retornar 0
    return 0.0;
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
