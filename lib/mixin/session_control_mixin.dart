import 'dart:async';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/page/auth/login_page.dart';
import 'package:app_facturacion/services/device_session_service.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:flutter/material.dart';

/// Mixin que proporciona control automático de sesiones y vigencia
/// Úsalo en cualquier página que requiera verificación de sesión
mixin SessionControlMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  Timer? _sessionKeepAliveTimer;
  Timer? _vigenciaCheckTimer;
  bool _isSessionActive = false;

  /// Override este método si necesitas lógica personalizada cuando la sesión expire
  Future<void> onSessionExpired(String reason)async {
    await _performLogout(reason);
  }

  /// Override este método si necesitas lógica personalizada cuando la vigencia expire
  Future<void> onVigenciaExpired()async {
    await _showVigenciaExpiredDialog();
  }

  /// Inicializa el control de sesión
  /// Llama esto en initState()de tu widget
  Future<bool> initializeSessionControl()async {
    try {
      // Verificar sesión actual
      final userInfo = await NegocioService.getCurrentUserInfo();
      final negocioId = userInfo.negocioId;

      final negocio = await NegocioService.getNegocioById(negocioId);
      if (negocio == null){
        await onSessionExpired('No se pudo cargar información del negocio');
        return false;
      }

      // Verificar vigencia
      final isVigenciaValid = await DeviceSessionService.checkNegocioVigencia(
        negocio,
      );
      if (!isVigenciaValid){
        await onVigenciaExpired();
        return false;
      }

      // Verificar acceso del dispositivo
      final accessResult = await DeviceSessionService.checkDeviceAccess(
        negocio,
        userInfo.userId ?? '',
      );

      if (!accessResult.success){
        if (accessResult.isExpired){
          await onVigenciaExpired();
        } else {
          await onSessionExpired(
            accessResult.errorMessage ?? 'Error de acceso',
          );
        }
        return false;
      }

      // Inicializar timers
      _startSessionTimers();
      _isSessionActive = true;
      return true;
    } catch (e){
      await onSessionExpired('Error al inicializar sesión: $e');
      return false;
    }
  }

  /// Inicia los timers para mantener la sesión
  void _startSessionTimers(){
    // Timer para mantener la sesión activa cada 5 minutos
    _sessionKeepAliveTimer = Timer.periodic(const Duration(minutes: 5), (
      _,
    )async {
      if (_isSessionActive){
        try {
          await DeviceSessionService.keepSessionAlive();
        } catch (e){
          await onSessionExpired('Error manteniendo sesión: $e');
        }
      }
    });

    // Timer para verificar vigencia cada hora
    _vigenciaCheckTimer = Timer.periodic(const Duration(hours: 1), (_)async {
      if (_isSessionActive){
        await _checkVigencia();
      }
    });
  }

  /// Verifica la vigencia del negocio
  Future<void> _checkVigencia()async {
    try {
      final userInfo = await NegocioService.getCurrentUserInfo();
      final negocioId = userInfo.negocioId;

      final negocio = await NegocioService.getNegocioById(negocioId);
      if (negocio != null){
        final isValid = await DeviceSessionService.checkNegocioVigencia(
          negocio,
        );
        if (!isValid){
          await onVigenciaExpired();
        }
      }
        } catch (e){
      safePrint('Error verificando vigencia: $e');
    }
  }

  /// Muestra el diálogo de vigencia expirada
  Future<void> _showVigenciaExpiredDialog()async {
    if (!mounted)return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context)=> WillPopScope(
        onWillPop: ()async => false,
        child: AlertDialog(
          title: const Text('Vigencia Expirada'),
          content: const Text(
            'La vigencia de su negocio ha expirado. '
            'Contacte al administrador para renovar el servicio.',
          ),
          actions: [
            TextButton(
              onPressed: ()async {
                Navigator.of(context).pop();
                await _performLogout('Vigencia expirada');
              },
              child: const Text('Entendido'),
            ),
          ],
        ),
      ),
    );
  }

  /// Realiza el logout y navega a la pantalla de login
  Future<void> _performLogout(String reason)async {
    try {
      _isSessionActive = false;
      await DeviceSessionService.closeCurrentSession();
      await Amplify.Auth.signOut();

      if (mounted){
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_)=> const LoginScreen()),
          (route)=> false,
        );
      }
    } catch (e){
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Limpia los recursos de la sesión
  /// Llama esto en dispose()de tu widget
  void disposeSessionControl(){
    _isSessionActive = false;
    _sessionKeepAliveTimer?.cancel();
    _vigenciaCheckTimer?.cancel();
  }

  /// Maneja los cambios en el ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    super.didChangeAppLifecycleState(state);

    if (!_isSessionActive)return;

    switch (state){
      case AppLifecycleState.resumed:
        // Verificar sesión al volver a la app
        DeviceSessionService.keepSessionAlive().catchError((e){
          onSessionExpired('Error al reanudar sesión: $e');
        });
        break;
      case AppLifecycleState.paused:
        // Opcional: cerrar sesión al pausar la app
        // DeviceSessionService.closeCurrentSession();
        break;
      case AppLifecycleState.detached:
        // Cerrar sesión al cerrar la app
        DeviceSessionService.closeCurrentSession();
        break;
      case AppLifecycleState.inactive:
        // No hacer nada en estado inactivo
        break;
      case AppLifecycleState.hidden:
        // Estado para cuando la app está oculta pero aún ejecutándose
        break;
    }
  }

  /// Obtiene el estado actual de la sesión
  bool get isSessionActive => _isSessionActive;

  /// Fuerza una verificación de sesión
  Future<bool> refreshSession()async {
    return await initializeSessionControl();
  }
}
