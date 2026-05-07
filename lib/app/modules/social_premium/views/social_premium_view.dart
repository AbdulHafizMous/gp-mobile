import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/pages/premium_page.dart';
import '../controllers/social_premium_controller.dart';

class SocialPremiumView extends GetView<SocialPremiumController> {
  const SocialPremiumView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const PremiumPage()); 
  }
}
