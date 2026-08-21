import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/share_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fiche détaillée d'un partenaire — accessible depuis l'onglet
/// "Partenaires" du Club (mapping des partenaires).
class PartnerDetailView extends StatefulWidget {
  final int partnerId;
  const PartnerDetailView({super.key, required this.partnerId});

  @override
  State<PartnerDetailView> createState() => _PartnerDetailViewState();
}

class _PartnerDetailViewState extends State<PartnerDetailView> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
      } else {
        final res = await RequestService().get('/partners/${widget.partnerId}');
        if (res.statusCode == 200) {
          _data = Map<String, dynamic>.from(res.data['data']);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final d = _data ?? {};
    final promotions = (d['promotions'] as List?) ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => ShareHelper.showShareSheet(
                  context,
                  title: d['company_name']?.toString() ?? 'Partenaire',
                  subtitle: d['address']?.toString(),
                  path: '/club/partenaire/${widget.partnerId}',
                  type: 'partner',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: d['banner_url'] != null
                  ? Image.network(d['banner_url'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: GPTheme.primaryColor))
                  : Container(color: GPTheme.primaryColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: GPTheme.primaryColor.withOpacity(0.15),
                        backgroundImage:
                            d['logo_url'] != null ? NetworkImage(d['logo_url']) : null,
                        child: d['logo_url'] == null
                            ? Icon(Icons.store_rounded, color: GPTheme.primaryColor)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          d['company_name']?.toString() ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (d['description'] != null) ...[
                    const SizedBox(height: 12),
                    Text(d['description'], style: TextStyle(color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 16),
                  if (d['phone'] != null)
                    _InfoRow(icon: Icons.call_outlined, text: d['phone']),
                  if (d['address'] != null)
                    _InfoRow(icon: Icons.location_on_outlined, text: d['address']),
                  if (d['google_maps_link'] != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(d['google_maps_link']),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Voir sur la carte'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Offres actives',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: GPTheme.primaryColor)),
                  const SizedBox(height: 10),
                  if (promotions.isEmpty)
                    Text('Aucune offre active pour le moment.',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ...promotions.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(p['description'] ?? '',
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700))),
        ],
      ),
    );
  }
}
