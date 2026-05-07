// lib/app/modules/social/views/dating_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/data/models/dating_models.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/controllers/dating_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_room_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

extension _ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF111111) : Colors.grey.shade100;
  Color get primaryText =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      (isDark ? Colors.white : Colors.black87);
  Color get subtleText => Theme.of(this).hintColor;
  Color get surface =>
      isDark ? const Color(0xFF1E1E1E) : Colors.white;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATING VIEW — hub (préférences si pas définies, sinon swipe)
// ─────────────────────────────────────────────────────────────────────────────
class DatingView extends StatelessWidget {
  const DatingView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DatingController>();

    return Obx(() {
      if (ctrl.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: GPTheme.primaryColor),
        );
      }
      // Si pas de préférences → afficher le setup
      if (!ctrl.hasPreferences) {
        return _PreferencesSetup(ctrl: ctrl);
      }
      // Sinon → page principale dating
      return _DatingMain(ctrl: ctrl);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATING MAIN (swipe + profils likés)
// ─────────────────────────────────────────────────────────────────────────────
class _DatingMain extends StatelessWidget {
  final DatingController ctrl;
  const _DatingMain({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor:
            context.isDark ? const Color(0xFF1A1A1A) : Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'DATING',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => _showPreferencesSheet(context, ctrl),
          ),
        ],
      ),
      body: Obx(() {
        // Dialogue match
        if (ctrl.newMatch.value != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMatchDialog(context, ctrl.newMatch.value!, ctrl);
          });
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profils likés ─────────────────────────────────────────
              if (ctrl.likedProfiles.isNotEmpty ||
                  ctrl.matches.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Vous avez aimé ces profils',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LikedProfilesRow(ctrl: ctrl),
                const SizedBox(height: 20),
                Divider(color: context.isDark ? Colors.white12 : Colors.grey.shade200),
              ],

              // ── Carte swipe ───────────────────────────────────────────
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ctrl.currentProfile != null
                    ? _SwipeCard(
                        profile: ctrl.currentProfile!,
                        ctrl: ctrl,
                      )
                    : _NoMoreProfiles(ctrl: ctrl),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  void _showPreferencesSheet(BuildContext ctx, DatingController ctrl) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreferencesSheet(ctrl: ctrl),
    );
  }

  void _showMatchDialog(
      BuildContext ctx, DatingProfile profile, DatingController ctrl) {
    ctrl.newMatch.value = null;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _MatchDialog(profile: profile, ctrl: ctrl),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIKED PROFILES ROW
// ─────────────────────────────────────────────────────────────────────────────
class _LikedProfilesRow extends StatelessWidget {
  final DatingController ctrl;
  const _LikedProfilesRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final allLiked = [
      ...ctrl.matches.map((m) => m.profile),
      ...ctrl.likedProfiles,
    ];
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allLiked.length,
        itemBuilder: (_, i) {
          final p = allLiked[i];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: GPTheme.primaryColor, width: 2.5),
                    image: p.displayPhoto.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(p.displayPhoto),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: p.displayPhoto.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  p.name.split(' ').first,
                  style: TextStyle(
                      fontSize: 10,
                      color: context.primaryText,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWIPE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SwipeCard extends StatefulWidget {
  final DatingProfile profile;
  final DatingController ctrl;

  const _SwipeCard({required this.profile, required this.ctrl});

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  Offset _dragOffset = Offset.zero;
  double _rotation = 0;
  bool _swiping = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset += d.delta;
      _rotation = _dragOffset.dx / 300;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final w = MediaQuery.of(context).size.width;
    if (_dragOffset.dx > w * 0.3) {
      _swipeRight();
    } else if (_dragOffset.dx < -w * 0.3) {
      _swipeLeft();
    } else {
      // Retour
      setState(() {
        _dragOffset = Offset.zero;
        _rotation = 0;
      });
    }
  }

  Future<void> _swipeRight() async {
    setState(() => _swiping = true);
    await Future.delayed(const Duration(milliseconds: 200));
    widget.ctrl.likeProfile(widget.profile);
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
      _swiping = false;
    });
  }

  Future<void> _swipeLeft() async {
    setState(() => _swiping = true);
    await Future.delayed(const Duration(milliseconds: 200));
    widget.ctrl.skipProfile(widget.profile);
    setState(() {
      _dragOffset = Offset.zero;
      _rotation = 0;
      _swiping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final w = MediaQuery.of(context).size.width - 32;
    final h = w * 1.35;

    // Indicateurs like/nope
    final likeOpacity = (_dragOffset.dx / 150).clamp(0.0, 1.0);
    final nopeOpacity = (-_dragOffset.dx / 150).clamp(0.0, 1.0);

    return Column(
      children: [
        // ── Carte ──────────────────────────────────────────────────────────
        GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(_dragOffset.dx, _dragOffset.dy)
              ..rotateZ(_rotation),
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo
                    p.displayPhoto.isNotEmpty
                        ? Image.network(
                            p.displayPhoto,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, prog) {
                              if (prog == null) return child;
                              return Container(
                                color: Colors.grey.shade800,
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: GPTheme.primaryColor,
                                      strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade700,
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 80),
                            ),
                          )
                        : Container(color: Colors.grey.shade700),

                    // Gradient bottom
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // LIKE overlay
                    if (likeOpacity > 0)
                      Positioned(
                        top: 30,
                        left: 20,
                        child: Opacity(
                          opacity: likeOpacity,
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.green, width: 3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'LIKE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // NOPE overlay
                    if (nopeOpacity > 0)
                      Positioned(
                        top: 30,
                        right: 20,
                        child: Opacity(
                          opacity: nopeOpacity,
                          child: Transform.rotate(
                            angle: 0.3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.red, width: 3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NOPE',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Info bas de carte
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              GPTheme.primaryColor.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${p.name}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${p.age} Ans',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (p.city != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.location_on_rounded,
                                            color: Colors.white70,
                                            size: 13),
                                        const SizedBox(width: 3),
                                        Text(p.city!,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Bouton info
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Boutons d'action ───────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Skip (X)
            _ActionCircle(
              icon: Icons.close_rounded,
              color: Colors.white,
              iconColor: Colors.black87,
              size: 56,
              onTap: () => widget.ctrl.skipProfile(p),
            ),
            const SizedBox(width: 20),
            // Like (❤)
            _ActionCircle(
              icon: Icons.favorite_rounded,
              color: GPTheme.primaryColor,
              iconColor: Colors.white,
              size: 64,
              onTap: () => widget.ctrl.likeProfile(p),
            ),
            const SizedBox(width: 20),
            // Message (chat)
            _ActionCircle(
              icon: Icons.chat_rounded,
              color: Colors.white,
              iconColor: Colors.black87,
              size: 56,
              onTap: () async {
                final chatCtrl = Get.find<ChatController>();
                final convId =
                    await chatCtrl.startConversationWithUser(p.id);
                if (convId != null) {
                  final conv = PrivateConversation(
                    id: convId,
                    otherUserId: p.id,
                    otherUserName: p.name,
                    otherUserAvatar: p.avatarUrl,
                  );
                  await chatCtrl.openPrivateConversation(conv);
                  Get.to(() => ChatRoomView(privateConv: conv));
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NO MORE PROFILES
// ─────────────────────────────────────────────────────────────────────────────
class _NoMoreProfiles extends StatelessWidget {
  final DatingController ctrl;
  const _NoMoreProfiles({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 64, color: context.subtleText),
          const SizedBox(height: 16),
          Text(
            'Vous avez vu tous les profils !',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.primaryText),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez plus tard pour découvrir\nde nouveaux profils.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.subtleText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: ctrl.loadSuggestions,
            style: ElevatedButton.styleFrom(
              backgroundColor: GPTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white),
            label: const Text('Actualiser',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCH DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _MatchDialog extends StatelessWidget {
  final DatingProfile profile;
  final DatingController ctrl;

  const _MatchDialog({required this.profile, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GPTheme.primaryColor.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              "C'est un match !",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous et ${profile.name} vous êtes likés mutuellement !',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            // Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white24,
                  backgroundImage: profile.displayPhoto.isNotEmpty
                      ? NetworkImage(profile.displayPhoto)
                      : null,
                  child: profile.displayPhoto.isEmpty
                      ? const Icon(Icons.person,
                          color: Colors.white, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white24,
                  child: const Icon(Icons.person,
                      color: Colors.white, size: 40),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Boutons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Get.back();
                  final chatCtrl = Get.find<ChatController>();
                  final convId = await chatCtrl
                      .startConversationWithUser(profile.id);
                  if (convId != null) {
                    final conv = PrivateConversation(
                      id: convId,
                      otherUserId: profile.id,
                      otherUserName: profile.name,
                      otherUserAvatar: profile.avatarUrl,
                    );
                    await chatCtrl.openPrivateConversation(conv);
                    Get.to(() => ChatRoomView(privateConv: conv));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(Icons.chat_rounded,
                    color: GPTheme.primaryColor),
                label: Text(
                  'Envoyer un message',
                  style: TextStyle(
                    color: GPTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: Get.back,
              child: const Text(
                'Continuer à swiper',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREFERENCES SETUP (premier démarrage)
// ─────────────────────────────────────────────────────────────────────────────
class _PreferencesSetup extends StatelessWidget {
  final DatingController ctrl;
  const _PreferencesSetup({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded,
                color: GPTheme.primaryColor, size: 64),
            const SizedBox(height: 20),
            Text(
              'Bienvenue dans le Dating !',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dites-nous vos préférences pour trouver votre match idéal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.subtleText, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Genre recherché
            Text(
              'Je recherche',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Wrap(
                  spacing: 12,
                  children: [
                    _GenderChip(
                      label: 'Des femmes',
                      icon: Icons.female_rounded,
                      selected: ctrl.selectedLookingFor.value == 'female',
                      onTap: () => ctrl.selectedLookingFor.value = 'female',
                    ),
                    _GenderChip(
                      label: 'Des hommes',
                      icon: Icons.male_rounded,
                      selected: ctrl.selectedLookingFor.value == 'male',
                      onTap: () => ctrl.selectedLookingFor.value = 'male',
                    ),
                    _GenderChip(
                      label: 'Les deux',
                      icon: Icons.people_rounded,
                      selected: ctrl.selectedLookingFor.value == 'both',
                      onTap: () => ctrl.selectedLookingFor.value = 'both',
                    ),
                  ],
                )),

            const SizedBox(height: 32),

            // Tranche d'âge
            Text(
              'Tranche d\'âge',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => RangeSlider(
                  values: RangeValues(
                    ctrl.minAge.value.toDouble(),
                    ctrl.maxAge.value.toDouble(),
                  ),
                  min: 18,
                  max: 60,
                  divisions: 42,
                  activeColor: GPTheme.primaryColor,
                  inactiveColor:
                      GPTheme.primaryColor.withValues(alpha: 0.2),
                  labels: RangeLabels(
                    '${ctrl.minAge.value} ans',
                    '${ctrl.maxAge.value} ans',
                  ),
                  onChanged: (v) {
                    ctrl.minAge.value = v.start.round();
                    ctrl.maxAge.value = v.end.round();
                  },
                )),
            Obx(() => Text(
                  '${ctrl.minAge.value} - ${ctrl.maxAge.value} ans',
                  style: TextStyle(
                      color: context.subtleText, fontSize: 13),
                )),

            const SizedBox(height: 40),

            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ctrl.isSubmitting.value
                        ? null
                        : ctrl.savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GPTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: ctrl.isSubmitting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Commencer à découvrir',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? GPTheme.primaryColor
              : GPTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? GPTheme.primaryColor
                : GPTheme.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? Colors.white : GPTheme.primaryColor,
                size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : GPTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREFERENCES SHEET (modifier depuis le dating)
// ─────────────────────────────────────────────────────────────────────────────
class _PreferencesSheet extends StatelessWidget {
  final DatingController ctrl;
  const _PreferencesSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Mes préférences',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: context.primaryText)),
          const SizedBox(height: 20),

          Text('Je recherche',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: context.primaryText)),
          const SizedBox(height: 10),
          Obx(() => Wrap(
                spacing: 10,
                children: [
                  _GenderChip(
                    label: 'Femmes',
                    icon: Icons.female_rounded,
                    selected: ctrl.selectedLookingFor.value == 'female',
                    onTap: () => ctrl.selectedLookingFor.value = 'female',
                  ),
                  _GenderChip(
                    label: 'Hommes',
                    icon: Icons.male_rounded,
                    selected: ctrl.selectedLookingFor.value == 'male',
                    onTap: () => ctrl.selectedLookingFor.value = 'male',
                  ),
                  _GenderChip(
                    label: 'Les deux',
                    icon: Icons.people_rounded,
                    selected: ctrl.selectedLookingFor.value == 'both',
                    onTap: () => ctrl.selectedLookingFor.value = 'both',
                  ),
                ],
              )),

          const SizedBox(height: 20),
          Obx(() => RangeSlider(
                values: RangeValues(
                  ctrl.minAge.value.toDouble(),
                  ctrl.maxAge.value.toDouble(),
                ),
                min: 18,
                max: 60,
                divisions: 42,
                activeColor: GPTheme.primaryColor,
                inactiveColor:
                    GPTheme.primaryColor.withValues(alpha: 0.2),
                labels: RangeLabels(
                  '${ctrl.minAge.value} ans',
                  '${ctrl.maxAge.value} ans',
                ),
                onChanged: (v) {
                  ctrl.minAge.value = v.start.round();
                  ctrl.maxAge.value = v.end.round();
                },
              )),

          const SizedBox(height: 20),
          Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: ctrl.isSubmitting.value
                      ? null
                      : () async {
                          await ctrl.savePreferences();
                          Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GPTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Enregistrer',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              )),
        ],
      ),
    );
  }
}