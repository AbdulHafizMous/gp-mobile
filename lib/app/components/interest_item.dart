import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class InterestItem extends StatefulWidget {
  const InterestItem({super.key, required this.title});

  final String title;

  @override
  State<InterestItem> createState() => _InterestItemState();
}

class _InterestItemState extends State<InterestItem> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => {
        setState(() {
          isSelected = !isSelected;
        }),
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          border: !isSelected
              ? Border.all(width: 1, color: Colors.black)
              : null,
          borderRadius: const BorderRadius.all(Radius.circular(15)),
        ),
        child: Center(
          child: Text(
            widget.title,
            style: TextStyle(
              color: isSelected ? GPTheme.primaryColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
