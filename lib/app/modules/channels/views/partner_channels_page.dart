// Gestion minimale des chaînes pour un PARTENAIRE connecté dans l'app :
// liste de ses chaînes + stats, ordre (haut/bas), visibilité, ajout d'une
// vidéo YouTube / d'un short. L'interface principale reste le web.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_field.dart';
import 'package:grand_public_v2/app/modules/channels/controllers/channels_list_controller.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class PartnerChannelsPage extends StatefulWidget {
  const PartnerChannelsPage({super.key});
  @override
  State<PartnerChannelsPage> createState() => _PartnerChannelsPageState();
}

class _PartnerChannelsPageState extends State<PartnerChannelsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true, _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final r = await RequestService().get('/partner/channels');
      _items = (r.data['data']['channels'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String m) => Get.snackbar('', m, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12), duration: const Duration(seconds: 2));

  Future<void> _post(String path, [Map<String, dynamic>? data, String? ok]) async {
    try {
      await RequestService().post(path, data: data);
      if (ok != null) _toast(ok);
      await _load();
      if (Get.isRegistered<ChannelsListController>()) Get.find<ChannelsListController>().load();
    } catch (_) {
      _toast('Action impossible, réessayez.');
    }
  }

  void _addMedia(Map<String, dynamic> ch) {
    final cats = (ch['categories'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final title = TextEditingController(), url = TextEditingController();
    int? cat = cats.isNotEmpty ? cats.first['id'] as int : null;
    bool short = false;
    Get.bottomSheet(
      StatefulBuilder(builder: (ctx, setS) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Ajouter une vidéo — ${ch['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              AppField(controller: title, hint: 'Titre', icon: Icons.title_rounded),
              const SizedBox(height: 10),
              AppField(controller: url, hint: 'Lien YouTube', icon: Icons.link_rounded, keyboardType: TextInputType.url),
              const SizedBox(height: 10),
              if (cats.isNotEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in cats)
                    ChoiceChip(
                      label: Text(c['name'].toString()),
                      selected: cat == c['id'],
                      selectedColor: GPTheme.primaryColor,
                      labelStyle: TextStyle(color: cat == c['id'] ? Colors.white : null, fontWeight: FontWeight.w700),
                      onSelected: (_) => setS(() => cat = c['id'] as int),
                    ),
                ])
              else
                const Text('Créez d\'abord une catégorie depuis le web.'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: GPTheme.primaryColor,
                title: const Text('C\'est un short (vertical)'),
                value: short,
                onChanged: (v) => setS(() => short = v),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: GPTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                onPressed: cat == null
                    ? null
                    : () {
                        if (title.text.trim().isEmpty || url.text.trim().isEmpty) {
                          _toast('Titre et lien requis.');
                          return;
                        }
                        Get.back();
                        _post('/partner/channels/${ch['id']}/media', {'category_id': cat, 'title': title.text.trim(), 'youtube_url': url.text.trim(), 'short': short}, 'Vidéo publiée.');
                      },
                child: const Text('Publier', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GPTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: Get.back),
        title: const Text('Mes chaînes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: GPTheme.primaryColor))
          : _error
              ? Center(child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Réessayer')))
              : _items.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(28), child: Text('Aucune chaîne. Créez-en une depuis le tableau de bord web.', textAlign: TextAlign.center)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final c = _items[i];
                          final active = c['is_active'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: Column(children: [
                              Row(children: [
                                CircleAvatar(radius: 24, backgroundColor: GPTheme.primaryColor, backgroundImage: c['logo_url'] != null ? NetworkImage(c['logo_url'].toString()) : null, child: c['logo_url'] == null ? Text(c['name'].toString()[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)) : null),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  Text('${c['subscribers']} abonnés · ${c['medias_count']} contenus · ${(c['net_total'] as num).round()} F net', style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
                                ])),
                                IconButton(tooltip: 'Monter', icon: const Icon(Icons.keyboard_arrow_up_rounded), onPressed: i == 0 ? null : () => _post('/partner/channels/reorder', {'channel_id': c['id'], 'direction': 'up'})),
                                IconButton(tooltip: 'Descendre', icon: const Icon(Icons.keyboard_arrow_down_rounded), onPressed: i == _items.length - 1 ? null : () => _post('/partner/channels/reorder', {'channel_id': c['id'], 'direction': 'down'})),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                Expanded(child: OutlinedButton.icon(onPressed: () => Get.toNamed('/channel/${c['id']}'), icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('Voir'))),
                                const SizedBox(width: 8),
                                Expanded(child: OutlinedButton.icon(onPressed: () => _addMedia(c), icon: const Icon(Icons.add_circle_outline, size: 18), label: const Text('Vidéo'))),
                                const SizedBox(width: 8),
                                Switch(value: active, activeColor: GPTheme.primaryColor, onChanged: (_) => _post('/partner/channels/${c['id']}/toggle', null, active ? 'Chaîne masquée.' : 'Chaîne visible.')),
                              ]),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }
}
