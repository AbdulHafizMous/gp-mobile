import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';

class ShopBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopController>(() => ShopController(), fenix: true);
  }
}
