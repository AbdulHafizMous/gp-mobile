import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class InterestItem extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const InterestItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<InterestItem> createState() => _InterestItemState();
}

class _InterestItemState extends State<InterestItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Colors.white.withAlpha(240)
              : Colors.transparent,
          border: !widget.isSelected
              ? Border.all(width: 1, color: Colors.white)
              : null,
          borderRadius: const BorderRadius.all(Radius.circular(30)),
        ),
        child: Center(
          child: Text(
            widget.title,
            style: TextStyle(
              color: widget.isSelected ? GPTheme.primaryColor : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
