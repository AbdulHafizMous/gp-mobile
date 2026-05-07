import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'package:kkiapay_flutter_sdk/utils/config.dart' as GPTheme;

class PrimaryLoadingButton extends StatelessWidget {
  const PrimaryLoadingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: const Center(
          child: CircularProgressIndicator(
            color: GPTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
