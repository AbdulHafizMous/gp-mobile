import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_bar_wi.dart';
import 'package:grand_public_v2/app/modules/pages/payement_fail.dart';

import '../controllers/pay_fail_controller.dart';

class PayFailView extends GetView<PayFailController> {
  const PayFailView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBarWi(),
      ),
      body: PayementFail(),
    );
  }
}
