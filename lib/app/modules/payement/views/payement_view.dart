import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/payement_controller.dart';

class PayementView extends GetView<PayementController> {
  const PayementView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayementView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'PayementView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
