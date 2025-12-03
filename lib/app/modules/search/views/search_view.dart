import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_bar_wi.dart';
import 'package:grand_public_v2/app/components/bottom_bar.dart';
import 'package:grand_public_v2/app/components/drawer_bloc.dart';
import 'package:grand_public_v2/app/modules/pages/search_page.dart';

import '../controllers/search_controller.dart';

class SearchView extends GetView<SearchPageController> {
  const SearchView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBarWi(),
      ),
      drawer: DrawerBloc(),
      body: SerachPage(),
      bottomNavigationBar: BottomBarWi(),
    );
  }
}
