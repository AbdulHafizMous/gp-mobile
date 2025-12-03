import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/modules/profile/controllers/profile_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final controller = Get.put(ProfileController());

  List actions = [
    {
      "title": "Modifier mon compte",
      "icon": const Icon(Icons.arrow_forward_ios),
      "actions": () => Get.toNamed("/edit-profile"),
    },
    {
      "title": "Gérer mes abonnements",
      "icon": const Icon(Icons.arrow_forward_ios),
      "actions": () => Get.toNamed("/manage-subscriptions"),
    },
    {
      "title": "Alertes",
      "icon": const Icon(Icons.notifications),
      "actions": () => Get.toNamed("/alerts"),
    },
    {
      "title": "Mes favoris",
      "icon": const Icon(Icons.arrow_forward_ios),
      "actions": () => Get.toNamed("/favorites"),
    },
    {"title": "Mode sombre", "actions": () => {}},
  ];

  void switchTheme() {
    controller.isDark.value = !controller.isDark.value;
    final bool isd = controller.isDark.value;
    GetStorage().write("isDark", isd);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "MON COMPTE",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: GPTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                            "https://s3-alpha-sig.figma.com/img/5bdc/3b1d/4d8603f4b4d57d797b50c64952efca09?Expires=1742169600&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=jEGmjPhUwlTZJoYBlcWEQBh~ThHwgt5fk4ufOF41ZN5l5WxFnrfW6N4OtnCWM3BALu~MHwnov3ouJdPZ5kgTS~8L7ffb06d9JpEXMDRd3mAwPCL~yQ4iWm7Flgu06DWvndIjHlW2eSAj94TmhwWR8C8BhizAfy3Ks6XudPEXdpE7op0S-2cm0pi6EXlSbmM9TikVB7sDg30BcV0MDaP76SJ35pxdX3Mf6E8BdgyHd3-lEnbCpxMHRdqdhqULOy1HHZTYiGzjF2J9yCcDtxoqgdCn7orv5GBy7kU0-DVK-Tz6wu1HFCwWvuYAAWc1~Yj73haOPQHjjnsVdXwjo~VUlQ__",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Text(
                                GetStorage().read('username'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => {},
                              child: const Text(
                                "Ajouter une description",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    const Row(
                      children: [
                        Icon(Icons.emoji_emotions),
                        SizedBox(width: 10),
                        Text(
                          "Avatar",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(actions[index]["title"]),
                    trailing: index != 4
                        ? actions[index]["icon"]
                        : Obx(
                            () => Switch(
                              thumbColor: WidgetStatePropertyAll(
                                GPTheme.primaryColor,
                              ),
                              value: controller.isDark.value,
                              onChanged: (value) => switchTheme(),
                              activeThumbColor: GPTheme.primaryColor,
                            ),
                          ),
                    onTap: actions[index]["actions"],
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.all(8.0),
            child: const Text(
              "Paramètres",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Modifier mon mot de passe"),
                Icon(Icons.arrow_forward_ios),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              GetStorage().remove('isLogged');
              GetStorage().remove('token');
              Get.offAllNamed('/login');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Se déconnecter",
                  style: TextStyle(color: GPTheme.primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
