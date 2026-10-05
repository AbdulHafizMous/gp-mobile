import 'package:grand_public_v2/app/services/dio.services.dart';

/// Liste des professions (backend : GET /professions), mise en cache pour la session.
class ProfessionService {
  ProfessionService._();
  static List<String>? _cache;

  static Future<List<String>> load({bool force = false}) async {
    if (!force && _cache != null && _cache!.isNotEmpty) return _cache!;
    final res = await RequestService().get('/professions');
    final raw = res.data is Map ? res.data['data'] : res.data;
    final list = (raw as List)
        .map((e) => (e is Map ? e['name'] : e).toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    _cache = list;
    return list;
  }
}
