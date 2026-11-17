import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

/// État d'accès à un direct (live d'une catégorie, radio / TV « direct seulement »).
class LiveAccess {
  final String kind; // media_live | channel
  final int refId;
  final bool isPaid;
  final int price;
  final bool hasAccess;
  final int viewers;
  final String? streamUrl; // fourni seulement quand l'accès est acquis
  final String? youtubeId;
  const LiveAccess({required this.kind, required this.refId, this.isPaid = false, this.price = 0, this.hasAccess = true, this.viewers = 0, this.streamUrl, this.youtubeId});

  bool get locked => isPaid && !hasAccess;

  factory LiveAccess.fromJson(Map<String, dynamic> j) => LiveAccess(
        kind: j['kind']?.toString() ?? 'media_live',
        refId: int.tryParse('${j['ref_id']}') ?? 0,
        isPaid: j['is_paid'] == true || j['is_paid'] == 1,
        price: int.tryParse('${j['price']}') ?? 0,
        hasAccess: j['has_access'] != false && j['has_access'] != 0,
        viewers: int.tryParse('${j['viewers']}') ?? 0,
        streamUrl: (j['stream_url']?.toString().isNotEmpty ?? false) ? j['stream_url'].toString() : null,
        youtubeId: (j['youtube_id']?.toString().isNotEmpty ?? false) ? j['youtube_id'].toString() : null,
      );
}

/// API /live/{kind}/{id} : état + paywall, présence (heartbeat) et paiement Moneroo.
class LiveAccessService {
  static Future<LiveAccess?> state(String kind, int id) async {
    try {
      final r = await RequestService().get('/live/$kind/$id');
      if (r.statusCode == 200) return LiveAccess.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
    } catch (e) {
      debugPrint('LiveAccess.state: $e');
    }
    return null;
  }

  /// Renvoie false si l'accès est refusé (402 : le prix a changé ou le direct est devenu payant).
  static Future<bool> heartbeat(String kind, int id) async {
    try {
      final r = await RequestService().post('/live/$kind/$id/heartbeat');
      return r.statusCode != 402;
    } on DioException catch (e) {
      return e.response?.statusCode != 402;
    } catch (_) {
      return true;
    }
  }

  /// Initialise le paiement : { checkout_url, payment_id, return_url_prefix } ou null.
  static Future<Map<String, dynamic>?> pay(String kind, int id) async {
    try {
      final r = await RequestService().post('/live/$kind/$id/pay');
      if (r.statusCode == 200 || r.statusCode == 201) return Map<String, dynamic>.from(r.data['data'] as Map);
    } catch (e) {
      debugPrint('LiveAccess.pay: $e');
    }
    return null;
  }

  static Future<LiveAccess?> confirm(String kind, int id, String paymentId) async {
    try {
      final r = await RequestService().post('/live/$kind/$id/confirm', data: {'payment_id': paymentId});
      if (r.statusCode == 200 || r.statusCode == 201) return LiveAccess.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
    } catch (e) {
      debugPrint('LiveAccess.confirm: $e');
    }
    return null;
  }
}
