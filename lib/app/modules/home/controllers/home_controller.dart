// lib/app/modules/home/controllers/home_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/section_model.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/notification_service.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESTINATION
// ─────────────────────────────────────────────────────────────────────────────
class HomeDestination {
  final String route;
  final int sectionIndex;
  final bool isSubPage;
  final Widget Function() builder;

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
  Color get activeSectionColor {
    return GPTheme.colorForSection(activeSectionIndex);
  }

  // ── Page registry ─────────────────────────────────────────────────────────
  final Map<String, Widget Function(Map<String, dynamic>)> _registry = {};

  void registerPage(
    String route,
    Widget Function(Map<String, dynamic> params) builder,
  ) {
    _registry[route] = builder;
  }

  // ── Back interceptors ─────────────────────────────────────────────────────
  // Les pages internes peuvent enregistrer un callback ici pour gérer le
  // bouton retour global à leur façon.
  //
  // Le callback doit retourner :
  //   true  → la page a géré le retour elle-même (ex: revenir à main profil)
  //           → HomeController ne fait rien
  //   false → la page n'a rien à gérer → HomeController fait popPage() normal
  final Map<String, bool Function()> _backInterceptors = {};

  /// Enregistre un intercepteur pour une route.
  /// Appelé par les pages dans leur initState / onInit.
  void registerBackInterceptor(String route, bool Function() handler) {
    _backInterceptors[route] = handler;
  }

  /// Supprime l'intercepteur. Appelé dans dispose().
  void unregisterBackInterceptor(String route) {
    _backInterceptors.remove(route);
  }

  //

  List<AppNotification> notifications = [];

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  Future<void> initialLoad() async {
    await NotificationService.init();
    debugPrint("Fetching User");
    activeUser.value = await getUser();
  }

  Future<void> initPusherClient() async {
    if (kIsWeb) {
      debugPrint('Pusher not initialized on web');
      return;
    }
    try {
      await pusher.init(
        apiKey: PUSHER_API_KEY,
        cluster: PUSHER_API_CLUSTER,
        logToConsole: true,
        onConnectionStateChange: (state, _) =>
            debugPrint('Connection state changed: $state'),
        onError: (error, code, data) => debugPrint('Pusher error: $error'),
        onSubscriptionSucceeded: (channel, _) =>
            debugPrint('Subscription succeeded: $channel'),
        onEvent: (PusherEvent event) {
          debugPrint(event.data);
          try {
            notifications.add(
              AppNotification(
                id: DateTime.now().millisecondsSinceEpoch,
                isRead: false,
                body: event.data["description"],
                title: event.data["title"],
                createdAt: DateTime.now().toIso8601String(),
                type: "general",
              ),
            );
          } catch (e) {
            debugPrint('Malformed pusher event: $e');
          }
        },
      );
      await pusher.subscribe(channelName: 'new-notification');
      await pusher.connect();
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  Future<User> getUser() async {
    try {
      dynamic jsonVal;
      if (useMock) {
        jsonVal = {
          "id": 1,
          "name": "Hafiz MOUSTAPHA",
          "username": null,
          "phone": "+2290161648007",
          "avatar_url": null,
          "birthday": null,
          "city": null,
          "gender": null,
          "description": null,
          "looking_for_gender": null,
          "fcm_token": null,
          "firebase_id": null,
          "role": "user",
          "email": "hafizmoustapha64@gmail.com",
          "country_code": "BJ",
          "is_otp_verified": true,
          "is_active": true,
          "needs_completion": false,
          "email_verified_at": null,
          "created_at": "2026-03-16T10:30:00.000000Z",
          "updated_at": "2026-03-16T10:30:00.000000Z",
        };
      } else {
        final response = await RequestService().get('/auth/me');
        jsonVal = response.data;
      }

      final data = jsonVal['data']['user'];
      User user = User.fromJson(data);
      activeUser.value = user;
      GetStorage().write('username', data['name']);
      GetStorage().write('email', data['email']);
      return user;
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint(
          'Error: ${e.response?.statusCode} ${e.response?.statusMessage}',
        );
        await ToastHelper.showToast(
          'Server error: ${e.response?.statusCode} ${e.response?.statusMessage}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        debugPrint('Error: ${e.message}');
        await ToastHelper.showToast(
          'Error: ${e.message}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return User.empty();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _stack.add(_sectionDest(shouldSkipMedia ? 1 : 0));

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
    //
    initPusherClient();
    initialLoad();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION (bottom bar)
  // ─────────────────────────────────────────────────────────────────────────
  void goToSection(int index, {bool showToast = true}) {
    if (shouldSkipMedia && index == 0) return; // Espaces masqué
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
  // NAVIGATE TO
  // ─────────────────────────────────────────────────────────────────────────
  void navigateTo(String route, {Map<String, dynamic> params = const {}}) {
    _closeDrawer();

    // Soumission App Store sans médias : on bloque tout accès direct
    // (deep link, notif...) aux Espaces et au Premium tant que c'est masqué.
    if (shouldSkipMedia &&
        (route.startsWith('/home/spaces') || route == '/social-premium')) {
      return;
    }

    if (_isExternalRoute(route)) {
      Get.toNamed(route, parameters: params.map((k, v) => MapEntry(k, '$v')));
      return;
    }

    final uniqueKey = _routeKey(route, params);
    if (_stack.isNotEmpty && _stack.last.route == uniqueKey) return;

    final dest = _resolveDest(route, uniqueKey, params);
    if (dest != null) _stack.add(dest);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POP PAGE — avec délégation aux intercepteurs internes
  // ─────────────────────────────────────────────────────────────────────────
  void popPage() {
    // La route de base sans query params
    final baseRoute = currentRoute.split('?').first;

    // Cherche d'abord un intercepteur enregistré pour cette route
    final interceptor = _backInterceptors[baseRoute];
    if (interceptor != null) {
      final handled = interceptor();
      if (handled) {
        // La page a géré le retour elle-même → on ne dépile pas
        return;
      }
    }

    // Comportement normal : dépiler
    if (canPop) _stack.removeLast();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────────────────
  void logout() {
    activeUser.value = User.empty();
    GetStorage().erase();
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

  String _routeKey(String route, Map<String, dynamic> params) {
    if (params.isEmpty) return route;
    final q = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$route?$q';
  }

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
      builder: () => builder(params),
    );
  }

  bool _isExternalRoute(String route) {
    if (route == '/login' || route == '/register') return true;
    if (route.startsWith('/home/spaces/')) return true;
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMING SOON WIDGET (inchangé)
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
