import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class ToastHelper {
  static Future<void> showToast(String msg,
      {Color backgroundColor = Colors.black,
      Color textColor = Colors.white}) async {
    try {
      await Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: 16.0,
      );
    } catch (e) {
      // Fallback to Get.snackbar when Fluttertoast plugin isn't available (web/desktop tests)
      debugPrint('Fluttertoast unavailable, fallback to Get.snackbar: $e');
      Get.snackbar('', msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: backgroundColor,
          colorText: textColor);
    }
  }
}
