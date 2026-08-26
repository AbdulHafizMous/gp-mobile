import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PromoDetailView extends StatelessWidget {
  const PromoDetailView({super.key, required this.promo, required this.ctrl});

  final Promotion promo;
  final ClubController ctrl;

  @override
  Widget build(BuildContext context) {
    // Trouve la promo dans la liste pour l'avoir réactive
    return Obx(() {
      final current = ctrl.promotions.firstWhere(
        (p) => p.id == promo.id,
        orElse: () => promo,
      );

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(current.title, style: const TextStyle(fontSize: 16)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          iconTheme: IconThemeData(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──────────────────────────────────────────────────
              if (current.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    current.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 16),

              // ── Infos ──────────────────────────────────────────────────
              Text(
                current.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // ── Détails ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  // color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      'Partenaire',
                      current.partner?.name ?? '—',
                      Icons.store_outlined,
                    ),
                    _InfoRow(
                      'Validité',
                      '${_fmtDate(current.startsAt)} → ${_fmtDate(current.endsAt)}',
                      Icons.calendar_today_outlined,
                    ),
                    _InfoRow(
                      'Cible',
                      _targetLabel(current.target),
                      Icons.people_outline,
                    ),
                    _InfoRow(
                      'Max / utilisateur',
                      '${current.maxUsesPerUser} fois',
                      Icons.repeat_outlined,
                    ),
                    if (current.totalMaxUses != null)
                      _InfoRow(
                        'Quota total',
                        '${current.usedCount} / ${current.totalMaxUses}',
                        Icons.bar_chart_outlined,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── QR Code si déjà généré ─────────────────────────────────
              if (current.userPendingUsage != null) ...[
                _QrSection(usage: current.userPendingUsage!),
                const SizedBox(height: 16),
              ],

              // ── Bouton Générer QR ──────────────────────────────────────
              if (current.isAvailable) ...[
                if (current.userCanClaim)
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: ctrl.isClaiming.value
                            ? null
                            : () => _onClaim(context, current),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GPTheme.clubColor,
                          foregroundColor: GPTheme.clubOnColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: ctrl.isClaiming.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code_2_rounded),
                        label: Text(
                          ctrl.isClaiming.value
                              ? 'Génération...'
                              : 'Générer mon code QR',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                else if (current.userPendingUsage == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vous avez utilisé toutes vos chances pour cette promotion.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else if (current.isExpired)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_clock_outlined, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Cette promotion est expirée.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _onClaim(BuildContext context, Promotion current) async {
    final usage = await ctrl.claimPromotion(current);
    if (usage != null && context.mounted) {
      _showQrDialog(context, usage);
    }
  }

  void _showQrDialog(BuildContext context, PromotionUsage usage) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Votre code QR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Présentez ce code au partenaire',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 20),
              QrImageView(data: usage.qrCode, size: 200),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: usage.qrCode));
                  Get.snackbar(
                    'Copié !',
                    usage.qrCode,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  // decoration: BoxDecoration(
                  //   color: Colors.grey.shade100,
                  //   borderRadius: BorderRadius.circular(8),
                  // ),
                  child: Text(
                    usage.qrCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GPTheme.clubColor,
                    foregroundColor: GPTheme.clubOnColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(String v) {
    try {
      final d = DateTime.parse(v);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return v;
    }
  }

  String _targetLabel(String t) =>
      {'all': 'Tous', 'active': 'Actifs', 'premium': 'Premium'}[t] ?? t;
}

// ── Widget QR actif ──────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  const _QrSection({required this.usage});
  final PromotionUsage usage;

  @override
  Widget build(BuildContext context) {
    final isUsed = usage.status == 'used';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUsed
            ? Colors.green.shade50
            : GPTheme.clubColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUsed
              ? Colors.green.shade200
              : GPTheme.clubColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isUsed ? Icons.check_circle_rounded : Icons.qr_code_2_rounded,
                color: isUsed
                    ? Colors.green
                    : (Theme.of(context).brightness == Brightness.dark
                        ? GPTheme.clubColor
                        : GPTheme.clubOnColor),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isUsed ? 'Code déjà utilisé' : 'Votre code QR actif',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUsed
                      ? Colors.green.shade700
                      : (Theme.of(context).brightness == Brightness.dark
                          ? GPTheme.clubColor
                          : GPTheme.clubOnColor),
                ),
              ),
            ],
          ),
          if (!isUsed) ...[
            const SizedBox(height: 16),
            QrImageView(
              data: usage.qrCode,
              size: 160,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              usage.qrCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (isUsed && usage.validatorName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Validé par ${usage.validatorName}',
              style: TextStyle(fontSize: 12, color: Colors.green.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            '$label :',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}