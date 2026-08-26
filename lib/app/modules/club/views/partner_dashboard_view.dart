import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_controller.dart';
import 'package:grand_public_v2/app/modules/club/views/partner_scanner_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
  Color get divider => Theme.of(this).dividerColor;
}

/// Espace partenaire (mobile) : scanner de QR codes pour valider les offres
/// + tableau de bord des statistiques (offres, scans, historique).
class PartnerDashboardView extends StatefulWidget {
  const PartnerDashboardView({super.key});

  @override
  State<PartnerDashboardView> createState() => _PartnerDashboardViewState();
}

class _PartnerDashboardViewState extends State<PartnerDashboardView> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final ctrl = Get.put(ClubController());

  @override
  void initState() {
    super.initState();
    ctrl.fetchPartnerStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        title: Text('Mon espace partenaire', style: TextStyle(color: context.primary)),
        iconTheme: IconThemeData(color: context.primary),
        bottom: TabBar(
          controller: _tab,
          labelColor: context.isDark ? GPTheme.clubColor : GPTheme.clubOnColor,
          unselectedLabelColor: context.subtle,
          indicatorColor: GPTheme.clubColor,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'Scanner'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Statistiques'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          const PartnerScannerView(),
          _StatsTab(ctrl: ctrl),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final ClubController ctrl;
  const _StatsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isPartnerStatsLoading.value && ctrl.partnerStats.value == null) {
        return Center(child: CircularProgressIndicator(color: GPTheme.clubColor));
      }
      final data = ctrl.partnerStats.value;
      if (data == null) {
        return Center(child: Text('Impossible de charger les statistiques.', style: TextStyle(color: context.subtle)));
      }
      final stats = Map<String, dynamic>.from(data['stats'] ?? {});
      final recent = (data['recent_usages'] as List?) ?? [];

      return RefreshIndicator(
        onRefresh: ctrl.fetchPartnerStats,
        color: GPTheme.clubColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _StatCard(label: 'Offres actives', value: '${stats['active_promotions'] ?? 0}', icon: Icons.local_offer_rounded),
                _StatCard(label: 'Offres au total', value: '${stats['total_promotions'] ?? 0}', icon: Icons.card_giftcard_rounded),
                _StatCard(label: 'Scans validés', value: '${stats['validated_usages'] ?? 0}', icon: Icons.check_circle_rounded, color: Colors.green),
                _StatCard(label: 'En attente', value: '${stats['pending_usages'] ?? 0}', icon: Icons.hourglass_top_rounded, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            Text('Scans récents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.primary)),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Aucun scan pour le moment.', style: TextStyle(color: context.subtle))),
              ),
            ...recent.map((u) {
              final used = u['status'] == 'used';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  border: Border.all(color: context.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: GPTheme.clubColor.withOpacity(0.12),
                      backgroundImage: u['user_avatar'] != null ? NetworkImage(u['user_avatar']) : null,
                      child: u['user_avatar'] == null ? Icon(Icons.person, size: 16, color: GPTheme.clubColor) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['user_name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: context.primary, fontSize: 13)),
                          Text(u['promotion_title'] ?? '', style: TextStyle(color: context.subtle, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: used ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(used ? 'Validé' : 'En attente',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: used ? Colors.green.shade700 : Colors.orange.shade700)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _StatCard({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? GPTheme.clubColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 20),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: context.primary)),
          Text(label, style: TextStyle(fontSize: 11, color: context.subtle)),
        ],
      ),
    );
  }
}