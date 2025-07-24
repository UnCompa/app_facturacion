import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:flutter/material.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    // Implementar la pantalla de detalles si es necesario
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de Factura #${invoice.invoiceNumber}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Pantalla de detalles no implementada')),
    );
  }
}
