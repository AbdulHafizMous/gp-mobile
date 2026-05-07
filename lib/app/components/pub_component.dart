import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class PubComponent extends StatefulWidget {
  const PubComponent({super.key});

  @override
  State<PubComponent> createState() => _PubComponentState();
}

class _PubComponentState extends State<PubComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: GPTheme.primaryColor,
      height: 50,
      child: const Center(
        child: Text(
          "PUB",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
