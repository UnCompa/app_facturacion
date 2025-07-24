import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:app_facturacion/page/admin/caja/admin_caja_create_page.dart';
import 'package:app_facturacion/page/admin/caja/admin_caja_detalle_page.dart';
import 'package:app_facturacion/page/admin/caja/admin_caja_monedas.page.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:flutter/material.dart';

class AdminCajaListPage extends StatefulWidget {
  const AdminCajaListPage({super.key});

  @override
  State<AdminCajaListPage> createState() => _AdminCajaListPageState();
}

class _AdminCajaListPageState extends State<AdminCajaListPage> {
  List<Caja> _cajas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCajas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Cajas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cajas.isEmpty
                ? _buildEmptyState()
                : _buildCajasList(),
          ),
        ],
      ),
      floatingActionButton: _cajas.length > 1 ? FloatingActionButton(
        onPressed: _createCaja,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay cajas registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón + para crear una nueva caja',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCajasList() {
    return RefreshIndicator(
      onRefresh: _refreshCajas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cajas.length,
        itemBuilder: (context, index) {
          final caja = _cajas[index];
          return _buildCajaCard(caja);
        },
      ),
    );
  }

  Widget _buildCajaCard(Caja caja) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showCajaDetails(caja),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caja ${caja.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Saldo Inicial: \$${caja.saldoInicial.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: caja.isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          caja.isActive ? 'Activa' : 'Inactiva',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleMenuAction(value, caja),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'monedas',
                            child: Row(
                              children: [
                                Icon(Icons.monetization_on, size: 18),
                                SizedBox(width: 8),
                                Text('Ver Monedas'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: caja.isActive ? 'deactivate' : 'activate',
                            child: Row(
                              children: [
                                Icon(
                                  caja.isActive
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(caja.isActive ? 'Desactivar' : 'Activar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'cierre',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.close_fullscreen_rounded,
                                  size: 18,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Cerrar caja',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
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
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Creado: ${_formatDate(DateTime.parse(caja.createdAt.toString()))}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createCaja() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminCajaCreatePage()),
    );
    if (result == true) {
      _loadCajas();
    }
  }

  void _showCajaDetails(Caja caja) async {
    final negocioData = await NegocioService.getCurrentUserInfo();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCajaDetallePage(
          cajaId: caja.id,
          negocioId: negocioData.negocioId,
        ),
      ),
    ).then((_) => _loadCajas());
  }

  void _handleMenuAction(String action, Caja caja) {
    switch (action) {
      case 'edit':
        _editCaja(caja);
        break;
      case 'monedas':
        _viewCajaMonedas(caja);
        break;
      case 'activate':
      case 'deactivate':
        _toggleCajaStatus(caja);
        break;
      case 'cierre':
        _showCerrarCajaModal(caja);
        break;
      case 'delete':
        _deleteCaja(caja);
        break;
    }
  }

  Future<void> _loadCajas() async {
    setState(() {
      _isLoading = true;
    });

    final negocioData = await NegocioService.getCurrentUserInfo();
    final request = ModelQueries.list(
      Caja.classType,
      where: Caja.ISDELETED.eq(false) & Caja.NEGOCIOID.eq(negocioData.negocioId),
    );
    final result = await Amplify.API.query(request: request).response;
    final cajas = result.data?.items;

    setState(() {
      _cajas = cajas!.where((caja) => caja != null).cast<Caja>().toList();
      _isLoading = false;
    });
  }

  void _showCerrarCajaModal(Caja caja) {
    final observacionesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Caja'),
        content: TextField(
          controller: observacionesController,
          decoration: const InputDecoration(
            labelText: 'Observaciones',
            hintText: 'Ingresa observaciones (opcional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cerrarCaja(
                caja,
                observacionesController.text.isEmpty
                    ? null
                    : observacionesController.text,
              );
            },
            child: const Text('Cerrar Caja'),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarCaja(Caja caja, String? observaciones) async {
    try {
      final negocioData = await NegocioService.getCurrentUserInfo();
      // 1. Sumar el monto de las monedas asociadas a la caja
      final monedasRequest = ModelQueries.list(
        CajaMoneda.classType,
        where: CajaMoneda.CAJAID
            .eq(caja.id)
            .and(CajaMoneda.ISDELETED.eq(false)),
      );
      final monedasResponse = await Amplify.API
          .query(request: monedasRequest)
          .response;
      final monedas =
          monedasResponse.data?.items.whereType<CajaMoneda>().toList() ?? [];

      // Calcular el monto final sumando los montos de las monedas
      final montoFinal = monedas.fold<double>(
        0.0,
        (sum, moneda) => sum + (moneda.monto ?? 0.0),
      );

      // Calcular la diferencia (monto final - saldo inicial)
      final diferencia = montoFinal - (caja.saldoInicial ?? 0.0);

      // 2. Actualizar la caja con el nuevo estado (desactivar)
      final updatedCaja = caja.copyWith(
        isActive: false,
        updatedAt: TemporalDateTime(DateTime.now()),
      );
      final updateCajaRequest = ModelMutations.update(updatedCaja);
      await Amplify.API.mutate(request: updateCajaRequest).response;

      // 3. Crear el registro de cierre de caja
      final cierreCaja = CierreCaja(
        cajaID: caja.id,
        negocioID: caja.negocioID,
        saldoFinal: montoFinal,
        diferencia: diferencia,
        observaciones: observaciones,
        isDeleted: false,
        createdAt: TemporalDateTime(DateTime.now()),
        updatedAt: TemporalDateTime(DateTime.now()),
      );
      final cierreRequest = ModelMutations.create(cierreCaja);
      await Amplify.API.mutate(request: cierreRequest).response;

      // 4. Opcional: Crear un registro en el historial de cierre
      final cierreHistorial = CierreCajaHistorial(
        cierreCajaID: cierreCaja.id,
        negocioID: caja.negocioID,
        usuarioID: negocioData.userId,
        fechaCierre: TemporalDateTime(DateTime.now()),
        isDeleted: false,
        createdAt: TemporalDateTime(DateTime.now()),
        updatedAt: TemporalDateTime(DateTime.now()),
      );
      final historialRequest = ModelMutations.create(cierreHistorial);
      await Amplify.API.mutate(request: historialRequest).response;

      // Notificar éxito (puedes usar un SnackBar o similar)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caja cerrada exitosamente')),
      );
    } catch (e) {
      // Manejo de errores
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar la caja: $e')));
    }
  }

  Future<void> _refreshCajas() async {
    await _loadCajas();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editCaja(Caja caja) {
    // TODO: Implementar edición de caja
    showDialog(
      context: context,
      builder: (context) => EditCajaDialog(
        caja: caja,
        onCajaUpdated: () {
          _loadCajas();
        },
      ),
    );
  }

  void _viewCajaMonedas(Caja caja) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CajaMonedasPage(caja: caja)),
    );
  }

  Future<void> _toggleCajaStatus(Caja caja) async {
    // TODO: Implementar cambio de estado activo/inactivo
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${caja.isActive ? 'Desactivar' : 'Activar'} Caja'),
        content: Text(
          '¿Estás seguro de que deseas ${caja.isActive ? 'desactivar' : 'activar'} esta caja?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => {
              !caja.isActive ? _activeCaja(caja) : _inactiveCaja(caja),
              Navigator.pop(context, false)
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implementar actualización del estado
      _loadCajas();
    }
  }

  Future<void> _activeCaja(Caja caja) async {
    try {
      final negocioData = await NegocioService.getCurrentUserInfo();
      final cajaNew = caja.copyWith(
        isActive: true,
        negocioID: negocioData.negocioId,
        saldoInicial: caja.saldoInicial,
        createdAt: caja.createdAt,
        updatedAt: TemporalDateTime(DateTime.now()),
        isDeleted: false,
      );
      final updateCajaRequest = ModelMutations.update(cajaNew);
      await Amplify.API.mutate(request: updateCajaRequest).response;
      _loadCajas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al activar la caja: $e')),
      );
    }
  }

  Future<void> _inactiveCaja(Caja caja) async {
    try {
      final negocioData = await NegocioService.getCurrentUserInfo();
      final cajaNew = caja.copyWith(
        isActive: false,
        negocioID: negocioData.negocioId,
        saldoInicial: caja.saldoInicial,
        createdAt: caja.createdAt,
        updatedAt: TemporalDateTime(DateTime.now()),
        isDeleted: false,
      );
      final updateCajaRequest = ModelMutations.update(cajaNew);
      await Amplify.API.mutate(request: updateCajaRequest).response;
      _loadCajas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inactivar la caja: $e')),
      );
    }
  }

  Future<void> _deleteCaja(Caja caja) async {
    // TODO: Implementar eliminación lógica de caja
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Caja'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta caja? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implementar eliminación lógica (isDeleted = true)
      _loadCajas();
    }
  }
}

class EditCajaDialog extends StatelessWidget {
  final Caja caja;
  final VoidCallback onCajaUpdated;

  const EditCajaDialog({
    super.key,
    required this.caja,
    required this.onCajaUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Implementar diálogo de edición
    return AlertDialog(
      title: const Text('Editar Caja'),
      content: const Text('Implementar formulario de edición'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implementar actualización
            Navigator.pop(context);
            onCajaUpdated();
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
