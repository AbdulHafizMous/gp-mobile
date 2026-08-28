import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_controller.dart';
import 'package:grand_public_v2/app/modules/club/views/club_view.dart'
    show neutralPartnerIcon;
import 'package:grand_public_v2/app/modules/club/views/promo_detail_view.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/share_helper.dart';
import 'package:url_launcher/url_launcher.dart';

extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
  Color get divider => Theme.of(this).dividerColor;
}

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
      return Scaffold(
        backgroundColor: context.bg,
        body: Center(
          child: CircularProgressIndicator(color: GPTheme.clubColor),
        ),
      );
    }
    final d = _data ?? {};
    final promotions = (d['promotions'] as List?) ?? [];
    final id = widget.partnerId;

    return Scaffold(
      backgroundColor: context.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: context.cardBg,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black),
                onPressed: () => ShareHelper.showShareSheet(
                  context,
                  title: d['company_name']?.toString() ?? 'Partenaire',
                  subtitle: d['address']?.toString(),
                  type: 'partner',
                  id: '$id',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: d['banner_url'] != null
                  ? Image.network(
                      d['banner_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _neutralHero(id),
                    )
                  : _neutralHero(id),
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
                        backgroundColor: GPTheme.clubColor.withOpacity(0.15),
                        backgroundImage: d['logo_url'] != null
                            ? NetworkImage(d['logo_url'])
                            : null,
                        child: d['logo_url'] == null
                            ? Icon(
                                neutralPartnerIcon(id),
                                color: GPTheme.clubColor,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          d['company_name']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((d['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      d['description'],
                      style: TextStyle(color: context.subtle),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if ((d['phone'] ?? '').toString().isNotEmpty)
                    _InfoRow(icon: Icons.call_outlined, text: d['phone']),
                  if ((d['address'] ?? '').toString().isNotEmpty)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: d['address'],
                    ),
                  if ((d['google_maps_link'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(d['google_maps_link']),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Voir sur la carte'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.isDark
                            ? GPTheme.clubColor
                            : GPTheme.clubOnColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Offres',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: context.isDark
                          ? GPTheme.clubColor
                          : GPTheme.clubOnColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (promotions.isEmpty)
                    Text(
                      'Aucune offre pour le moment.',
                      style: TextStyle(color: context.subtle),
                    ),
                  ...promotions.map(
                    (p) => _OfferTile(data: Map<String, dynamic>.from(p)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _neutralHero(int id) {
  return Container(
    color: GPTheme.clubColor,
    alignment: Alignment.center,
    child: Icon(
      neutralPartnerIcon(id),
      size: 56,
      color: Colors.white.withOpacity(0.35),
    ),
  );
}

class _OfferTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OfferTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final isEligible = data['is_eligible'] == true;
    final isAvailable = data['is_available'] == true;

    return GestureDetector(
      onTap: () {
        final ctrl = Get.isRegistered<ClubController>()
            ? Get.find<ClubController>()
            : Get.put(ClubController());
        Get.to(
          () => PromoDetailView(promo: Promotion.fromJson(data), ctrl: ctrl),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border.all(color: context.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.primary,
                    ),
                  ),
                  if ((data['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      data['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.subtle),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Badge(
                        label: isEligible && isAvailable
                            ? 'Éligible'
                            : 'Non éligible',
                        color: isEligible && isAvailable
                            ? Colors.green.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.2),
                        textColor: isEligible && isAvailable
                            ? Colors.green.shade700
                            : context.subtle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: context.subtle),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
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
          Icon(icon, size: 16, color: context.subtle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: context.primary)),
          ),
        ],
      ),
    );
  }
}
