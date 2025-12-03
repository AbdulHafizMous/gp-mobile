import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_bar_wi.dart';
import 'package:grand_public_v2/app/components/bottom_bar.dart';
import 'package:grand_public_v2/app/components/drawer_bloc.dart';
import 'package:grand_public_v2/app/modules/pages/profil_page.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: AppBarWi(),
      ),
      body: ProfilPage(),
      drawer: DrawerBloc(),
      bottomNavigationBar: BottomBarWi(),
    );
  }
}
