// lib/app/modules/home/controllers/home_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/section_model.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESTINATION — unité de navigation dans le layout HomeView
// ─────────────────────────────────────────────────────────────────────────────
class HomeDestination {
  final String route; // clé unique → AnimatedSwitcher + debug
  final int sectionIndex; // onglet bottom-bar actif
  final bool isSubPage; // true → back-button AppBar visible
  final Widget Function() builder; // construit lazily

  const HomeDestination({
    required this.route,
    required this.sectionIndex,
    required this.builder,
    this.isSubPage = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class HomeController extends GetxController {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _stack = <HomeDestination>[].obs;
  final _box = GetStorage();

  // ── Getters ───────────────────────────────────────────────────────────────
  HomeDestination get _current => _stack.last;
  String get currentRoute => _current.route;
  int get activeSectionIndex => _current.sectionIndex;
  Widget get currentPage => _current.builder();
  bool get canPop => _stack.length > 1;

  // ── Page registry ─────────────────────────────────────────────────────────
  // HomeBinding enregistre ici les builders des pages internes.
  // Clé = route logique (ex: '/profile', '/home/spaces').
  // Valeur = fonction qui reçoit des params et retourne un Widget.
  // → zéro import circulaire dans ce controller.
  final Map<String, Widget Function(Map<String, dynamic>)> _registry = {};

  void registerPage(
    String route,
    Widget Function(Map<String, dynamic> params) builder,
  ) {
    _registry[route] = builder;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _stack.add(_sectionDest(0));

    // Section demandée depuis MainPageView
    final pending = _box.read<int>('_pendingSection');
    if (pending != null && pending >= 0 && pending < sections.length) {
      debugPrint('HomeController ▶ pending section: $pending');
      _box.remove('_pendingSection');
      _stack.assignAll([_sectionDest(pending)]);
      ToastHelper.showToast(
        'Menu mis à jour : ${sections[pending].title}',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION  (bottom bar)
  // ─────────────────────────────────────────────────────────────────────────
  void goToSection(int index, {bool showToast = true}) {
    if (index == activeSectionIndex && !canPop) return;
    _closeDrawer();
    _stack.assignAll([_sectionDest(index)]);
    if (showToast) {
      ToastHelper.showToast(
        'Menu mis à jour : ${sections[index].title}',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATE TO — sous-page dans le layout
  // params : données à passer au builder (ex: spaceId, categoryIndex…)
  // ─────────────────────────────────────────────────────────────────────────
  void navigateTo(String route, {Map<String, dynamic> params = const {}}) {
    _closeDrawer();

    // Routes qui sortent du layout (GetX router + propre Scaffold)
    if (_isExternalRoute(route)) {
      Get.toNamed(route, parameters: params.map((k, v) => MapEntry(k, '$v')));
      return;
    }

    // Évite d'empiler la même destination exacte
    final uniqueKey = _routeKey(route, params);
    if (_stack.isNotEmpty && _stack.last.route == uniqueKey) return;

    final dest = _resolveDest(route, uniqueKey, params);
    if (dest != null) _stack.add(dest);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BACK
  // ─────────────────────────────────────────────────────────────────────────
  void popPage() {
    if (canPop) _stack.removeLast();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────────────────
  void logout() {
    GetStorage().remove('token');
    GetStorage().remove('isDark');
    GetStorage().remove('isLogged');
    Get.offAllNamed('/login');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void _closeDrawer() {
    if (scaffoldKey.currentState?.isDrawerOpen == true) {
      scaffoldKey.currentState!.closeDrawer();
    }
  }

  HomeDestination _sectionDest(int index) {
    final section = sections[index];
    return HomeDestination(
      route: '/section_$index',
      sectionIndex: index,
      isSubPage: false,
      builder: () {
        if (section.isLive && section.page != null) return section.page!;
        return _ComingSoonWidget(section: section);
      },
    );
  }

  /// Route key unique = route + params sérialisés
  /// Permet à AnimatedSwitcher de détecter qu'on navigue vers un espace différent.
  String _routeKey(String route, Map<String, dynamic> params) {
    if (params.isEmpty) return route;
    final q = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$route?$q';
  }

  /// Résolution générique : cherche dans le registry,
  /// sinon délègue à GetX (qui affichera la route GetX enregistrée).
  HomeDestination? _resolveDest(
    String route,
    String routeKey,
    Map<String, dynamic> params,
  ) {
    final builder = _registry[route];
    if (builder == null) {
      ToastHelper.showToast(
        'Bientôt disponible !',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return null;
    }
    return HomeDestination(
      route: routeKey,
      sectionIndex: activeSectionIndex,
      isSubPage: true,
      // Le Scaffold transparent permet aux pages qui ont leur propre
      // couleur de fond (ProfileView, SpacesListView…) de s'afficher
      // correctement sans double fond.
      builder: () => builder(params),
    );
  }

  bool _isExternalRoute(String route) {
    if (route == '/login' || route == '/register') return true;
    // SpaceView (détail) a son propre SliverAppBar + Scaffold complet
    if (route.startsWith('/home/spaces/')) return true;
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMING SOON WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _ComingSoonWidget extends StatefulWidget {
  final SectionModel section;
  const _ComingSoonWidget({required this.section});

  @override
  State<_ComingSoonWidget> createState() => _ComingSoonWidgetState();
}

class _ComingSoonWidgetState extends State<_ComingSoonWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _anim,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.section.icon,
                        size: 80,
                        color: Colors.white24,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'BIENTÔT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _anim,
              child: Text(
                widget.section.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _anim,
              child: Text(
                widget.section.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
