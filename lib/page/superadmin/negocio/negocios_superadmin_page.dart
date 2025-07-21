import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/Negocio.dart';
import 'package:app_facturacion/page/superadmin/negocio/edit_bussines_superadmin_page.dart';
import 'package:app_facturacion/routes/routes.dart';
import 'package:flutter/material.dart';

class NegociosSuperadminPage extends StatefulWidget {
  const NegociosSuperadminPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return NegociosSuperadminPageState();
  }
}

class NegociosSuperadminPageState extends State<NegociosSuperadminPage> {
  List<Negocio> negocios = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    getAllBussines();
  }

  Future<List<Negocio>> getAllBussines() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final request = ModelQueries.list(Negocio.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('Errores en la respuesta: ${response.errors}');
        throw Exception('Error al obtener los negocios');
      }

      final negociosItems = response.data?.items;

      final negociosList =
          negociosItems
              ?.where((item) => item != null)
              .map((item) => item!)
              .toList() ??
          [];

      setState(() {
        negocios = negociosList;
        isLoading = false;
      });

      return negociosList;
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los negocios: ${e.toString()}';
      });

      safePrint('Error getting businesses: $e');
      return [];
    }
  }

  Future<void> refreshNegocios() async {
    await getAllBussines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Negocios'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshNegocios,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí puedes navegar a una página para crear un nuevo negocio
          Navigator.of(context).pushNamed(Routes.superAdminNegociosCrear);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: refreshNegocios,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (negocios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, color: Colors.grey, size: 60),
            SizedBox(height: 16),
            Text(
              'No hay negocios registrados',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshNegocios,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: negocios.length,
        itemBuilder: (context, index) {
          final negocio = negocios[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  negocio.nombre.substring(0, 1).toUpperCase() ?? 'N',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                negocio.nombre ?? 'Sin nombre',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (negocio.direccion != null) Text(negocio.direccion!),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        negocio.telefono ?? 'Sin teléfono',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        negocio.ruc ?? 'Sin email',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'editar':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditBussinesSuperadminPage(negocio: negocio),
                        ),
                      );
                      break;
                    case 'eliminar':
                      _showDeleteDialog(negocio);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Negocio negocio) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que deseas eliminar el negocio "${negocio.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteNegocio(negocio);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNegocio(Negocio negocio) async {
    try {
      final request = ModelMutations.delete(negocio);
      await Amplify.API.mutate(request: request).response;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Negocio eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      refreshNegocios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar negocio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
