import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

import '../controllers/main_page_controller.dart';

class MainPageView extends GetView<MainPageController> {
  MainPageView({super.key});

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GPTheme.primaryColor,
      floatingActionButton: FloatingActionButton.small(
        shape: CircleBorder(),
        onPressed: () {
          GetStorage().remove('token');
          GetStorage().remove('isLogged');
          debugPrint("Logged out !");
          Get.offAllNamed('/login');
        },
        child: Icon(Icons.logout_outlined),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),

            Image.asset(
              LOGO_PIXEL,
              height: 100,
              width: 100,
              cacheHeight: 100,
              cacheWidth: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              "Explorez les différentes Sections dp !",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 15),

            ...userMenuItems.map((item) {
              return buildItem(
                context,
                item.title,
                item.description,
                item.route,
                item.icon,
              );
            }),

            // ...adminMenu.map((group) {
            //   return buildItemGroup(
            //     group.title,
            //     group.items.map((item) {
            //       return buildItem(
            //         context,
            //         item.title,
            //         item.description,
            //         item.route,
            //         item.icon,
            //       );
            //     }).toList(),
            //   );
            // }),
          ],
        ),
      ),
    );
  }
}

Widget buildItemGroup(String title, List<Widget> children) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: ExpansionTile(
      shape: Border.all(color: Colors.transparent),
      tilePadding: const EdgeInsets.only(left: 0, right: 5),
      iconColor: GPTheme.primaryColor,
      onExpansionChanged: (value) {},
      title: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.only(left: 15),
        height: 45,
        decoration: BoxDecoration(
          color: GPTheme.secondaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Text(
          title,
          overflow: TextOverflow.fade,
          maxLines: 1,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      children: children,
    ),
  );
}

Widget buildItem(
  BuildContext context,
  String label,
  String subtitle,
  String? page,
  IconData icon,
) {
  return GestureDetector(
    onTap: () async {
      if (page != null) {
        try {
          Get.offAllNamed(page);
        } catch (e) {
          await ToastHelper.showToast(
            'Page en Construction !',
            backgroundColor: Colors.amber,
            textColor: Colors.white,
          );
        }
      } else {
        // await ToastHelper.showToast(
        //   'Commentaire envoyé et attente de validation',
        //   backgroundColor: Colors.green,
        //   textColor: Colors.white,
        // );
        // await ToastHelper.showToast(
        //   'Error: $page Not Found',
        //   backgroundColor: Colors.red,
        //   textColor: Colors.white,
        // );
        await ToastHelper.showToast(
          'On y travaille !',
          backgroundColor: Colors.amber,
          textColor: Colors.white,
        );
      }
    },
    child: Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(icon, size: 40, color: GPTheme.primaryColor),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: GPTheme.primaryColor),
          ],
        ),
      ),
    ),
  );
}
