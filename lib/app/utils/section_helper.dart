import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class SectionHelper {
  static int get index {
    return Get.find<HomeController>().activeSectionIndex;
  }

  static Color get color {
    return GPTheme.colorForSection(index);
  }

  static Color get contentColor {
    return GPTheme.contentColorForSection(index);
  }

  static String get logo {
    return GPTheme.logoForSection(index);
  }
}