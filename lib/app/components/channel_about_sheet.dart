import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/data/models/channel_model.dart';

/// Fiche d'identité d'un média : logo, type, fréquence, ville, informations et site officiel.
void showChannelAbout(BuildContext context, ChannelModel ch) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final subtle = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65);
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 12, 20, 28), children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ch.logoUrl != null
                      ? Image.network(ch.logoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _Mono(ch.name))
                      : _Mono(ch.name),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ch.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    Text([ch.kindLabel, if ((ch.frequency ?? '').isNotEmpty) ch.frequency!, if ((ch.city ?? '').isNotEmpty) ch.city!].join(' · '), style: TextStyle(color: subtle, fontSize: 13)),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            if (ch.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(ch.description, style: const TextStyle(height: 1.45)),
            ],
            if (ch.info.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Informations', style: TextStyle(color: subtle, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: .6)),
              const SizedBox(height: 6),
              for (final r in ch.info)
                InkWell(
                  onTap: null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 120, child: Text(r.label, style: TextStyle(color: subtle, fontSize: 13))),
                      Expanded(
                        child: Text(r.value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ]),
                  ),
                ),
            ],
          ]),
        ),
      );
    },
  );
}

class _Mono extends StatelessWidget {
  final String name;
  const _Mono(this.name);
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF1F2937),
        alignment: Alignment.center,
        child: Text(name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
      );
}
