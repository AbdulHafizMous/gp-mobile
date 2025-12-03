import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class PaySucController extends GetxController {
  //TODO: Implement PaySucController

  final count = 60.obs;

  Future<void> payementSave(int amount) async {
    try {
      var mail = GetStorage().read('email');

      if (mail == null) return;
      await RequestService().post(
        '/payment/store',
        data: {
          "amount": amount,
          "email": mail,
          "phone_number": "+22940428170",
          "subscription_id": "1",
          "transaction_id": "eG7Hds4F",
        },
      );
    } catch (e) {
      debugPrint(e.toString());
    }
    return;
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    await payementSave(1000);
  }

  void increment() => count.value++;
}
