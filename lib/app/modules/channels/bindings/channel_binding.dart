import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/channels/controllers/channel_controller.dart';
import 'package:grand_public_v2/app/modules/space/controllers/space_controller.dart';

/// Enregistre ChannelController SOUS le type SpaceController : SpaceView
/// (GetView<SpaceController>) l'utilise donc tel quel.
class ChannelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SpaceController>(() => ChannelController());
  }
}
