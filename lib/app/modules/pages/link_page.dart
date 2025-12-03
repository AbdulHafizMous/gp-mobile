import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkPage extends StatefulWidget {
  const LinkPage({super.key});

  @override
  State<LinkPage> createState() => _LinkPageState();
}

class _LinkPageState extends State<LinkPage> {
  // facebok, instagram, youtube, twitter, snapchat, tiktok
  final liens = [
    {
      "title": "Facebook",
      "subtitle": "@grandpublic",
      "icon": "assets/icons/red_facebook.png",
      "link": "https://www.facebook.com/grandpublic",
    },
    {
      "title": "Instagram",
      "subtitle": "@grandpublic",
      "icon": "assets/icons/red_insta.png",
      "link": "https://www.instagram.com/grandpublic",
    },
    {
      "title": "Youtube",
      "subtitle": "Grand Public TV",
      "icon": "assets/icons/red_youtube.png",
      "link": "https://www.youtube.com/grandpublic",
    },
    {
      "title": "Twitter",
      "subtitle": "@grandpublic",
      "icon": "assets/icons/red_tw.png",
      "link": "https://www.twitter.com/grandpublic",
    },
    {
      "title": "Snapchat",
      "subtitle": "@grandpublic",
      "icon": "assets/icons/red_snap.png",
      "link": "https://www.snapchat.com/grandpublic",
    },
    {
      "title": "Tiktok",
      "subtitle": "@grandpublic",
      "icon": "assets/icons/red_tiktok.png",
      "link": "https://www.tiktok.com/grandpublic",
    },
  ];

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      Fluttertoast.showToast(
        msg: "Impossible d'ouvrir le lien",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          "LIENS",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: GPTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ListView.separated(
          padding: const EdgeInsets.all(15),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          shrinkWrap: true,
          itemCount: liens.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                leading: Image.asset(
                  liens[index]["icon"]!,
                  width: 50,
                  height: 50,
                ),
                title: Text(liens[index]["title"]!),
                subtitle: Text(liens[index]["subtitle"]!),
                onTap: () {
                  _launchUrl(Uri.parse(liens[index]["link"]!));
                },
                trailing: const Icon(Icons.arrow_outward_outlined),
              ),
            );
          },
        ),
      ],
    );
  }
}
