import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/channel_model.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

/// Liste des chaînes (onglet « Chaînes » de Youwiiin) avec affichage
/// GRILLE (2 colonnes) ou LISTE (1 ligne), mémorisé entre les sessions.
class ChannelsListController extends GetxController {
  static const _layoutKey = 'channels_layout_grid';

  final channels = <ChannelModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final isGrid = true.obs;
  final search = ''.obs;

  @override
  void onInit() {
    super.onInit();
    isGrid.value = GetStorage().read<bool>(_layoutKey) ?? true;
    load();
  }

  void toggleLayout() {
    isGrid.value = !isGrid.value;
    GetStorage().write(_layoutKey, isGrid.value);
  }

  List<ChannelModel> get filtered {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return channels;
    return channels.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  Future<void> load() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final r = await RequestService().get('/channels');
      channels.assignAll((r.data['data']['channels'] as List<dynamic>? ?? [])
          .map((j) => ChannelModel.fromJson(Map<String, dynamic>.from(j as Map))));
    } catch (e) {
      debugPrint('ChannelsListController.load: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
