// lib/app/services/crush_quota_service.dart
//
// Point UNIQUE de vérité pour tout ce qui concerne le quota de messages
// Crush : récupération du statut, récupération des packs, et un seul flag
// `isEnabled` que TOUS les widgets Crush (bannière de quota, paywall,
// blocage à l'envoi) consultent avant d'afficher quoi que ce soit.
//
// Tant que le backend renvoie `enabled: false` (comportement par défaut,
// voir config('custom.crush_message_limit_enabled') côté Laravel), cette
// classe se comporte comme si la fonctionnalité n'existait pas : aucun
// widget ne s'affiche, aucun envoi de message n'est jamais bloqué.

import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/message_credit_pack_model.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class CrushQuotaService extends GetxService {
  static CrushQuotaService get to => Get.find();

  final Rx<CrushQuotaStatus> status =
      const CrushQuotaStatus(enabled: false).obs;
  final RxList<MessageCreditPack> packs = <MessageCreditPack>[].obs;
  final RxBool isLoadingPacks = false.obs;

  bool get isEnabled => status.value.enabled;

  Future<CrushQuotaService> init() async {
    await refreshQuota();
    return this;
  }

  Future<void> refreshQuota() async {
    try {
      final res = await RequestService().get('/crush/quota');
      final data = res.data?['data'];
      status.value = data != null
          ? CrushQuotaStatus.fromJson(data)
          : const CrushQuotaStatus(enabled: false);
    } catch (_) {
      // Ne bloque jamais l'app pour une histoire de quota.
      status.value = const CrushQuotaStatus(enabled: false);
    }
  }

  Future<void> loadPacks() async {
    if (!isEnabled) return;
    isLoadingPacks.value = true;
    try {
      final res = await RequestService().get('/crush/packs');
      final list = (res.data?['data'] as List<dynamic>? ?? [])
          .map((j) => MessageCreditPack.fromJson(j))
          .toList();
      packs.assignAll(list);
    } catch (_) {
      packs.clear();
    } finally {
      isLoadingPacks.value = false;
    }
  }

  /// À appeler après un achat de pack confirmé par le backend, pour
  /// rafraîchir immédiatement le solde affiché.
  Future<void> onPackPurchaseConfirmed(Map<String, dynamic> quotaJson) async {
    status.value = CrushQuotaStatus.fromJson(quotaJson);
  }
}
