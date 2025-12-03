import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_bar_wi.dart';
import 'package:grand_public_v2/app/modules/pages/payement_suc.dart';

import '../controllers/pay_suc_controller.dart';

class PaySucView extends GetView<PaySucController> {
  const PaySucView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(controller.count.value.toDouble()),
        child: const AppBarWi(),
      ),
      body: const PayementSuc(),
    );
  }
}
