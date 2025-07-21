import 'dart:async';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/mixin/session_control_mixin.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:app_facturacion/page/auth/login_page.dart';
import 'package:app_facturacion/services/device_session_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage>
    with WidgetsBindingObserver, SessionControlMixin {
  String? userName;
  Negocio? negocio;
  bool isLoading = true;
  String? errorMessage;

  // Nueva información de vigencia y dispositivos
  DateTime? fechaVencimiento;
  int diasRestantes = 0;
  int dispositivosConectados = 0;
  int maxDispositivosMovil = 0;
  int maxDispositivosPC = 0;
  bool vigenciaValida = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserAndBusiness();
    WidgetsBinding.instance.addObserver(this);
    initializeSessionControl();

    // Actualizar información cada 30 segundos
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    disposeSessionControl();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshVigenciaInfo();
      }
    });
  }

  Future<void> _loadUserAndBusiness() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Obtener el usuario actual
      final user = await Amplify.Auth.getCurrentUser();
      final attributes = await Amplify.Auth.fetchUserAttributes();

      String? negocioId;
      String? userDisplayName;

      for (final attribute in attributes) {
        if (attribute.userAttributeKey.key == 'custom:negocioid') {
          negocioId = attribute.value;
        }
        if (attribute.userAttributeKey.key == 'name' ||
            attribute.userAttributeKey.key == 'preferred_username') {
          userDisplayName = attribute.value;
        }
      }

      userDisplayName ??= user.username;

      if (negocioId != null) {
        // Consultar los datos del negocio
        final request = ModelQueries.get(
          Negocio.classType,
          NegocioModelIdentifier(id: negocioId),
        );
        final response = await Amplify.API.query(request: request).response;

        if (response.data != null) {
          setState(() {
            userName = userDisplayName;
            negocio = response.data;
          });

          // Cargar información adicional de vigencia y dispositivos
          await _loadVigenciaInfo();
        } else {
          setState(() {
            userName = userDisplayName;
            errorMessage = 'No se pudo cargar la información del negocio';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          userName = userDisplayName;
          errorMessage = 'Usuario sin negocio asignado';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar datos: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadVigenciaInfo() async {
    if (negocio == null) return;

    try {
      // Calcular vigencia
      final now = DateTime.now().toUtc(); // Comparación justa en UTC
      if (negocio!.createdAt != null && negocio!.duration != null) {
        final fechaCreacion = negocio!.createdAt!.getDateTimeInUtc();
        fechaVencimiento = fechaCreacion.add(
          Duration(days: negocio!.duration!),
        );
        diasRestantes = (fechaVencimiento!.difference(now).inSeconds / 86400)
            .ceil();
        vigenciaValida = fechaVencimiento!.isAfter(now);
      }
      final deviceInfo = await DeviceSessionService.getConnectedDevicesInfo(
        negocio!.id,
      );
      setState(() {
        maxDispositivosMovil = negocio!.movilAccess ?? 0;
        maxDispositivosPC = negocio!.pcAccess ?? 0;
        isLoading = false;
        dispositivosConectados = deviceInfo['total'] ?? 0;
      });
    } catch (e) {
      safePrint('Error cargando información de vigencia: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshVigenciaInfo() async {
    if (negocio != null && mounted) {
      await _loadVigenciaInfo();
    }
  }

  Color _getVigenciaColor() {
    if (!vigenciaValida) return Colors.red;
    if (diasRestantes <= 7) return Colors.orange;
    if (diasRestantes <= 30) return Colors.yellow[700]!;
    return Colors.green;
  }

  IconData _getVigenciaIcon() {
    if (!vigenciaValida) return Icons.error;
    if (diasRestantes <= 7) return Icons.warning;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          negocio != null
              ? 'Panel de Administración\n${negocio!.nombre}'
              : 'Panel de Administración',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserAndBusiness,
            tooltip: 'Actualizar información',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserAndBusiness,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact user info
                    _buildUserInfoCard(),
                    const SizedBox(height: 6),
                    // Prominent menu options
                    Expanded(
                      child: ListView(
                        children: [
                          _buildOptionTile(
                            icon: Icons.person,
                            title: 'Gestionar usuario',
                            subtitle: 'Datos personales',
                            onTap: () {
                             /*  Navigator.of(
                                context,
                              ).pushNamed(Routes.adminViewInventory); */
                            },
                          ),
                          _buildOptionTile(
                            icon: Icons.document_scanner,
                            title: 'Venta por Factura',
                            subtitle: 'Seguimiento de ventas por factura',
                            onTap: () {
                             /*  Navigator.of(
                                context,
                              ).pushNamed(Routes.adminViewUsers); */
                            },
                          ),
                          _buildOptionTile(
                            icon: Icons.fast_forward,
                            title: 'Venta Rapida',
                            subtitle: 'Selecciona los productos, y listo!',
                            onTap: () {
                             /*  Navigator.of(
                                context,
                              ).pushNamed(Routes.adminViewUsers); */
                            },
                          ),
                          /* _buildOptionTile(
                            icon: Icons.inventory_outlined,
                            title: 'Facturación',
                            subtitle: 'Generar y gestionar facturas',
                            onTap: () {
                              // Navegar a facturación
                            },
                          ),
                          _buildOptionTile(
                            icon: Icons.devices,
                            title: 'Gestión de Dispositivos',
                            subtitle: 'Ver y gestionar sesiones activas',
                            onTap: () {
                              _showDevicesDialog();
                            },
                          ),
                          _buildOptionTile(
                            icon: Icons.settings,
                            title: 'Configuraciones',
                            subtitle: 'Ajustes del negocio',
                            onTap: () {
                              // Navegar a configuraciones
                            },
                          ),
                          _buildOptionTile(
                            icon: Icons.analytics,
                            title: 'Ver Reportes',
                            subtitle: 'Análisis y estadísticas',
                            onTap: () {
                              // Navegar a reportes
                            },
                          ), */
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, ${userName ?? 'Usuario'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (negocio != null) ...[
                    Text(
                      'RUC: ${negocio!.ruc}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (negocio!.telefono != null)
                      Text(
                        'Tel: ${negocio!.telefono}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.orange[700],
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Amplify.Auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                "Cerrar sesión",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVigenciaCard() {
    if (negocio == null) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getVigenciaIcon(), color: _getVigenciaColor(), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Vigencia',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (fechaVencimiento != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$diasRestantes días',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getVigenciaColor(),
                    ),
                  ),
                  Text(
                    '${fechaVencimiento!.day}/${fechaVencimiento!.month}/${fechaVencimiento!.year}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              LinearProgressIndicator(
                value: vigenciaValida
                    ? diasRestantes / (negocio!.duration ?? 365)
                    : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getVigenciaColor()),
                minHeight: 3,
              ),
            ] else ...[
              Text(
                'Sin info',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesCard() {
    if (negocio == null) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, color: Colors.blue, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Dispositivos',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildDeviceInfo(
                  'Móvil',
                  Icons.smartphone,
                  maxDispositivosMovil,
                  Colors.green,
                ),
                const SizedBox(width: 4),
                _buildDeviceInfo(
                  'PC',
                  Icons.computer,
                  maxDispositivosPC,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.connected_tv,
                    color: Colors.purple,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Conectados: $dispositivosConectados',
                    style: GoogleFonts.poppins(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(String label, IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            '$count permitidos',
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final bool isEnabled = negocio != null && vigenciaValida;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey[200]!, Colors.grey[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isEnabled
                  ? Colors.black12
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isEnabled
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: AnimatedScale(
            scale: isEnabled ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEnabled
                    ? Theme.of(context).primaryColor.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: isEnabled
                    ? Theme.of(context).primaryColor
                    : Colors.grey[400],
              ),
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isEnabled ? Colors.black87 : Colors.grey[500],
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isEnabled ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          trailing: AnimatedOpacity(
            opacity: isEnabled ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: isEnabled
                  ? Theme.of(context).primaryColor
                  : Colors.grey[400],
            ),
          ),
          onTap: isEnabled
              ? () {
                  // Agregar feedback háptico (si está soportado)
                  // HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
        ),
      ),
    );
  }

  void _showDevicesDialog() async {
    if (negocio == null) return;

    try {
      final sessions = await DeviceSessionService.getActiveSessions(
        negocio!.id,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dispositivos Conectados'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: sessions.isEmpty
                  ? const Center(child: Text('No hay dispositivos conectados'))
                  : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        if (session == null) {
                          return const ListTile(title: Text('Sesión inválida'));
                        }
                        return ListTile(
                          leading: Icon(
                            session.deviceType == 'MOVIL'
                                ? Icons.smartphone
                                : Icons.computer,
                          ),
                          title: Text(
                            session.deviceInfo ?? 'Dispositivo desconocido',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Usuario: ${session.userId ?? 'N/A'}'),
                              Text(
                                'Último acceso: ${session.lastActivity.getDateTimeInUtc().toLocal().toString().substring(0, 16) ?? 'N/A'}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              _disconnectDevice(session.id);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar dispositivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice(String sessionId) async {
    try {
      await DeviceSessionService.closeSpecificSession(sessionId);
      await _refreshVigenciaInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispositivo desconectado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desconectar dispositivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
