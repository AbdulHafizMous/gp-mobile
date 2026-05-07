import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PayementSuc extends StatelessWidget {
  const PayementSuc({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.check,
          color: Colors.green,
          size: 20,
        ),
        const SizedBox(
          height: 20,
        ),
        const Text("Paiment effectué"),
        const SizedBox(
          height: 20,
        ),
        ElevatedButton(
          onPressed: () => {
            Get.back(),
          },
          child: const Text("Continuer"),
        ),
      ],
    );
  }
}
