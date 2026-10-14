// Liste des chaînes : grille de 2 ou liste d'une ligne (même principe que
// les vidéos). Utilisable comme onglet (ChannelsListBody) ou comme page.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/ad_banner_widget.dart';
import 'package:grand_public_v2/app/components/ad_native_card.dart';
import 'package:grand_public_v2/app/data/models/channel_model.dart';
import 'package:grand_public_v2/app/modules/channels/controllers/channels_list_controller.dart';

void openChannel(int id) => Get.toNamed('/channel/$id');

class ChannelsListBody extends StatelessWidget {
  final Color accent;
  const ChannelsListBody({super.key, this.accent = const Color(0xFF6C63FF)});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<ChannelsListController>()
        ? Get.find<ChannelsListController>()
        : Get.put(ChannelsListController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      const AdBannerWidget(screen: 'channels'),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 4),
        child: Row(children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Icon(Icons.search_rounded, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => c.search.value = v,
                    decoration: const InputDecoration(hintText: 'Rechercher une chaîne', border: InputBorder.none, isDense: true),
                  ),
                ),
              ]),
            ),
          ),
          Obx(() => IconButton(
                tooltip: c.isGrid.value ? 'Afficher en liste' : 'Afficher en grille',
                icon: Icon(c.isGrid.value ? Icons.view_agenda_outlined : Icons.grid_view_rounded),
                onPressed: c.toggleLayout,
              )),
        ]),
      ),
      Expanded(
        child: Obx(() {
          if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
          if (c.hasError.value) {
            return Center(child: TextButton.icon(onPressed: c.load, icon: const Icon(Icons.refresh), label: const Text('Réessayer')));
          }
          final list = c.filtered;
          if (list.isEmpty) {
            return const Center(child: Text('Aucune chaîne pour le moment.'));
          }
          return RefreshIndicator(
            onRefresh: c.load,
            child: c.isGrid.value ? _grid(list, accent) : _rows(list, accent, isDark),
          );
        }),
      ),
    ]);
  }

  Widget _grid(List<ChannelModel> list, Color accent) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.82),
      itemCount: list.length,
      itemBuilder: (_, i) => _ChannelGridCard(channel: list[i], accent: accent),
    );
  }

  Widget _rows(List<ChannelModel> list, Color accent, bool isDark) {
    // Une carte sponsorisée toutes les 5 chaînes (placement native_feed).
    final total = list.length + list.length ~/ 5;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: total,
      itemBuilder: (_, i) {
        if ((i + 1) % 6 == 0) return const AdNativeCard(screen: 'channels');
        final idx = i - (i ~/ 6);
        if (idx >= list.length) return const SizedBox.shrink();
        return _ChannelRow(channel: list[idx], accent: accent, isDark: isDark);
      },
    );
  }
}

class _Logo extends StatelessWidget {
  final ChannelModel channel;
  final double size;
  final Color accent;
  const _Logo({required this.channel, required this.size, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent,
        image: channel.logoUrl != null ? DecorationImage(image: NetworkImage(channel.logoUrl!), fit: BoxFit.cover) : null,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: channel.logoUrl == null
          ? Text(channel.name.isEmpty ? '?' : channel.name[0].toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.4))
          : null,
    );
  }
}

class _ChannelGridCard extends StatelessWidget {
  final ChannelModel channel;
  final Color accent;
  const _ChannelGridCard({required this.channel, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => openChannel(channel.id),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? Colors.white10 : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            flex: 5,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: channel.bannerUrl != null
                    ? Image.network(channel.bannerUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: accent.withValues(alpha: 0.3)))
                    : Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.5)]))),
              ),
              if (channel.isSubscribed)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Abonné', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
              Positioned(bottom: -22, left: 12, child: _Logo(channel: channel, size: 46, accent: accent)),
            ]),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  channel.plans.isEmpty ? channel.description : 'Dès ${channel.plans.map((p) => p.price).reduce((a, b) => a < b ? a : b).round()} F',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final ChannelModel channel;
  final Color accent;
  final bool isDark;
  const _ChannelRow({required this.channel, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openChannel(channel.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? Colors.white10 : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          SizedBox(
            height: 110,
            width: double.infinity,
            child: channel.bannerUrl != null
                ? Image.network(channel.bannerUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: accent.withValues(alpha: 0.3)))
                : Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.5)]))),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              _Logo(channel: channel, size: 44, accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  if (channel.description.isNotEmpty)
                    Text(channel.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                ]),
              ),
              if (channel.isSubscribed) const Icon(Icons.verified_rounded, color: Colors.green) else const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Page autonome (deep link, drawer…) listant les chaînes.
class ChannelsPage extends StatelessWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chaînes')),
      body: const SafeArea(child: ChannelsListBody()),
    );
  }
}
