import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_bar_wi.dart';
import 'package:grand_public_v2/app/components/bottom_bar.dart';
import 'package:grand_public_v2/app/components/drawer_bloc.dart';
import 'package:grand_public_v2/app/modules/pages/link_list.dart';

import '../controllers/insolite_controller.dart';

class InsoliteView extends GetView<InsoliteController> {
  const InsoliteView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: AppBarWi(),
      ),
      drawer: DrawerBloc(),
      body: LinkList(title: "INSOLITE", category: "insolite"),
      bottomNavigationBar: BottomBarWi(),
    );
  }
}
