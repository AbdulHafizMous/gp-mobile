import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_bar_wi.dart';

import '../controllers/soon_controller.dart';

class SoonView extends GetView<SoonController> {
  const SoonView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: AppBarWi(),
      ),
      body: Container(
        color: Colors.white,
        child: const Center(
          child: Text(
            'Bientôt disponible',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
    );
  }
}
