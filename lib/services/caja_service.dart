import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/models/Caja.dart';
import 'package:app_facturacion/services/negocio_service.dart';

class CajaService {
  static Future<Caja> getCurrentCaja() async {
    try {
      final negocioInfo = await NegocioService.getCurrentUserInfo();
      final request = ModelQueries.list(
        Caja.classType,
        where: Caja.NEGOCIOID.eq(negocioInfo.negocioId) & Caja.ISDELETED.eq(false),
        limit: 1,
      );
      final response = await Amplify.API.query(request: request).response;
      final caja = response.data?.items.first;
      return caja!;
    } catch (e) {
      rethrow;
    }
  }
}
