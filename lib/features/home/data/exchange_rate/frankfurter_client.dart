import 'dart:convert';

import '../../../../core/network/atlas_http_client.dart';
import '../../domain/models/home_models.dart';
import 'exchange_rate_mapper.dart';

/// Client réseau pour l'API Frankfurter (taux EUR/MAD).
class FrankfurterClient {
  const FrankfurterClient();

  static final Uri _eurMadRateUri = Uri.https(
    'api.frankfurter.dev',
    '/v2/rate/EUR/MAD',
  );

  /// Récupère le dernier taux de référence EUR → MAD.
  Future<ExchangeRateData> fetchEurMadRate() async {
    final body = await AtlasHttpClient.get(_eurMadRateUri.toString());
    final json = jsonDecode(body) as Map<String, dynamic>;
    return ExchangeRateMapper.fromFrankfurter(json);
  }
}
