import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminCajaCreatePage extends StatefulWidget {
  const AdminCajaCreatePage({super.key});

  @override
  State<AdminCajaCreatePage> createState() => _AdminCajaCreatePageState();
}

class _AdminCajaCreatePageState extends State<AdminCajaCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _saldoInicialController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  List<CajaMonedaForm> _monedas = [];

  // Denominaciones predefinidas por moneda
  final Map<String, List<double>> _denominacionesPorMoneda = {
    'USD': [0.01, 0.05, 0.10, 0.25, 1.00, 5.00, 10.00, 20.00, 50.00, 100.00],
    'EUR': [
      0.01,
      0.02,
      0.05,
      0.10,
      0.20,
      0.50,
      1.00,
      2.00,
      5.00,
      10.00,
      20.00,
      50.00,
      100.00,
      200.00,
      500.00,
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeMonedasDefecto();
  }

  @override
  void dispose() {
    _saldoInicialController.dispose();
    super.dispose();
  }

  void _initializeMonedasDefecto() {
    // Inicializar con denominaciones USD por defecto
    final denominacionesUSD = _denominacionesPorMoneda['USD'] ?? [];
    _monedas = denominacionesUSD.map((denominacion) {
      return CajaMonedaForm(
        moneda: 'USD',
        denominacion: denominacion,
        monto: 0.0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Caja'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _guardarCaja,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'GUARDAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCajaInfoSection(),
                    const SizedBox(height: 24),
                    _buildMonedasSection(),
                  ],
                ),
              ),
            ),
            _buildBottomSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildCajaInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la Caja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _saldoInicialController,
              decoration: const InputDecoration(
                labelText: 'Saldo Inicial',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Ingrese el saldo inicial de la caja',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El saldo inicial es requerido';
                }
                final saldo = double.tryParse(value);
                if (saldo == null || saldo < 0) {
                  return 'Ingrese un saldo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                ),
                const Text('Activar caja al crearla'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonedasSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Denominaciones de Monedas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Cambiar moneda',
                  onSelected: _cambiarMoneda,
                  itemBuilder: (context) => _denominacionesPorMoneda.keys
                      .map(
                        (moneda) => PopupMenuItem(
                          value: moneda,
                          child: Text('Cambiar a $moneda'),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure las denominaciones disponibles en la caja',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildMonedasList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonedasList() {
    return Column(
      children: _monedas.asMap().entries.map((entry) {
        final index = entry.key;
        final moneda = entry.value;
        return _buildMonedaItem(moneda, index);
      }).toList(),
    );
  }

  Widget _buildMonedaItem(CajaMonedaForm moneda, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  moneda.moneda,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  _formatDenominacion(moneda.denominacion),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDenominacionLabel(moneda.moneda, moneda.denominacion),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${_formatDenominacion(moneda.denominacion)} x ${_getCantidad(moneda.monto, moneda.denominacion)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: moneda.monto.toString(),
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final monto = double.tryParse(value) ?? 0.0;
                setState(() {
                  _monedas[index] = moneda.copyWith(monto: monto);
                });
              },
              validator: (value) {
                final monto = double.tryParse(value ?? '0') ?? 0.0;
                if (monto < 0) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary() {
    final totalMonedas = _monedas.fold<double>(
      0.0,
      (sum, moneda) => sum + moneda.monto,
    );
    final saldoInicial = double.tryParse(_saldoInicialController.text) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total en Monedas:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                '\$${totalMonedas.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Inicial:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                '\$${saldoInicial.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Diferencia:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${(saldoInicial - totalMonedas).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (saldoInicial - totalMonedas) == 0
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
          ),
          if ((saldoInicial - totalMonedas) != 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El saldo inicial no coincide con el total de monedas',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDenominacion(double denominacion) {
    if (denominacion < 1) {
      return '${(denominacion * 100).toInt()}¢';
    } else {
      return '\$${denominacion.toStringAsFixed(denominacion == denominacion.toInt() ? 0 : 2)}';
    }
  }

  String _getDenominacionLabel(String moneda, double denominacion) {
    if (denominacion < 1) {
      return '$moneda - ${(denominacion * 100).toInt()} centavos';
    } else if (denominacion == 1) {
      return '$moneda - 1 ${moneda == 'USD' ? 'dólar' : 'euro'}';
    } else {
      return '$moneda - ${denominacion.toInt()} ${moneda == 'USD' ? 'dólares' : 'euros'}';
    }
  }

  int _getCantidad(double monto, double denominacion) {
    if (denominacion == 0) return 0;
    return (monto / denominacion).round();
  }

  void _cambiarMoneda(String nuevaMoneda) {
    final denominaciones = _denominacionesPorMoneda[nuevaMoneda] ?? [];
    setState(() {
      _monedas = denominaciones.map((denominacion) {
        return CajaMonedaForm(
          moneda: nuevaMoneda,
          denominacion: denominacion,
          monto: 0.0,
        );
      }).toList();
    });
  }

  // ============== FUNCIONES PARA IMPLEMENTAR ==============

  Future<void> _guardarCaja() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implementar creación de la caja
      await _crearCaja();

      if (mounted) {
        Navigator.pop(context, true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caja creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la caja: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _crearCaja() async {
    // TODO: Implementar la lógica de creación

    final saldoInicial = double.parse(_saldoInicialController.text);

    final negocioId = await _getCurrentNegocioId();

    // 1. Crear la caja
    final nuevaCaja = Caja(
      negocioID: negocioId,
      isDeleted: false,
      saldoInicial: saldoInicial,
      isActive: _isActive,
      createdAt: TemporalDateTime.now(),
      updatedAt: TemporalDateTime.now(),
    );

    final cajaCreada = await Amplify.API
        .mutate(request: ModelMutations.create(nuevaCaja))
        .response;

    // 2. Crear las monedas asociadas
    final monedasACrear = _monedas.where((m) => m.monto > 0).toList();

    for (final monedaForm in monedasACrear) {
      final cajaMoneda = CajaMoneda(
        cajaID: cajaCreada.data!.id,
        negocioID: negocioId,
        moneda: monedaForm.moneda,
        denominacion: monedaForm.denominacion,
        monto: monedaForm.monto,
        isDeleted: false,
        createdAt: TemporalDateTime.now(),
        updatedAt: TemporalDateTime.now(),
      );

      await Amplify.API
          .mutate(request: ModelMutations.create(cajaMoneda))
          .response;
    }
    Navigator.pop(context, true);
  }

  Future<String> _getCurrentNegocioId() async {
    final userData = await NegocioService.getCurrentUserInfo();
    return userData.negocioId;
  }
}

class CajaMonedaForm {
  final String moneda;
  final double denominacion;
  final double monto;

  CajaMonedaForm({
    required this.moneda,
    required this.denominacion,
    required this.monto,
  });

  CajaMonedaForm copyWith({
    String? moneda,
    double? denominacion,
    double? monto,
  }) {
    return CajaMonedaForm(
      moneda: moneda ?? this.moneda,
      denominacion: denominacion ?? this.denominacion,
      monto: monto ?? this.monto,
    );
  }
}
