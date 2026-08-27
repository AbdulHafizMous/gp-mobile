import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/utils/section_helper.dart';

class InterestItem extends StatefulWidget {
  final String title;
  final bool isSelected;
  final bool fromProfile;
  final VoidCallback onTap;

  const InterestItem({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.fromProfile = false,
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
              ? (widget.fromProfile ? SectionHelper.color : Colors.white)
              : Colors.transparent,
          border: Border.all(
            width: 1,
            color: widget.fromProfile ? SectionHelper.color : Colors.white,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(30)),
        ),
        child: Center(
          child: Text(
            widget.title,
            style: TextStyle(
              color: widget.isSelected
                  ? (widget.fromProfile ? Colors.white : SectionHelper.color)
                  : (widget.fromProfile ? SectionHelper.color : Colors.white),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
