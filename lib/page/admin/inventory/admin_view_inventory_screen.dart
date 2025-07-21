import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/Producto.dart';
import 'package:app_facturacion/page/admin/inventory/admin_create_inventory_product.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:flutter/material.dart';

class AdminViewInventoryScreen extends StatefulWidget {
  const AdminViewInventoryScreen({super.key});

  @override
  _AdminViewInventoryScreenState createState() =>
      _AdminViewInventoryScreenState();
}

class _AdminViewInventoryScreenState extends State<AdminViewInventoryScreen> {
  final List<Map<String, String>> _inventoryItems = [];
  final TextEditingController _searchController = TextEditingController();
  final String _selectedCategory = 'Categoría';
  String _negocioID = "";

  @override
  void initState() {
    super.initState();
    _getProductosByNegocio();
  }

  Future<void> _getProductosByNegocio() async {
    try {
      final info = await NegocioService.getCurrentUserInfo();
      final negocioId = info.negocioId;
      _negocioID = negocioId;

      final request = ModelQueries.list(
        Producto.classType,
        where: Producto.NEGOCIOID.eq(negocioId),
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final products = response.data!.items.whereType<Producto>().toList();

        setState(() {
          _inventoryItems.clear();
          _inventoryItems.addAll(
            products
                .map(
                  (product) => {
                    'name': product.nombre,
                    'quantity': product.stock.toString(),
                  },
                )
                .toList(),
          );
        });
      } else if (response.errors.isNotEmpty) {
        print('Query failed: ${response.errors}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestionar inventario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Nombre del producto',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: ['Categoría'].map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (_) {},
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _inventoryItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(_inventoryItems[index]['name']!),
                      trailing: SizedBox(
                        width: 80,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _inventoryItems[index]['quantity'] = value;
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _inventoryItems.add({
                    'name': 'Nombre del producto ${_inventoryItems.length}',
                    'quantity': '',
                  });
                });
              },
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(15),
              ),
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  AdminCreateInventoryProduct(negocioID: _negocioID),
            ),
          );
        },
      ),
    );
  }
}
