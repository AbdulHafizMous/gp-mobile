import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/modules/club/views/promo_detail_view.dart';

class ClubView extends StatelessWidget {
  const ClubView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ClubController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          color: GPTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.card_giftcard_rounded,
                            color: GPTheme.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Club',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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

            // ── Liste ────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value && ctrl.promotions.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: GPTheme.primaryColor),
                  );
                }

                if (ctrl.promotions.isEmpty) {
                  return _emptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () => ctrl.fetchPromotions(refresh: true),
                  color: GPTheme.primaryColor,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: ctrl.promotions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _PromoCard(
                      promo: ctrl.promotions[i],
                      onTap: () => Get.to(() => PromoDetailView(
                            promo: ctrl.promotions[i],
                            ctrl: ctrl,
                          )),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Aucune promotion disponible',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('Revenez bientôt !',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ── Carte promo ──────────────────────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.onTap});

  final Promotion promo;
  final VoidCallback onTap;

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
                  ? GPTheme.primaryColor.withOpacity(0.3)
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