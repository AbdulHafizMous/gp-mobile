// lib/app/components/crush_quota_banner.dart
//
// Petit indicateur "X messages restants aujourd'hui" affiché en haut d'une
// conversation Crush. Complètement invisible tant que
// CrushQuotaService.isEnabled est false (comportement actuel inchangé).

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/crush_quota_service.dart';
import 'package:grand_public_v2/app/utils/crush_paywall_helper.dart';

class CrushQuotaBanner extends StatelessWidget {
  const CrushQuotaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final quota = CrushQuotaService.to.status.value;
      if (!quota.enabled) return const SizedBox.shrink();

      final exhausted = quota.remainingToday <= 0;
      final label = exhausted
          ? (quota.bonusCredits > 0
              ? '${quota.bonusCredits} messages bonus restants'
              : 'Quota quotidien atteint')
          : '${quota.remainingToday}/${quota.dailyLimit} messages restants aujourd\'hui';

      return InkWell(
        onTap: () => showCrushPacksSheet(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: exhausted ? Colors.red.withOpacity(0.08) : Colors.amber.withOpacity(0.10),
          child: Row(
            children: [
              Icon(
                exhausted ? Icons.lock_clock_rounded : Icons.chat_bubble_outline_rounded,
                size: 14,
                color: exhausted ? Colors.red.shade400 : Colors.amber.shade800,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: exhausted ? Colors.red.shade400 : Colors.amber.shade900,
                  ),
                ),
              ),
              Text(
                'Recharger',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: exhausted ? Colors.red.shade400 : Colors.amber.shade900,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
