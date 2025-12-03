import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PayementFail extends StatelessWidget {
  const PayementFail({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.close,
          color: Colors.redAccent,
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
