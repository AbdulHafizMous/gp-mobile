import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class ClubController extends GetxController {
  final promotions   = <Promotion>[].obs;
  final isLoading    = false.obs;
  final isClaiming   = false.obs;
  final hasMore      = false.obs;

  // ── Onglet Club (0 = Offres, 1 = Partenaires) ─────────────────────────
  final clubTab   = 0.obs;
  final searchCtrl = TextEditingController();
  final searchQuery = ''.obs;

  final partners        = <PartnerFiche>[].obs;
  final isPartnersLoading = false.obs;

  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    fetchPromotions();
    fetchPartners();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    fetchPromotions(refresh: true);
    fetchPartners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PARTENAIRES
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> fetchPartners() async {
    isPartnersLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        partners.value = [];
        return;
      }
      final response = await RequestService().get(
        '/partners',
        queryParameters: searchQuery.value.isNotEmpty
            ? {'search': searchQuery.value}
            : null,
      );
      if (response.statusCode == 200) {
        final list = (response.data['data'] as List)
            .map((e) => PartnerFiche.fromJson(e))
            .toList();
        partners.value = list;
      }
    } on DioException catch (e) {
      debugPrint('fetchPartners DioError: ${e.message}');
    } catch (e) {
      debugPrint('fetchPartners error: $e');
    } finally {
      isPartnersLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FETCH
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> fetchPromotions({bool refresh = false}) async {
    if (refresh) { _page = 1; promotions.clear(); }
    isLoading.value = true;

    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        promotions.value = _mockPromotions();
        return;
      }

      final response = await RequestService().get(
        '/promotions',
        queryParameters: {
          'page': _page,
          'per_page': 20,
          if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        },
      );

      if (response.statusCode == 200) {
        final data  = response.data['data'];
        final list  = (data['promotions'] as List)
            .map((e) => Promotion.fromJson(e))
            .toList();

        refresh ? promotions.value = list : promotions.addAll(list);
        hasMore.value = data['pagination']['has_more_pages'] as bool? ?? false;
        _page++;
      }
    } on DioException catch (e) {
      debugPrint('fetchPromotions DioError: ${e.message}');
    } catch (e) {
      debugPrint('fetchPromotions error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLAIM — génère un QR code
  // ══════════════════════════════════════════════════════════════════════════
  Future<PromotionUsage?> claimPromotion(Promotion promo) async {
    isClaiming.value = true;

    try {
      if (useMock) {
        await Future.delayed(const Duration(seconds: 1));
        final mockUsage = PromotionUsage(
          id:          999,
          qrCode:      'MOCK-${promo.id}-${DateTime.now().millisecondsSinceEpoch}',
          status:      'pending',
          generatedAt: DateTime.now().toIso8601String(),
        );
        // Update local state
        final idx = promotions.indexWhere((p) => p.id == promo.id);
        if (idx != -1) {
          promotions[idx] = promotions[idx].copyWith(
            userPendingQr:    mockUsage.qrCode,
            userPendingUsage: mockUsage,
            userCanClaim:     false,
            userUsageCount:   promotions[idx].userUsageCount + 1,
          );
        }
        return mockUsage;
      }

      final response = await RequestService().post('/promotions/${promo.id}/claim');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final usage = PromotionUsage.fromJson(response.data['data']);

        // Update local state
        final idx = promotions.indexWhere((p) => p.id == promo.id);
        if (idx != -1) {
          promotions[idx] = promotions[idx].copyWith(
            userPendingQr:    usage.qrCode,
            userPendingUsage: usage,
            userCanClaim:     false,
            userUsageCount:   promotions[idx].userUsageCount + 1,
          );
        }
        return usage;
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString()
                ?? 'Impossible de générer le code QR.';
      _showError(msg);
    } catch (e) {
      _showError('Une erreur est survenue.');
    } finally {
      isClaiming.value = false;
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VALIDATE — partenaire scanne le QR
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> validateQrCode(String qrCode) async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(seconds: 1));
        return {
          'user_name':   'Mock User',
          'promo_title': 'Promotion Mock',
        };
      }

      final response = await RequestService().post(
        '/promotions/validate',
        data: {'qr_code': qrCode},
      );

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? 'Code QR invalide.';
      _showError(msg);
    } catch (e) {
      _showError('Une erreur est survenue.');
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOCK
  // ══════════════════════════════════════════════════════════════════════════
  List<Promotion> _mockPromotions() => [
    Promotion(
      id: 1, title: '-20% sur tous les menus',
      description: 'Profitez de 20% de réduction sur tous les menus du restaurant Partner Food.',
      type: 'discount', target: 'all',
      maxUsesPerUser: 2, totalMaxUses: 100, usedCount: 34,
      startsAt: '2026-01-01', endsAt: '2026-12-31',
      isActive: true, isExpired: false, isAvailable: true,
      partner: const PromotionPartner(id: 1, name: 'Partner Food'),
      userCanClaim: true, userUsageCount: 0,
    ),
    Promotion(
      id: 2, title: 'Accès VIP événement',
      description: 'Accès gratuit à notre prochain événement exclusif.',
      type: 'access', target: 'premium',
      maxUsesPerUser: 1, usedCount: 12,
      startsAt: '2026-03-01', endsAt: '2026-06-30',
      isActive: true, isExpired: false, isAvailable: true,
      partner: const PromotionPartner(id: 2, name: 'Club Prestige'),
      userCanClaim: false,
      userUsageCount: 1,
      userPendingQr: 'MOCK-2-123456',
      userPendingUsage: PromotionUsage(
        id: 10, qrCode: 'MOCK-2-123456', status: 'pending',
        generatedAt: '2026-03-10T10:00:00',
      ),
    ),
    Promotion(
      id: 3, title: 'Cadeau de bienvenue',
      description: 'Un cadeau offert pour tout nouvel abonné.',
      type: 'gift', target: 'active',
      maxUsesPerUser: 1, usedCount: 5,
      startsAt: '2026-01-01', endsAt: '2026-02-28',
      isActive: false, isExpired: true, isAvailable: false,
      partner: const PromotionPartner(id: 3, name: 'Grand Public Store'),
      userCanClaim: false, userUsageCount: 0,
    ),
  ];

  void _showError(String msg) {
    Get.snackbar(
      'Erreur', msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PARAMÈTRES CLUB — rappel d'offres activable/désactivable
  // ══════════════════════════════════════════════════════════════════════════
  final remindersEnabled = true.obs;
  final isTogglingReminders = false.obs;

  Future<void> toggleReminders(bool value) async {
    isTogglingReminders.value = true;
    final previous = remindersEnabled.value;
    remindersEnabled.value = value; // optimiste
    try {
      if (!useMock) {
        await RequestService().patch(
          '/club/reminder-toggle',
          data: {'enabled': value},
        );
      }
    } catch (e) {
      remindersEnabled.value = previous; // rollback si échec
      debugPrint('toggleReminders error: $e');
    } finally {
      isTogglingReminders.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ESPACE PARTENAIRE — stats (scan géré par PartnerScannerView)
  // ══════════════════════════════════════════════════════════════════════════
  final partnerStats = Rxn<Map<String, dynamic>>();
  final isPartnerStatsLoading = false.obs;

  bool get isPartner => activeUser.value.role == 'Partner';

  Future<void> fetchPartnerStats() async {
    if (!isPartner) return;
    isPartnerStatsLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        partnerStats.value = {
          'stats': {
            'total_promotions': 3, 'active_promotions': 2,
            'total_usages': 42, 'validated_usages': 30, 'pending_usages': 12,
          },
          'recent_usages': [],
        };
        return;
      }
      final res = await RequestService().get('/partner/stats');
      if (res.statusCode == 200) {
        partnerStats.value = Map<String, dynamic>.from(res.data['data']);
      }
    } catch (e) {
      debugPrint('fetchPartnerStats error: $e');
    } finally {
      isPartnerStatsLoading.value = false;
    }
  }
}