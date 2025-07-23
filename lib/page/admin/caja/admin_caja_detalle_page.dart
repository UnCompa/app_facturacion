import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:flutter/material.dart';

class AdminCajaDetallePage extends StatefulWidget {
  final String cajaId;
  final String negocioId;

  const AdminCajaDetallePage({
    super.key,
    required this.cajaId,
    required this.negocioId,
  });

  @override
  _CajaDetailScreenState createState() => _CajaDetailScreenState();
}

class _CajaDetailScreenState extends State<AdminCajaDetallePage> {
  Caja? _caja;
  List<CajaMoneda> _cajaMonedas = [];
  List<CajaMovimiento> _cajaMovimientos = [];
  List<CierreCaja> _cierresCaja = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCajaDetails();
  }

  Future<void> _fetchCajaDetails() async {
    try {
      // Consultar detalles de la caja
      final cajaRequest = ModelQueries.get(
        Caja.classType,
        CajaModelIdentifier(id: widget.cajaId),
      );
      final cajaResponse = await Amplify.API
          .query(request: cajaRequest)
          .response;
      final caja = cajaResponse.data;

      if (caja == null) {
        setState(() {
          _error = 'Caja no encontrada';
          _isLoading = false;
        });
        return;
      }

      // Consultar monedas de la caja
      final monedasRequest = ModelQueries.list(
        CajaMoneda.classType,
        where: CajaMoneda.CAJAID
            .eq(widget.cajaId)
            .and(CajaMoneda.ISDELETED.eq(false)),
      );
      final monedasResponse = await Amplify.API
          .query(request: monedasRequest)
          .response;
      final monedas = monedasResponse.data?.items ?? [];

      // Consultar movimientos de la caja
      final movimientosRequest = ModelQueries.list(
        CajaMovimiento.classType,
        where: CajaMovimiento.CAJAID
            .eq(widget.cajaId)
            .and(CajaMovimiento.ISDELETED.eq(false)),
      );
      final movimientosResponse = await Amplify.API
          .query(request: movimientosRequest)
          .response;
      final movimientos = movimientosResponse.data?.items ?? [];

      // Consultar cierres de caja
      final cierresRequest = ModelQueries.list(
        CierreCaja.classType,
        where: CierreCaja.CAJAID
            .eq(widget.cajaId)
            .and(CierreCaja.ISDELETED.eq(false)),
      );
      final cierresResponse = await Amplify.API
          .query(request: cierresRequest)
          .response;
      final cierres = cierresResponse.data?.items ?? [];

      setState(() {
        _caja = caja;
        _cajaMonedas = monedas.whereType<CajaMoneda>().toList();
        _cajaMovimientos = movimientos.whereType<CajaMovimiento>().toList();
        _cierresCaja = cierres.whereType<CierreCaja>().toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar los detalles: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de Caja')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _caja == null
          ? const Center(child: Text('No se encontraron datos'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información general de la caja
                  Text(
                    'Caja ID: ${_caja!.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Saldo Inicial: ${_caja!.saldoInicial}'),
                  Text('Estado: ${_caja!.isActive ? "Activa" : "Inactiva"}'),
                  Text('Creada: ${_caja!.createdAt?.toString() ?? "N/A"}'),
                  Text('Actualizada: ${_caja!.updatedAt?.toString() ?? "N/A"}'),
                  const SizedBox(height: 16),

                  // Monedas
                  const Text(
                    'Monedas:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_cajaMonedas.isEmpty)
                    const Text('No hay monedas registradas')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cajaMonedas.length,
                      itemBuilder: (context, index) {
                        final moneda = _cajaMonedas[index];
                        return ListTile(
                          title: Text(
                            '${moneda.moneda} - ${moneda.denominacion}',
                          ),
                          subtitle: Text('Monto: ${moneda.monto}'),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // Movimientos
                  const Text(
                    'Movimientos:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_cajaMovimientos.isEmpty)
                    const Text('No hay movimientos registrados')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cajaMovimientos.length,
                      itemBuilder: (context, index) {
                        final movimiento = _cajaMovimientos[index];
                        return ListTile(
                          title: Text(
                            '${movimiento.tipo} - ${movimiento.monto}',
                          ),
                          subtitle: Text(
                            movimiento.descripcion ?? 'Sin descripción',
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // Cierres de caja
                  const Text(
                    'Cierres de Caja:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_cierresCaja.isEmpty)
                    const Text('No hay cierres registrados')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cierresCaja.length,
                      itemBuilder: (context, index) {
                        final cierre = _cierresCaja[index];
                        return ListTile(
                          title: Text('Saldo Final: ${cierre.saldoFinal}'),
                          subtitle: Text(
                            'Diferencia: ${cierre.diferencia}\nObservaciones: ${cierre.observaciones ?? "N/A"}',
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
