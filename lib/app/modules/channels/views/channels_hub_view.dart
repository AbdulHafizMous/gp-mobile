// Onglet « Chaînes » : TOP 10 mis en avant (2 par ligne, classé par l'admin) puis liste alphabétique complète
// (2 colonnes ou 1 colonne), barre de recherche, index A–Z. Blowmusic y apparaît avec une présentation à part.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/alpha_rail.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/channel_model.dart';
import 'package:grand_public_v2/app/modules/channels/controllers/channels_list_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class _Entry {
  final String name;
  final ChannelModel? ch; // null = Blowmusic
  const _Entry(this.name, this.ch);
  bool get blow => ch == null;
}

const _accents = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ';
const _plain = 'aaaaaceeeeiiiinooooouuuuyy';
String _fold(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final i = _accents.indexOf(ch);
    b.write(i >= 0 ? _plain[i] : ch);
  }
  return b.toString();
}

String _letterOf(String name) {
  final f = _fold(name.trim());
  for (final r in f.runes) {
    final c = String.fromCharCode(r);
    if (RegExp(r'[a-z]').hasMatch(c)) return c.toUpperCase();
    if (RegExp(r'[0-9]').hasMatch(c)) return '#';
  }
  return '#';
}

class ChannelsHubView extends StatefulWidget {
  const ChannelsHubView({super.key});
  @override
  State<ChannelsHubView> createState() => _ChannelsHubViewState();
}

class _ChannelsHubViewState extends State<ChannelsHubView> {
  static const _az = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  late final ChannelsListController c =
      Get.isRegistered<ChannelsListController>()
      ? Get.find<ChannelsListController>()
      : Get.put(ChannelsListController());
  final _sc = ScrollController();
  final _viewportKey = GlobalKey();
  final _allTitleKey = GlobalKey();
  final _rail = AlphaRailController();
  final Map<String, GlobalKey> _keys = {};
  List<String> _available = const [];

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    _sc.dispose();
    _rail.dispose();
    super.dispose();
  }

  void _open(_Entry e) {
    if (e.blow) {
      Get.toNamed('/blowmusic/home');
    } else {
      Get.toNamed('/channel/${e.ch!.id}');
    }
  }

  /// L'index n'apparaît que lorsque la liste alphabétique devient visible.
  void _onScroll() {
    if (!mounted || !_sc.hasClients) return;
    final vp = _viewportKey.currentContext?.findRenderObject();
    if (vp is! RenderBox || !vp.attached) return;
    final top = vp.localToGlobal(Offset.zero).dy;
    final h = vp.size.height;
    final tObj = _allTitleKey.currentContext?.findRenderObject();
    var show = false;
    if (tObj is RenderBox && tObj.attached) {
      show = tObj.localToGlobal(Offset.zero).dy - top < h * .5;
    }
    if (_rail.show.value != show) _rail.show.value = show;
    if (_rail.busy || _available.isEmpty) return;
    String? current;
    for (final l in _available) {
      final o = _keys[l]?.currentContext?.findRenderObject();
      if (o is! RenderBox || !o.attached) continue;
      if (o.localToGlobal(Offset.zero).dy - top <= 90) {
        current = l;
      } else {
        break;
      }
    }
    current ??= _available.first;
    final pos = _sc.position;
    if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 4)
      current = _available.last;
    if (_rail.active.value != current) _rail.active.value = current;
  }

  void _jump(String letter) {
    final ctx = _keys[letter]?.currentContext;
    if (ctx != null)
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final q = c.search.value.trim();
      final all = <_Entry>[
        if (isBlowMusicActivated &&
            (q.isEmpty || _fold('blowmusic musique live').contains(_fold(q))))
          const _Entry('Blowmusic', null),
        ...c.filtered.map((x) => _Entry(x.name, x)),
      ]..sort((a, b) => _fold(a.name).compareTo(_fold(b.name)));

      final featured =
          c.channels
              .where(
                (x) =>
                    x.featuredRank != null &&
                    x.featuredRank! >= 1 &&
                    x.featuredRank! <= 10,
              )
              .toList()
            ..sort((a, b) => a.featuredRank!.compareTo(b.featuredRank!));

      final groups = <String, List<_Entry>>{};
      for (final e in all) {
        groups.putIfAbsent(_letterOf(e.name), () => []).add(e);
      }
      final letters = groups.keys.toList()
        ..sort((a, b) => a == '#' ? 1 : (b == '#' ? -1 : a.compareTo(b)));
      for (final l in letters) {
        _keys.putIfAbsent(l, () => GlobalKey());
      }
      _available = letters;
      if (_rail.active.value.isEmpty && letters.isNotEmpty)
        _rail.active.value = letters.first;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());

      final loadingFirst = c.isLoading.value && c.channels.isEmpty;
      final errorFirst = c.hasError.value && c.channels.isEmpty;
      final ready = !loadingFirst && !errorFirst;

      return AlphaRailHost(
        ctrl: _rail,
        letters: [..._az.split(''), if (groups.containsKey('#')) '#'],
        enabled: letters.toSet(),
        onJump: _jump,
        accent: GPTheme.primaryColor,
        fg: isDark ? Colors.white : Colors.black87,
        isDark: isDark,
        enabledRail: ready && q.isEmpty,
        child: SizedBox.expand(
          key: _viewportKey,
          child: RefreshIndicator(
            color: GPTheme.primaryColor,
            onRefresh: c.load,
            child: SingleChildScrollView(
              controller: _sc,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (loadingFirst)
                    SizedBox(
                      height: 320,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: GPTheme.primaryColor,
                        ),
                      ),
                    )
                  else if (errorFirst)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 40),
                            const SizedBox(height: 8),
                            const Text('Impossible de charger les chaînes.'),
                            TextButton.icon(
                              onPressed: c.load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // ── TOP 10 (3 par ligne) ──────────────────────────────────
                    if (q.isEmpty &&
                        (featured.isNotEmpty || isBlowMusicActivated)) ...[
                      const _SectionTitle(
                        icon: Icons.local_fire_department_rounded,
                        title: 'À la une',
                        subtitle: 'Les chaînes à ne pas manquer',
                      ),
                      const SizedBox(height: 10),
                      // if (isBlowMusicActivated) ...[
                      //   _BlowCard(
                      //     onTap: () => _open(const _Entry('Blowmusic', null)),
                      //   ),
                      //   const SizedBox(height: 10),
                      // ],
                      _Top1Card(
                        ch: featured[0],
                        onTap: () =>
                            _open(_Entry(featured[0].name, featured[0])),
                      ),
                      const SizedBox(height: 10),
                      if (featured.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: featured.length - 1,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.86,
                              ),
                          itemBuilder: (_, i) => _FeaturedCard(
                            ch: featured[i + 1],
                            onTap: () => _open(
                              _Entry(featured[i + 1].name, featured[i + 1]),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                    // ── Recherche : après le top 10, avant la liste A-Z ───────
                    // (clé stable : le champ garde le focus quand le top 10 disparaît)
                    _SearchField(
                      key: const ValueKey('hub-search'),
                      onChanged: (v) => c.search.value = v,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    // ── TOUTES LES CHAÎNES (alphabétique) ─────────────────────
                    KeyedSubtree(
                      key: _allTitleKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: _SectionTitle(
                              icon: Icons.sort_by_alpha_rounded,
                              title: 'Toutes les chaînes',
                              subtitle: '${all.length} au total',
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: .05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _LayoutBtn(
                                  icon: Icons.grid_view_rounded,
                                  selected: c.isGrid.value,
                                  onTap: () =>
                                      c.isGrid.value ? null : c.toggleLayout(),
                                ),
                                _LayoutBtn(
                                  icon: Icons.view_agenda_rounded,
                                  selected: !c.isGrid.value,
                                  onTap: () =>
                                      c.isGrid.value ? c.toggleLayout() : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (all.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text('Aucune chaîne ne correspond.'),
                        ),
                      )
                    else
                      for (final l in letters)
                        Padding(
                          padding: EdgeInsets.only(right: q.isEmpty ? 24 : 0),
                          child: Column(
                            key: _keys[l],
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 14,
                                  bottom: 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: GPTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        l,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Divider(
                                        color: isDark
                                            ? Colors.white12
                                            : Colors.black12,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (c.isGrid.value)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: groups[l]!.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 1.05,
                                      ),
                                  itemBuilder: (_, i) => _GridCard(
                                    e: groups[l]![i],
                                    onTap: () => _open(groups[l]![i]),
                                  ),
                                )
                              else
                                for (final e in groups[l]!)
                                  _ListTile(e: e, onTap: () => _open(e)),
                            ],
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool isDark;
  const _SearchField({
    super.key,
    required this.onChanged,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Rechercher une chaîne',
      prefixIcon: const Icon(Icons.search_rounded),
      filled: true,
      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: .05),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: GPTheme.primaryColor, size: 22),
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _LayoutBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  const _LayoutBtn({required this.icon, required this.selected, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: selected ? GPTheme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : Theme.of(context).hintColor,
      ),
    ),
  );
}

/// Image de la chaîne (logo ou bannière) ; repli : dégradé avec les initiales.
/// En mode Top 1 : logo contenu dans une tuile arrondie translucide (54x54).
class _Cover extends StatelessWidget {
  final ChannelModel ch;
  final bool isTop1;
  const _Cover({required this.ch, this.isTop1 = false});

  @override
  Widget build(BuildContext context) {
    final url = ch.logoUrl ?? ch.bannerUrl;
    final hasUrl = url != null && url.isNotEmpty;

    if (isTop1) {
      final initials = Center(
        child: Text(
          _initials(ch.name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
      return Center(
        child: Container(
          width: 54,
          height: 54,
          padding: EdgeInsets.all(!hasUrl ? 9 : 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(16),
          ),
          child: hasUrl
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => initials,
                  errorWidget: (_, __, ___) => initials,
                )
              : initials,
        ),
      );
    }

    final hue = (ch.id * 47) % 360;
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue.toDouble(), .6, .45).toColor(),
            HSLColor.fromAHSL(
              1,
              ((hue + 40) % 360).toDouble(),
              .6,
              .35,
            ).toColor(),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(ch.name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (!hasUrl) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }

  static String _initials(String n) {
    final p = n
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (p.isEmpty) return '?';
    return (p.length == 1
            ? p[0].substring(0, p[0].length > 1 ? 2 : 1)
            : '${p[0][0]}${p[1][0]}')
        .toUpperCase();
  }
}

class _FeaturedCard extends StatelessWidget {
  final ChannelModel ch;
  final VoidCallback onTap;
  const _FeaturedCard({required this.ch, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final rank = ch.featuredRank ?? 0;
    final medal = rank == 1
        ? const Color(0xFFF5B301)
        : rank == 2
        ? const Color(0xFF9CA3AF)
        : rank == 3
        ? const Color(0xFFCD7F32)
        : Colors.black54;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Cover(ch: ch),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: medal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (ch.isSubscribed)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF34D399),
                  size: 20,
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ch.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      height: 1.15,
                    ),
                  ),
                  if (ch.isSubscribed) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Abonné(e)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Top1Card extends StatelessWidget {
  final ChannelModel ch;
  final VoidCallback onTap;
  const _Top1Card({required this.ch, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = Color(0xFFF5B301);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [c, Color.lerp(c, Colors.black, .28)!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: .35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _Cover(ch: ch, isTop1: true),
            // Container(
            //   width: 54,
            //   height: 54,
            //   padding: const EdgeInsets.all(9),
            //   decoration: BoxDecoration(
            //     color: Colors.white24,
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: Image.asset(LOGO_BLOWMUSIC, fit: BoxFit.contain),
            // ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ch.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    ch.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: c),
                  const SizedBox(width: 4),
                  Text(
                    '1',
                    style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _BlowCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BlowCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = GPTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [c, Color.lerp(c, Colors.black, .28)!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: .35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(LOGO_BLOWMUSIC, fit: BoxFit.contain),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blowmusic',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Musique, playlists et lives en direct',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors_rounded, size: 14, color: c),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final _Entry e;
  final VoidCallback onTap;
  const _GridCard({required this.e, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = e.blow ? 'Musique & live' : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0 : .07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: e.blow
                  ? Container(
                      width: double.infinity,
                      color: GPTheme.primaryColor,
                      padding: const EdgeInsets.all(22),
                      child: Image.asset(LOGO_BLOWMUSIC, fit: BoxFit.contain),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: _Cover(ch: e.ch!),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      e.ch?.isSubscribed == true ? 'Abonné(e)' : sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final _Entry e;
  final VoidCallback onTap;
  const _ListTile({required this.e, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: e.blow
                        ? Container(
                            color: GPTheme.primaryColor,
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              LOGO_BLOWMUSIC,
                              fit: BoxFit.contain,
                            ),
                          )
                        : _Cover(ch: e.ch!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        e.blow
                            ? 'Musique, playlists et lives en direct'
                            : e.ch!.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.ch?.isSubscribed == true)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF34D399),
                      size: 20,
                    ),
                  ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
