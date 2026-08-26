import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/modules/club/views/promo_detail_view.dart';
import 'package:grand_public_v2/app/modules/club/views/partner_detail_view.dart';
import 'package:grand_public_v2/app/modules/club/views/partner_dashboard_view.dart';
import 'package:grand_public_v2/app/utils/share_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS (mêmes conventions que Chat / Bizz)
// ─────────────────────────────────────────────────────────────────────────────
extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  // Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get inputBg => isDark ? Colors.white10 : Colors.grey.shade100;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
  Color get divider => Theme.of(this).dividerColor;
}

class ClubView extends StatelessWidget {
  const ClubView({super.key});

  void _showClubSettings(BuildContext context, ClubController ctrl) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Paramètres du Club',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: context.primary)),
            const SizedBox(height: 16),
            Obx(() => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: GPTheme.clubColor,
                  title: Text('Rappels d\'offres', style: TextStyle(color: context.primary, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Recevoir une notification à l\'ouverture de l\'app s\'il y a des offres disponibles pour vous.',
                    style: TextStyle(color: context.subtle, fontSize: 12),
                  ),
                  value: ctrl.remindersEnabled.value,
                  onChanged: ctrl.isTogglingReminders.value ? null : ctrl.toggleReminders,
                )),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ClubController());

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GPTheme.clubColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.card_giftcard_outlined,
                            color: GPTheme.clubColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Club',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (ctrl.isPartner)
                        IconButton(
                          tooltip: 'Mon espace partenaire',
                          icon: Icon(Icons.qr_code_scanner_rounded, color: context.subtle),
                          onPressed: () => Get.to(() => const PartnerDashboardView()),
                        ),
                      IconButton(
                        tooltip: 'Paramètres du Club',
                        icon: Icon(Icons.tune_rounded, color: context.subtle),
                        onPressed: () => _showClubSettings(context, ctrl),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profitez de promotions exclusives chez nos partenaires',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // ── Tabs Offres / Partenaires ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Row(
                  children: [
                    _ClubTabChip(
                      label: 'Offres',
                      icon: Icons.local_offer_outlined,
                      active: ctrl.clubTab.value == 0,
                      onTap: () => ctrl.clubTab.value = 0,
                    ),
                    const SizedBox(width: 8),
                    _ClubTabChip(
                      label: 'Partenaires',
                      icon: Icons.storefront_outlined,
                      active: ctrl.clubTab.value == 1,
                      onTap: () => ctrl.clubTab.value = 1,
                    ),
                  ],
                ),
              ),
            ),

            // ── Recherche ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: ctrl.searchCtrl,
                onChanged: ctrl.onSearchChanged,
                style: TextStyle(color: context.primary, fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Rechercher un partenaire, un mot-clé, une adresse…',
                  hintStyle: TextStyle(fontSize: 13, color: context.subtle),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.subtle),
                  filled: true,
                  fillColor: context.inputBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Contenu ──────────────────────────────────────────────────
            Expanded(
              child: Obx(
                () => ctrl.clubTab.value == 0
                    ? _OffresTab(ctrl: ctrl)
                    : _PartenairesTab(ctrl: ctrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubTabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ClubTabChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? GPTheme.clubColor : context.inputBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15, color: active ? GPTheme.clubOnColor : context.subtle),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? GPTheme.clubOnColor : context.subtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet OFFRES ──────────────────────────────────────────────────────────
class _OffresTab extends StatelessWidget {
  final ClubController ctrl;
  const _OffresTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.promotions.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: GPTheme.clubColor),
        );
      }

      if (ctrl.promotions.isEmpty) {
        return _emptyState(
          icon: Icons.local_offer_outlined,
          title: 'Aucune promotion disponible',
          subtitle: 'Revenez bientôt ou changez votre recherche !',
        );
      }

      return RefreshIndicator(
        onRefresh: () => ctrl.fetchPromotions(refresh: true),
        color: GPTheme.clubColor,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: ctrl.promotions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _PromoCard(
            promo: ctrl.promotions[i],
            onTap: () => Get.to(() => PromoDetailView(
                  promo: ctrl.promotions[i],
                  ctrl: ctrl,
                )),
            onShare: () => ShareHelper.showShareSheet(
              context,
              title: ctrl.promotions[i].title,
              subtitle: ctrl.promotions[i].partner?.name,
              type: 'promotion',
              id: '${ctrl.promotions[i].id}',
            ),
          ),
        ),
      );
    });
  }
}

// ── Onglet PARTENAIRES ──────────────────────────────────────────────────────
class _PartenairesTab extends StatelessWidget {
  final ClubController ctrl;
  const _PartenairesTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isPartnersLoading.value && ctrl.partners.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: GPTheme.clubColor),
        );
      }

      if (ctrl.partners.isEmpty) {
        return _emptyState(
          icon: Icons.storefront_outlined,
          title: 'Aucun partenaire trouvé',
          subtitle: 'Essayez une autre recherche.',
        );
      }

      return RefreshIndicator(
        onRefresh: ctrl.fetchPartners,
        color: GPTheme.clubColor,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: ctrl.partners.length,
          itemBuilder: (_, i) {
            final p = ctrl.partners[i];
            return _PartnerCard(
              partner: p,
              onTap: () => Get.to(() => PartnerDetailView(partnerId: p.id)),
            );
          },
        ),
      );
    });
  }
}

// ── Icônes neutres pour les partenaires sans logo/bannière ──────────────────
// Choisies de façon stable (basée sur l'id) pour qu'un même partenaire garde
// toujours la même icône entre deux rafraîchissements.
const List<IconData> _kNeutralPartnerIcons = [
  Icons.storefront_rounded,
  Icons.restaurant_rounded,
  Icons.local_cafe_rounded,
  Icons.shopping_bag_rounded,
  Icons.spa_rounded,
  Icons.local_mall_rounded,
  Icons.celebration_rounded,
  Icons.icecream_rounded,
];

IconData neutralPartnerIcon(int id) =>
    _kNeutralPartnerIcons[id % _kNeutralPartnerIcons.length];

class _PartnerCard extends StatelessWidget {
  final PartnerFiche partner;
  final VoidCallback onTap;
  const _PartnerCard({required this.partner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: partner.bannerUrl != null
                    ? Image.network(partner.bannerUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _neutralBanner(partner.id))
                    : _neutralBanner(partner.id),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: GPTheme.clubColor.withOpacity(0.15),
                        backgroundImage: partner.logoUrl != null
                            ? NetworkImage(partner.logoUrl!)
                            : null,
                        child: partner.logoUrl == null
                            ? Icon(neutralPartnerIcon(partner.id), size: 14, color: GPTheme.clubColor)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(partner.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                  if (partner.address != null) ...[
                    const SizedBox(height: 6),
                    Text(partner.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                  if ((partner.activeOffersCount ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${partner.activeOffersCount} offre(s) active(s)',
                          style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
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

Widget _neutralBanner(int id) {
  return Container(
    color: GPTheme.clubColor.withOpacity(0.1),
    alignment: Alignment.center,
    child: Icon(neutralPartnerIcon(id), size: 28, color: GPTheme.clubColor.withOpacity(0.4)),
  );
}

Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );
}

// ── Carte promo ──────────────────────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.onTap, this.onShare});

  final Promotion promo;
  final VoidCallback onTap;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: promo.isExpired ? null : onTap,
      child: Opacity(
        opacity: promo.isExpired ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: promo.userPendingQr != null
                  ? GPTheme.clubColor.withOpacity(0.3)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image ou gradient
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: promo.imageUrl != null
                      ? Image.network(promo.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gradientPlaceholder())
                      : _gradientPlaceholder(),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges
                    Row(
                      children: [
                        _Badge(label: _typeLabel(promo.type), color: _typeColor(promo.type)),
                        const SizedBox(width: 6),
                        _Badge(label: _targetLabel(promo.target), color: Colors.grey.shade200),
                        if (promo.userPendingQr != null) ...[
                          const SizedBox(width: 6),
                          _Badge(label: 'QR actif', color: Colors.green.shade50,
                              textColor: Colors.green.shade700),
                        ],
                        if (promo.isExpired) ...[
                          const SizedBox(width: 6),
                          _Badge(label: 'Expirée', color: Colors.grey.shade100,
                              textColor: Colors.grey.shade500),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(promo.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(promo.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 10),

                    // Footer
                    Row(
                      children: [
                        Icon(Icons.store_outlined, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(promo.partner?.name ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        const Spacer(),
                        Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(_formatDate(promo.endsAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        if (onShare != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onShare,
                            child: Icon(Icons.share_outlined, size: 16, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _typeColor(promo.type).withOpacity(0.3),
            _typeColor(promo.type).withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _typeIcon(promo.type),
          size: 48,
          color: _typeColor(promo.type).withOpacity(0.5),
        ),
      ),
    );
  }

  String _typeLabel(String t) =>
      {'discount': 'Réduction', 'gift': 'Cadeau', 'access': 'Accès', 'other': 'Offre'}[t] ?? t;

  String _targetLabel(String t) =>
      {'all': 'Tous', 'active': 'Actifs', 'premium': 'Premium'}[t] ?? t;

  Color _typeColor(String t) {
    return switch (t) {
      'discount' => Colors.orange,
      'gift'     => Colors.pink,
      'access'   => Colors.purple,
      _          => Colors.blue,
    };
  }

  IconData _typeIcon(String t) {
    return switch (t) {
      'discount' => Icons.percent_rounded,
      'gift'     => Icons.card_giftcard_rounded,
      'access'   => Icons.vpn_key_outlined,
      _          => Icons.local_offer_outlined,
    };
  }

  String _formatDate(String v) {
    try {
      final d = DateTime.parse(v);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return v;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.textColor});
  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.grey.shade700)),
    );
  }
}