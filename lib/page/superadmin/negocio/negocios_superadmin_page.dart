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

      final request = ModelQueries.list(
        Negocio.classType,
        where: Negocio.ISDELETED.eq(false),
      );
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
        onPressed: () async {
          final result = await Navigator.of(
            context,
          ).pushNamed(Routes.superAdminNegociosCrear);
          if (result == true) {
            refreshNegocios();
          }
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
        padding: const EdgeInsets.all(16.0),
        itemCount: negocios.length,
        itemBuilder: (context, index) {
          final negocio = negocios[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con nombre y menú
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Center(
                          child: Text(
                            (negocio.nombre.isNotEmpty == true
                                ? negocio.nombre.substring(0, 1).toUpperCase()
                                : 'N'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              negocio.nombre ?? 'Sin nombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (negocio.direccion != null)
                              Text(
                                negocio.direccion!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'editar':
                              () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditBussinesSuperadminPage(
                                      negocio: negocio,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  refreshNegocios();
                                }
                              };
                              break;
                            case 'eliminar':
                              _showDeleteDialog(negocio);
                              break;
                          }
                        },
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF2196F3),
                                ),
                                SizedBox(width: 12),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'eliminar',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 12),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Información de contacto
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Teléfono',
                          negocio.telefono ?? 'Sin teléfono',
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.email_outlined,
                          'RUC/Email',
                          negocio.ruc ?? 'Sin información',
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.timer,
                          'Duracion de acceso',
                          '${negocio.duration} Días' ?? 'Sin información',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Información de acceso
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFE1BEE7)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.computer_outlined,
                                color: const Color(0xFF7B1FA2),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PC Access',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                "${negocio.pcAccess ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7B1FA2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E8),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFC8E6C9)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.phone_android_outlined,
                                color: const Color(0xFF388E3C),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Móvil Access',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                "${negocio.movilAccess ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF388E3C),
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
        },
      ),
    );
  }

  // Método auxiliar para crear las filas de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF2196F3)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
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
      final negocioUpdate = negocio.copyWith(isDeleted: true);
      final request = ModelMutations.update(negocioUpdate);
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
