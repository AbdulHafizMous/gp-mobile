import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/pages/link_page.dart';

import '../controllers/social_link_controller.dart';

class SocialLinkView extends GetView<SocialLinkController> {
  const SocialLinkView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const LinkPage());
  }
}
