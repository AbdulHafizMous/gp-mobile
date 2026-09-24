import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/blowmusic_controller.dart';

class FullscreenVideoPage extends StatefulWidget {
  const FullscreenVideoPage({super.key});

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  @override
  void initState() {
    super.initState();
    // Forcer la mise en page paysage + cacher la barre de statut/navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restaurer le mode portrait et afficher la barre système en quittant
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BlowMusicController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: ctrl.videoPlayerController != null &&
                    ctrl.videoPlayerController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: ctrl.videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(ctrl.videoPlayerController!),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          // Bouton Quitter le plein écran en haut à gauche
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 32),
                onPressed: () {
                  ctrl.isFullScreen.value = false;
                  Get.back(); // Ferme la vue plein écran
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}