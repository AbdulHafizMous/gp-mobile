import 'package:flutter/material.dart';
// import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/app_link_router.dart';

final RegExp _gpLink = RegExp(r'https?://(?:www\.)?grandpublic\.bj/m/([a-z_]+)/([^\s/?#]+)', caseSensitive: false);

/// Carte d'aperçu (image, type, titre, description) pour un lien Grandpublic contenu dans [text].
/// Retourne un widget vide si aucun lien de l'app n'est présent.
class LinkPreviewCard extends StatefulWidget {
  final String text;
  final bool isMe;
  const LinkPreviewCard({super.key, required this.text, this.isMe = false});

  static bool hasLink(String t) => _gpLink.hasMatch(t);

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  static final Map<String, Map<String, dynamic>?> _cache = {};
  Map<String, dynamic>? _data;
  late final String _type, _id;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final m = _gpLink.firstMatch(widget.text);
    _type = m?.group(1) ?? '';
    _id = m?.group(2) ?? '';
    _load();
  }

  Future<void> _load() async {
    final key = '$_type/$_id';
    if (_cache.containsKey(key)) {
      _data = _cache[key];
      _loading = false;
      return;
    }
    try {
      final r = await RequestService().get('/share/preview/$_type/$_id');
      if (r.statusCode == 200) {
        _data = Map<String, dynamic>.from(r.data['data'] as Map);
        if (_data!['found'] != true) _data = null;
      }
    } catch (_) {}
    _cache[key] = _data;
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_type.isEmpty) return const SizedBox.shrink();
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final d = _data;
    if (d == null) return const SizedBox.shrink();
    final img = (d['image'] ?? '').toString();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => AppLinkRouter.route(_type, id: _id),
      child: Container(
        width: 250,
        margin: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? Colors.black26 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GPTheme.primaryColor.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (img.isNotEmpty)
            Image.network(img, height: 120, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((d['label'] ?? 'Grandpublic').toString().toUpperCase(),
                  style: TextStyle(color: GPTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8)),
              const SizedBox(height: 3),
              Text((d['title'] ?? '').toString(),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w800, fontSize: 13)),
              if ((d['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(d['description'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11.5)),
              ],
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.open_in_new_rounded, size: 13, color: GPTheme.primaryColor),
                const SizedBox(width: 4),
                Text('Ouvrir', style: TextStyle(color: GPTheme.primaryColor, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
