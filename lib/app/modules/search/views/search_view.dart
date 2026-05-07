import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/pages/search_page.dart';

import '../controllers/search_controller.dart';

class SearchView extends GetView<SearchPageController> {
  const SearchView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const SerachPage());
  }
}
