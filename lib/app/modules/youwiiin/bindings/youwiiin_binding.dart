import 'package:get/get.dart';
import '../controllers/youwiiin_controller.dart';

class YouwiiinBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: le contrôleur est recréé si une autre route (lobby, jeu) qui partage ce binding
    // a été fermée et l'a supprimé, sinon Get.find lève « not found » sur l'accueil.
    Get.lazyPut<YouwiiinController>(() => YouwiiinController(), fenix: true);
  }
}
