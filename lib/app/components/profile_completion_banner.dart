// Bannière simple « Complétez votre profil » : visible tant que le profil
// est incomplet, dans tous les modules. Un tap ouvre le bottom sheet.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/profile_completion_service.dart';

class ProfileCompletionBanner extends StatefulWidget {
  final Color color;

  /// Si renseigné : à l'entrée dans ce module, le bottom sheet de complétion
  /// est proposé (une fois par visite) tant que le profil est incomplet.
  final String? module;
  const ProfileCompletionBanner({super.key, this.color = const Color(0xFFF59E0B), this.module});

  @override
  State<ProfileCompletionBanner> createState() => _ProfileCompletionBannerState();
}

class _ProfileCompletionBannerState extends State<ProfileCompletionBanner> {
  static const int _totalFields = 5;
  Worker? _worker;

  Color get color => widget.color;

  @override
  void initState() {
    super.initState();
    if (widget.module != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
      // L'utilisateur peut être chargé après l'ouverture du module.
      _worker = ever(activeUser, (_) => _prompt());
    }
  }

  void _prompt() {
    if (!mounted || !Get.isRegistered<ProfileCompletionService>()) return;
    ProfileCompletionService.to.promptIfNeeded(widget.module!);
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final u = activeUser.value;
      if (!u.needsProfileCompletion) return const SizedBox.shrink();
      final done = (_totalFields - u.profileMissingFields.length).clamp(0, _totalFields);
      final progress = done / _totalFields;
      return Material(
        color: color.withValues(alpha: 0.14),
        child: InkWell(
          onTap: () {
            if (Get.isRegistered<ProfileCompletionService>()) {
              ProfileCompletionService.to.openSheet();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(children: [
              SizedBox(
                width: 30,
                height: 30,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.25),
                  ),
                  Icon(Icons.person_outline_rounded, size: 15, color: color),
                ]),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Complétez votre profil pour profiter de tout',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Text('${(progress * 100).round()}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: color),
            ]),
          ),
        ),
      );
    });
  }
}
