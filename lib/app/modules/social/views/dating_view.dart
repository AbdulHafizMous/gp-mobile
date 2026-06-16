// lib/app/modules/social/views/dating_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/data/models/dating_models.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/modules/social/controllers/chat_controller.dart';
import 'package:grand_public_v2/app/modules/social/controllers/dating_controller.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_room_view.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.grey.shade100;
  Color get surface => isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATING VIEW — hub
// ─────────────────────────────────────────────────────────────────────────────
class DatingView extends StatefulWidget {
  const DatingView({super.key});

  @override
  State<DatingView> createState() => _DatingViewState();
}

class _DatingViewState extends State<DatingView>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _ctrl = Get.find<DatingController>();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_ctrl.isLoading.value && _ctrl.suggestions.isEmpty) {
        return Scaffold(
          backgroundColor: context.bg,
          body: Center(
            child: CircularProgressIndicator(color: GPTheme.primaryColor),
          ),
        );
      }

      // Setup préférences si pas encore configurées
      if (!_ctrl.hasPreferences) {
        return _PreferencesSetup(ctrl: _ctrl);
      }

      return Scaffold(
        backgroundColor: context.bg,
        appBar: _DatingAppBar(ctrl: _ctrl, tabCtrl: _tab),
        body: TabBarView(
          controller: _tab,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _SwipeTab(ctrl: _ctrl),
            _MatchesTab(ctrl: _ctrl),
            _LikesTab(ctrl: _ctrl),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR DATING
// ─────────────────────────────────────────────────────────────────────────────
class _DatingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DatingController ctrl;
  final TabController tabCtrl;

  const _DatingAppBar({required this.ctrl, required this.tabCtrl});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      color: isDark
          ? const Color(0xFF111111)
          : GPTheme.primaryColor.withOpacity(0.9),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
              child: Row(
                children: [
                  const Text(
                    'Dating',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showPrefsSheet(context, ctrl),
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                    tooltip: 'Préférences',
                  ),
                ],
              ),
            ),
            TabBar(
              controller: tabCtrl,
              indicatorColor: GPTheme.primaryColor,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.explore_rounded, size: 15),
                      SizedBox(width: 5),
                      Text('Découvrir'),
                    ],
                  ),
                ),
                Tab(
                  child: Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded, size: 15),
                        const SizedBox(width: 5),
                        const Text('Matches'),
                        if (ctrl.matches.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: GPTheme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${ctrl.matches.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.thumb_up_rounded, size: 15),
                      SizedBox(width: 5),
                      Text('Likés'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showPrefsSheet(BuildContext context, DatingController ctrl) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PreferencesSheet(ctrl: ctrl),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET SWIPE
// ─────────────────────────────────────────────────────────────────────────────
class _SwipeTab extends StatelessWidget {
  final DatingController ctrl;
  const _SwipeTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = ctrl.currentProfile;

      if (ctrl.suggestions.isEmpty) {
        return _EmptySuggestions(ctrl: ctrl);
      }

      return Stack(
        children: [
          // Stack de cartes (on affiche jusqu'à 2 cartes derrière)
          if (ctrl.currentIndex.value + 2 < ctrl.suggestions.length)
            Positioned.fill(
              child: _ProfileCard(
                profile: ctrl.suggestions[ctrl.currentIndex.value + 2],
                scale: 0.90,
                offset: 20,
                interactive: false,
              ),
            ),
          if (ctrl.currentIndex.value + 1 < ctrl.suggestions.length)
            Positioned.fill(
              child: _ProfileCard(
                profile: ctrl.suggestions[ctrl.currentIndex.value + 1],
                scale: 0.95,
                offset: 10,
                interactive: false,
              ),
            ),
          // Carte principale (draggable)
          if (profile != null)
            Positioned.fill(
              child: _DraggableCard(profile: profile, ctrl: ctrl),
            ),
          // Overlay "C'est un Match !"
          if (ctrl.newMatch.value != null)
            _MatchOverlay(profile: ctrl.newMatch.value!, ctrl: ctrl),
        ],
      );
    });
  }
}

class _EmptySuggestions extends StatelessWidget {
  final DatingController ctrl;
  const _EmptySuggestions({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: GPTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_rounded,
                size: 48,
                color: GPTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Plus de suggestions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: context.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Vous avez vu tous les profils disponibles.\nRevenez plus tard !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.subtle,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: ctrl.loadSuggestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: GPTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Rafraîchir',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAGGABLE SWIPE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DraggableCard extends StatefulWidget {
  final DatingProfile profile;
  final DatingController ctrl;
  const _DraggableCard({required this.profile, required this.ctrl});

  @override
  State<_DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<_DraggableCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  double _rotation = 0;
  bool isDragging = false;
  late AnimationController _snapBack;
  late Animation<Offset> _snapAnim;

  static const double _threshold = 100.0;

  @override
  void initState() {
    super.initState();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _snapBack, curve: Curves.elasticOut));
    _snapBack.addListener(() {
      setState(() => _dragOffset = _snapAnim.value);
    });
  }

  @override
  void dispose() {
    _snapBack.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) {
    _snapBack.stop();
    setState(() => isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset += d.delta;
      _rotation = _dragOffset.dx / 300;
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => isDragging = false);
    if (_dragOffset.dx > _threshold) {
      _doLike();
    } else if (_dragOffset.dx < -_threshold) {
      _doSkip();
    } else {
      // Snap back
      _snapAnim = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _snapBack, curve: Curves.elasticOut));
      _snapBack.forward(from: 0);
      setState(() {
        _rotation = 0;
      });
    }
  }

  void _doLike() => widget.ctrl.likeProfile(widget.profile);
  void _doSkip() => widget.ctrl.skipProfile(widget.profile);

  @override
  Widget build(BuildContext context) {
    final likeOpacity = (_dragOffset.dx / _threshold).clamp(0.0, 1.0);
    final skipOpacity = (-_dragOffset.dx / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _rotation * 0.3,
          child: Stack(
            children: [
              _ProfileCard(
                profile: widget.profile,
                scale: 1.0,
                offset: 0,
                interactive: true,
              ),
              // LIKE badge
              if (likeOpacity > 0.05)
                Positioned(
                  top: 60,
                  left: 24,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Opacity(
                      opacity: likeOpacity.clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LIKE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // SKIP badge
              if (skipOpacity > 0.05)
                Positioned(
                  top: 60,
                  right: 24,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Opacity(
                      opacity: skipOpacity.clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NOPE',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final DatingProfile profile;
  final double scale;
  final double offset;
  final bool interactive;

  const _ProfileCard({
    required this.profile,
    required this.scale,
    required this.offset,
    required this.interactive,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Transform.translate(
        offset: Offset(0, offset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
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
                  _ProfilePhoto(url: profile.displayPhoto),
                  // Gradient bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.45, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Infos
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                '${profile.name}, ${profile.age}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (interactive)
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (profile.city != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white60,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                profile.city!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              if (profile.distance != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${profile.distance!.toStringAsFixed(0)} km',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (profile.bio?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            profile.bio!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (profile.interests.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: profile.interests
                                .take(4)
                                .map(
                                  (i) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white30),
                                    ),
                                    child: Text(
                                      i,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        // Boutons action (seulement carte active)
                        if (interactive) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ActionBtn(
                                icon: Icons.close_rounded,
                                color: Colors.red,
                                size: 56,
                                onTap: () {
                                  final p = Get.find<DatingController>()
                                      .currentProfile;
                                  if (p != null)
                                    Get.find<DatingController>().skipProfile(p);
                                },
                              ),
                              const SizedBox(width: 32),
                              _ActionBtn(
                                icon: Icons.favorite_rounded,
                                color: GPTheme.primaryColor,
                                size: 64,
                                onTap: () {
                                  final p = Get.find<DatingController>()
                                      .currentProfile;
                                  if (p != null)
                                    Get.find<DatingController>().likeProfile(p);
                                },
                              ),
                              const SizedBox(width: 32),
                              _ActionBtn(
                                icon: Icons.star_rounded,
                                color: Colors.amber,
                                size: 56,
                                onTap: () {
                                  // Super like
                                  final p = Get.find<DatingController>()
                                      .currentProfile;
                                  if (p != null)
                                    Get.find<DatingController>().likeProfile(p);
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
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
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.48),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final String url;
  const _ProfilePhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey.shade800,
        child: const Icon(
          Icons.person_rounded,
          size: 80,
          color: Colors.white24,
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade800,
        child: const Icon(
          Icons.person_rounded,
          size: 80,
          color: Colors.white24,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCH OVERLAY
// ─────────────────────────────────────────────────────────────────────────────
class _MatchOverlay extends StatelessWidget {
  final DatingProfile profile;
  final DatingController ctrl;
  const _MatchOverlay({required this.profile, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ❤️
              Icon(
                Icons.favorite_rounded,
                size: 60,
                color: GPTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                'C\'est un Match !',
                style: TextStyle(
                  color: GPTheme.primaryColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous et ${profile.name} vous vous êtes likés mutuellement !',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // Photos en miroir
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MatchAvatar(url: null, isMe: true),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: _MatchAvatar(url: profile.displayPhoto),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              // CTA Message
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ctrl.dismissMatch();
                    // Ouvrir la conv existante ou en créer une
                    final chatCtrl = Get.find<ChatController>();
                    final convId = await chatCtrl.startConversationWithUser(
                      profile.id,
                    );
                    if (convId != null) {
                      final convs = chatCtrl.privateConversations;
                      final conv = convs.firstWhereOrNull(
                        (c) => c.id == convId,
                      );
                      if (conv != null) {
                        await chatCtrl.openPrivateConversation(conv);
                        Get.to(
                          () => ChatRoomView(privateConv: conv),
                          transition: Transition.fade,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GPTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Envoyer un message à ${profile.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: ctrl.dismissMatch,
                child: const Text(
                  'Continuer à swiper',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  final String? url;
  final bool isMe;
  const _MatchAvatar({this.url, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: GPTheme.primaryColor, width: 3),
        color: isMe
            ? GPTheme.primaryColor.withOpacity(0.2)
            : Colors.grey.shade800,
        image: url != null && url!.isNotEmpty
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
      ),
      child: (url == null || url!.isEmpty)
          ? Icon(
              Icons.person_rounded,
              size: 40,
              color: isMe ? GPTheme.primaryColor : Colors.white38,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET MATCHES
// ─────────────────────────────────────────────────────────────────────────────
class _MatchesTab extends StatelessWidget {
  final DatingController ctrl;
  const _MatchesTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.matches.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 56,
                  color: context.subtle,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun match pour l\'instant',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continuez à swiper pour trouver votre match !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.subtle,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: ctrl.matches.length,
        itemBuilder: (_, i) {
          final match = ctrl.matches[i];
          return _MatchTile(
            match: match,
            onMessage: () async {
              final chatCtrl = Get.find<ChatController>();
              if (match.conversationId != null) {
                final conv = chatCtrl.privateConversations.firstWhereOrNull(
                  (c) => c.id == match.conversationId,
                );
                if (conv != null) {
                  await chatCtrl.openPrivateConversation(conv);
                  Get.to(
                    () => ChatRoomView(privateConv: conv),
                    transition: Transition.rightToLeft,
                  );
                  return;
                }
              }
              final convId = await chatCtrl.startConversationWithUser(
                match.profile.id,
              );
              if (convId != null) {
                final conv = chatCtrl.privateConversations.firstWhereOrNull(
                  (c) => c.id == convId,
                );
                if (conv != null) {
                  await chatCtrl.openPrivateConversation(conv);
                  Get.to(
                    () => ChatRoomView(privateConv: conv),
                    transition: Transition.rightToLeft,
                  );
                }
              }
            },
          );
        },
      );
    });
  }
}

class _MatchTile extends StatelessWidget {
  final DatingMatch match;
  final VoidCallback onMessage;
  const _MatchTile({required this.match, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? GPTheme.primaryColor.withOpacity(0.15)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: match.profile.displayPhoto.isNotEmpty
                    ? NetworkImage(match.profile.displayPhoto)
                    : null,
                backgroundColor: GPTheme.primaryColor.withOpacity(0.15),
                child: match.profile.displayPhoto.isEmpty
                    ? Text(
                        match.profile.name[0].toUpperCase(),
                        style: TextStyle(
                          color: GPTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: GPTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            '${match.profile.name}, ${match.profile.age}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.primary,
            ),
          ),
          subtitle: Text(
            match.profile.city ?? '',
            style: TextStyle(fontSize: 12, color: context.subtle),
          ),
          trailing: GestureDetector(
            onTap: onMessage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: GPTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET LIKÉS
// ─────────────────────────────────────────────────────────────────────────────
class _LikesTab extends StatelessWidget {
  final DatingController ctrl;
  const _LikesTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.likedProfiles.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thumb_up_outlined, size: 48, color: context.subtle),
              const SizedBox(height: 14),
              Text(
                'Vous n\'avez encore liké personne',
                style: TextStyle(color: context.subtle, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: ctrl.likedProfiles.length,
        itemBuilder: (_, i) {
          final p = ctrl.likedProfiles[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ProfilePhoto(url: p.displayPhoto),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.5, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.name}, ${p.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (p.city != null)
                        Text(
                          p.city!,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREFERENCES SETUP (onboarding)
// ─────────────────────────────────────────────────────────────────────────────
class _PreferencesSetup extends StatelessWidget {
  final DatingController ctrl;
  const _PreferencesSetup({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: GPTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: GPTheme.primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Bienvenue dans le Dating ! ${activeUser.value.toJson()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Dites-nous vos préférences pour trouver votre match idéal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.subtle,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Genre recherché
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Je recherche',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignme
                    children: [
                      _GenderChip(
                        label: 'Femmes',
                        icon: Icons.female_rounded,
                        selected: ctrl.selectedLookingFor.value == 'female',
                        onTap: () => ctrl.selectedLookingFor.value = 'female',
                      ),
                      const SizedBox(width: 8),
                      _GenderChip(
                        label: 'Hommes',
                        icon: Icons.male_rounded,
                        selected: ctrl.selectedLookingFor.value == 'male',
                        onTap: () => ctrl.selectedLookingFor.value = 'male',
                      ),
                      const SizedBox(width: 8),
                      _GenderChip(
                        label: 'Les deux',
                        icon: Icons.people_rounded,
                        selected: ctrl.selectedLookingFor.value == 'both',
                        onTap: () => ctrl.selectedLookingFor.value = 'both',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tranche d\'âge',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.primary,
                  ),
                ),
              ),
              Obx(() {
                return Column(
                  children: [
                    RangeSlider(
                      values: RangeValues(
                        ctrl.minAge.value.toDouble(),
                        ctrl.maxAge.value.toDouble(),
                      ),
                      min: 18,
                      max: 60,
                      divisions: 42,
                      activeColor: GPTheme.primaryColor,
                      inactiveColor: GPTheme.primaryColor.withOpacity(0.15),
                      labels: RangeLabels(
                        '${ctrl.minAge.value} ans',
                        '${ctrl.maxAge.value} ans',
                      ),
                      onChanged: (v) {
                        ctrl.minAge.value = v.start.round();
                        ctrl.maxAge.value = v.end.round();
                      },
                    ),
                    Text(
                      '${ctrl.minAge.value} – ${ctrl.maxAge.value} ans',
                      style: TextStyle(color: context.subtle),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 36),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ctrl.isSubmitting.value
                        ? null
                        : ctrl.savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GPTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: ctrl.isSubmitting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Commencer à découvrir',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREFERENCES SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PreferencesSheet extends StatelessWidget {
  final DatingController ctrl;
  const _PreferencesSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mes préférences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Je recherche',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: context.primary,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GenderChip(
                    label: 'Des femmes',
                    icon: Icons.female_rounded,
                    selected: ctrl.selectedLookingFor.value == 'female',
                    onTap: () => ctrl.selectedLookingFor.value = 'female',
                  ),
                  const SizedBox(width: 10),
                  _GenderChip(
                    label: 'Des hommes',
                    icon: Icons.male_rounded,
                    selected: ctrl.selectedLookingFor.value == 'male',
                    onTap: () => ctrl.selectedLookingFor.value = 'male',
                  ),
                  const SizedBox(width: 10),
                  _GenderChip(
                    label: 'Les deux',
                    icon: Icons.people_rounded,
                    selected: ctrl.selectedLookingFor.value == 'both',
                    onTap: () => ctrl.selectedLookingFor.value = 'both',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tranche d\'âge',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: context.primary,
            ),
          ),
          Obx(
            () => RangeSlider(
              values: RangeValues(
                ctrl.minAge.value.toDouble(),
                ctrl.maxAge.value.toDouble(),
              ),
              min: 18,
              max: 60,
              divisions: 42,
              activeColor: GPTheme.primaryColor,
              inactiveColor: GPTheme.primaryColor.withOpacity(0.15),
              labels: RangeLabels(
                '${ctrl.minAge.value} ans',
                '${ctrl.maxAge.value} ans',
              ),
              onChanged: (v) {
                ctrl.minAge.value = v.start.round();
                ctrl.maxAge.value = v.end.round();
              },
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => SizedBox(
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENDER CHIP
// ─────────────────────────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? GPTheme.primaryColor
              : GPTheme.primaryColor.withOpacity(context.isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? GPTheme.primaryColor
                : GPTheme.primaryColor.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : GPTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : GPTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
