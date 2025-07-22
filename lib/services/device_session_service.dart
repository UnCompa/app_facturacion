import 'dart:io';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/ModelProvider.dart';
import 'package:app_facturacion/services/negocio_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

// Modelo para sesiones activas (agrega esto a tu schema GraphQL)
/*
type SesionDispositivo
  @model
  @auth(
    rules: [
      { allow: groups, groups: ["superadmin"] }
      { allow: groups, groups: ["admin"], operations: [read, update, create, delete] }
      { allow: groups, groups: ["vendedor"], operations: [read, create, delete] }
    ]
  ){
  id: ID!
  negocioId: ID! @index(name: "byNegocio")
  userId: String!
  deviceId: String!
  deviceType: String! # "PC" o "MOVIL"
  deviceInfo: String
  isActive: Boolean!
  lastActivity: AWSDateTime!
  createdAt: AWSDateTime
  updatedAt: AWSDateTime
}
*/

class DeviceSessionService {
  static const int SESSION_TIMEOUT_HOURS = 24;

  /// Verifica la vigencia del negocio
  static Future<bool> checkNegocioVigencia(Negocio negocio)async {
    if (negocio.duration == null)return true; // Sin límite de duración

    final createdAt = negocio.createdAt;
    if (createdAt == null)return true;

    final now = DateTime.now();
    final createdDate = createdAt.getDateTimeInUtc();
    final expiryDate = createdDate.add(Duration(days: negocio.duration!));

    return now.isBefore(expiryDate);
  }

  /// Obtiene información del dispositivo actual
  static Future<Map<String, String>> getDeviceInfo()async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String deviceType = '';
    String deviceDescription = '';

    try {
      if (kIsWeb){
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceId = '${webInfo.browserName}_${webInfo.userAgent?.hashCode}';
        deviceType = 'PC';
        deviceDescription = '${webInfo.browserName} ${webInfo.platform}';
      } else if (Platform.isAndroid){
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceType = 'MOVIL';
        deviceDescription = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS){
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceType = 'MOVIL';
        deviceDescription = '${iosInfo.name} ${iosInfo.model}';
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux){
        deviceId = Platform.localHostname;
        deviceType = 'PC';
        deviceDescription =
            '${Platform.operatingSystem} ${Platform.localHostname}';
      }
    } catch (e){
      safePrint('Error obteniendo info del dispositivo: $e');
      deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      deviceType = kIsWeb ? 'PC' : 'MOVIL';
      deviceDescription = 'Dispositivo desconocido';
    }

    return {
      'deviceId': deviceId,
      'deviceType': deviceType,
      'deviceDescription': deviceDescription,
    };
  }

  /// Verifica si el dispositivo puede conectarse
  static Future<DeviceAccessResult> checkDeviceAccess(
    Negocio negocio,
    String userId,
  )async {
    try {
      // 1. Verificar vigencia del negocio
      if (!await checkNegocioVigencia(negocio)){
        return DeviceAccessResult.expired();
      }

      // 2. Obtener información del dispositivo
      final deviceInfo = await getDeviceInfo();
      final deviceType = deviceInfo['deviceType']!;
      final deviceId = deviceInfo['deviceId']!;

      // 3. Verificar si este dispositivo ya tiene una sesión activa
      final existingSession = await _getActiveSession(negocio.id, deviceId);
      if (existingSession != null){
        // Actualizar última actividad
        await _updateSessionActivity(existingSession);
        return DeviceAccessResult.success(existingSession);
      }

      // 4. Verificar límites de dispositivos
      final activeSessions = await _getActiveSessions(negocio.id, deviceType);
      final maxDevices = deviceType == 'PC'
          ? negocio.pcAccess
          : negocio.movilAccess;

      if (maxDevices != null && activeSessions.length >= maxDevices){
        return DeviceAccessResult.limitReached(deviceType, maxDevices);
      }

      // 5. Crear nueva sesión
      final newSession = await _createSession(
        negocio.id,
        userId,
        deviceId,
        deviceType,
        deviceInfo['deviceDescription']!,
      );

      return DeviceAccessResult.success(newSession);
    } catch (e){
      safePrint('Error verificando acceso del dispositivo: $e');
      return DeviceAccessResult.error(e.toString());
    }
  }

  /// Obtiene una sesión activa por dispositivo
  static Future<SesionDispositivo?> _getActiveSession(
    String negocioId,
    String deviceId,
  )async {
    try {
      const String query = '''
        query ListSesionesDispositivo(
          \$negocioId: ID!
          \$filter: ModelSesionDispositivoFilterInput
        ){
          listSesionDispositivos(
            filter: {
              negocioId: { eq: \$negocioId }
              deviceId: { eq: \$deviceId }
              isActive: { eq: true }
            }
          ){
            items {
              id
              negocioId
              userId
              deviceId
              deviceType
              deviceInfo
              isActive
              lastActivity
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {'negocioId': negocioId, 'deviceId': deviceId},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null){
        final data = response.data as Map<String, dynamic>;
        final items = data['listSesionDispositivos']['items'] as List;

        if (items.isNotEmpty){
          final session = SesionDispositivo.fromJson(items.first);

          // Verificar si la sesión no ha expirado
          final lastActivity = session.lastActivity.getDateTimeInUtc();
          final now = DateTime.now();
          final hoursSinceActivity = now.difference(lastActivity).inHours;

          if (hoursSinceActivity > SESSION_TIMEOUT_HOURS){
            // Marcar sesión como inactiva
            await _deactivateSession(session.id);
            return null;
          }

          return session;
        }
      }
      return null;
    } catch (e){
      safePrint('Error obteniendo sesión activa: $e');
      return null;
    }
  }

  /// Obtiene todas las sesiones activas por tipo de dispositivo
  static Future<List<SesionDispositivo>> _getActiveSessions(
    String negocioId,
    String deviceType,
  )async {
    try {
      const String query = '''
        query ListSesionesDispositivo(\$negocioId: ID!){
          listSesionDispositivos(
            filter: {
              negocioId: { eq: \$negocioId }
              deviceType: { eq: \$deviceType }
              isActive: { eq: true }
            }
          ){
            items {
              id
              negocioId
              userId
              deviceId
              deviceType
              deviceInfo
              isActive
              lastActivity
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {'negocioId': negocioId, 'deviceType': deviceType},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null){
        final data = response.data as Map<String, dynamic>;
        final items = data['listSesionDispositivos']['items'] as List;

        List<SesionDispositivo> activeSessions = [];
        final now = DateTime.now();

        for (final item in items){
          final session = SesionDispositivo.fromJson(item);
          final lastActivity = session.lastActivity.getDateTimeInUtc();

          final hoursSinceActivity = now.difference(lastActivity).inHours;

          if (hoursSinceActivity > SESSION_TIMEOUT_HOURS){
            // Desactivar sesión expirada
            await _deactivateSession(session.id);
          } else {
            activeSessions.add(session);
          }
        }

        return activeSessions;
      }
      return [];
    } catch (e){
      safePrint('Error obteniendo sesiones activas: $e');
      return [];
    }
  }

  /// Crea una nueva sesión
  static Future<SesionDispositivo> _createSession(
    String negocioId,
    String userId,
    String deviceId,
    String deviceType,
    String deviceInfo,
  )async {
    final session = SesionDispositivo(
      negocioId: negocioId,
      userId: userId,
      deviceId: deviceId,
      deviceType: deviceType,
      deviceInfo: deviceInfo,
      isActive: true,
      lastActivity: TemporalDateTime.now(),
    );

    final request = ModelMutations.create(session);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.data != null){
      return response.data!;
    } else {
      throw Exception('Error creando sesión: ${response.errors}');
    }
  }

  /// Actualiza la última actividad de una sesión
  static Future<void> _updateSessionActivity(SesionDispositivo session)async {
    try {
      final updatedSession = session.copyWith(
        lastActivity: TemporalDateTime.now(),
      );

      final request = ModelMutations.update(updatedSession);
      await Amplify.API.mutate(request: request).response;
    } catch (e){
      safePrint('Error actualizando actividad de sesión: $e');
    }
  }

  /// Desactiva una sesión
  static Future<void> _deactivateSession(String sessionId)async {
    try {
      // Primero obtener la sesión
      final getRequest = ModelQueries.get(
        SesionDispositivo.classType,
        SesionDispositivoModelIdentifier(id: sessionId),
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;

      if (getResponse.data != null){
        final session = getResponse.data!.copyWith(isActive: false);
        final updateRequest = ModelMutations.update(session);
        await Amplify.API.mutate(request: updateRequest).response;
      }
    } catch (e){
      safePrint('Error desactivando sesión: $e');
    }
  }

  /// Cierra la sesión del dispositivo actual
  static Future<void> closeCurrentSession()async {
    try {
      final deviceInfo = await getDeviceInfo();
      final user = await Amplify.Auth.getCurrentUser();
      final userInfo = await NegocioService.getCurrentUserInfo();
      final negocioId = userInfo.negocioId;

      final session = await _getActiveSession(
        negocioId,
        deviceInfo['deviceId']!,
      );
      if (session != null){
        await _deactivateSession(session.id);
      }
    } catch (e){
      safePrint('Error cerrando sesión actual: $e');
    }
  }

  /// Mantiene la sesión activa (llamar periódicamente)
  static Future<void> keepSessionAlive()async {
    try {
      final deviceInfo = await getDeviceInfo();
      final userInfo = await NegocioService.getCurrentUserInfo();
      final negocioId = userInfo.negocioId;

      final session = await _getActiveSession(
        negocioId,
        deviceInfo['deviceId']!,
      );
      if (session != null){
        await _updateSessionActivity(session);
      }
        } catch (e){
      safePrint('Error manteniendo sesión activa: $e');
    }
  }
  /// Obtiene todas las sesiones activas para un negocio
  static Future<List<SesionDispositivo?>> getActiveSessions(String negocioId)async {
    try {
      final request = ModelQueries.list(
        SesionDispositivo.classType,
        where: SesionDispositivo.NEGOCIOID
            .eq(negocioId)
            .and(SesionDispositivo.ISACTIVE.eq(true)),
      );
      final response = await Amplify.API.query(request: request).response;

      final sessions = response.data?.items;
      if (sessions == null){
        safePrint('Errores: ${response.errors}');
        return const [];
      }

      List<SesionDispositivo?> activeSessions = [];
      final now = DateTime.now();

      for (final session in sessions){
        if (session == null)continue;
        final lastActivity = session.lastActivity.getDateTimeInUtc();
        final hoursSinceActivity = now.difference(lastActivity).inHours;

        if (hoursSinceActivity > SESSION_TIMEOUT_HOURS){
          // Desactivar sesión expirada
          await _deactivateSession(session.id);
        } else {
          activeSessions.add(session);
        }
      }

      return activeSessions;
    } on ApiException catch (e){
      safePrint('Consulta de sesiones fallida: $e');
      return const [];
    }
  }

  /// Cierra una sesión específica
  static Future<void> closeSpecificSession(String sessionId)async {
    try {
      final getRequest = ModelQueries.get(
        SesionDispositivo.classType,
        SesionDispositivoModelIdentifier(id: sessionId),
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;

      final session = getResponse.data;
      if (session == null){
        safePrint('Errores: ${getResponse.errors}');
        throw Exception('Sesión no encontrada');
      }

      if (!session.isActive){
        return;
      }

      final updatedSession = session.copyWith(isActive: false);
      final updateRequest = ModelMutations.update(updatedSession);
      final updateResponse = await Amplify.API
          .mutate(request: updateRequest)
          .response;

      if (updateResponse.data == null){
        safePrint('Errores al actualizar: ${updateResponse.errors}');
        throw Exception('Error al cerrar la sesión');
      }
    } on ApiException catch (e){
      safePrint('Cierre de sesión fallido: $e');
      rethrow;
    }
  }
  /// Obtiene información de los dispositivos conectados para un negocio
/// Obtiene información de los dispositivos conectados para un negocio
static Future<Map<String, dynamic>> getConnectedDevicesInfo(
  String negocioId,
)async {
  try {
    final request = ModelQueries.list(
      SesionDispositivo.classType,
      where: SesionDispositivo.NEGOCIOID
          .eq(negocioId)
          .and(SesionDispositivo.ISACTIVE.eq(true)),
    );
    final response = await Amplify.API.query(request: request).response;

    final sessions = response.data?.items;
    if (sessions == null){
      safePrint('Errores: ${response.errors}');
      return {'devices': [], 'total': 0};
    }

    List<Map<String, dynamic>> connectedDevices = [];
    final now = DateTime.now();

    for (final session in sessions){
      if (session == null)continue;
      final lastActivity = session.lastActivity.getDateTimeInUtc();
      final hoursSinceActivity = now.difference(lastActivity).inHours;

      if (hoursSinceActivity > SESSION_TIMEOUT_HOURS){
        // Desactivar sesión expirada
        await _deactivateSession(session.id);
        continue;
      }

      // Intentar obtener el nombre del usuario (si tienes un método para esto)
      String userName = session.userId;
      try {
        final userInfo = await NegocioService.getCurrentUserInfo();
        userName = userInfo.userId ?? session.userId; // Ajusta según tu modelo
      } catch (e){
        safePrint(
          'Error obteniendo nombre de usuario para ${session.userId}: $e',
        );
      }

      connectedDevices.add({
        'sessionId': session.id,
        'deviceType': session.deviceType.toLowerCase(),
        'deviceName': session.deviceInfo ?? 'Dispositivo desconocido',
        'userName': userName,
        'lastAccess': session.lastActivity
            .getDateTimeInUtc()
            .toLocal()
            .toString()
            .substring(0, 16),
      });
    }

    return {
      'devices': connectedDevices,
      'total': connectedDevices.length,
    };
  } on ApiException catch (e){
    safePrint('Consulta de dispositivos conectados fallida: $e');
    return {'devices': [], 'total': 0};
  }
}
}

/// Resultado de la verificación de acceso del dispositivo
class DeviceAccessResult {
  final bool success;
  final String? errorMessage;
  final SesionDispositivo? session;
  final String? deviceType;
  final int? maxDevices;
  final bool isExpired;

  DeviceAccessResult._({
    required this.success,
    this.errorMessage,
    this.session,
    this.deviceType,
    this.maxDevices,
    this.isExpired = false,
  });

  factory DeviceAccessResult.success(SesionDispositivo session){
    return DeviceAccessResult._(success: true, session: session);
  }

  factory DeviceAccessResult.limitReached(String deviceType, int maxDevices){
    return DeviceAccessResult._(
      success: false,
      errorMessage:
          'Límite de dispositivos $deviceType alcanzado ($maxDevices)',
      deviceType: deviceType,
      maxDevices: maxDevices,
    );
  }

  factory DeviceAccessResult.expired(){
    return DeviceAccessResult._(
      success: false,
      errorMessage: 'La vigencia del negocio ha expirado',
      isExpired: true,
    );
  }

  factory DeviceAccessResult.error(String message){
    return DeviceAccessResult._(success: false, errorMessage: message);
  }
}
