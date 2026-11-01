import 'package:get/get.dart';

import '../controllers/blowmusic_controller.dart';

class BlowMusicBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent : sinon GetX le supprime à la sortie de la page et onClose()
    // coupe le son → le mini-lecteur flottant n'aurait rien à afficher.
    final c = Get.isRegistered<BlowMusicController>()
        ? Get.find<BlowMusicController>()
        : Get.put<BlowMusicController>(BlowMusicController(), permanent: true);
    c.onEnterModule(); // re-sélectionne l'onglet (Live / argument 'tab') à chaque entrée
  }
}
