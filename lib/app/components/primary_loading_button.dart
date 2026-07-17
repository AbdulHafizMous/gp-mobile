import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

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
        child: Center(
          child: CircularProgressIndicator(
            color: GPTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
