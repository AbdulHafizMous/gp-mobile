import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_bar_wi.dart';
import 'package:grand_public_v2/app/components/bottom_bar.dart';
import 'package:grand_public_v2/app/components/drawer_bloc.dart';
import 'package:grand_public_v2/app/modules/pages/premium_page.dart';

import '../controllers/social_premium_controller.dart';

class SocialPremiumView extends GetView<SocialPremiumController> {
  const SocialPremiumView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: AppBarWi(),
      ),
      drawer: DrawerBloc(),
      body: PremiumPage(),
      bottomNavigationBar: BottomBarWi(),
    );
  }
}
