// lib/app/modules/channels/controllers/channel_controller.dart
//
// Page d'une chaîne = EXACTEMENT la page d'un espace (bannière/logo,
// catégories, contenus premium ou non, lives) : on réutilise SpaceView et on
// ne remplace que le chargement des données (GET /channels/{id}).

import 'package:flutter/material.dart';
// import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/channel_model.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/modules/space/controllers/space_controller.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class ChannelController extends SpaceController {
  @override
  bool get isChannel => true;

  int get channelId => spaceId; // le paramètre de route `id` est l'id de la chaîne

  @override
  Future<void> loadSpace() async {
    isLoading.value = true;
    try {
      final r = await RequestService().get('/channels/$channelId');
      final data = r.data['data'] as Map<String, dynamic>;
      final ch = Map<String, dynamic>.from(data['channel'] as Map);
      channel.value = ChannelModel.fromJson(ch);

      space.value = SpaceModel.fromJson({
        ...ch,
        'is_active': true,
        'categories': data['categories'] ?? [],
      });

      final cats = space.value!.categories;
      if (cats.isNotEmpty) {
        final idx = initialCategoryIndex.clamp(0, cats.length - 1);
        selectedCategoryIndex.value = idx;
        await loadCategoryMedias(cats[idx].id);
      }
    } catch (e) {
      debugPrint('ChannelController.loadSpace error: $e');
      space.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Rechargement après un abonnement (déverrouille les contenus premium).
  Future<void> refreshAfterPayment() async {
    final catId = space.value?.categories.isNotEmpty == true
        ? space.value!.categories[selectedCategoryIndex.value.clamp(0, space.value!.categories.length - 1)].id
        : null;
    await loadSpace();
    if (catId != null) await reloadCategory(catId);
  }
}
