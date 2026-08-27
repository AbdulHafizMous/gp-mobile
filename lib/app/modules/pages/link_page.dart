import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grand_public_v2/app/utils/section_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LinkPage extends StatefulWidget {
  const LinkPage({super.key});

  @override
  State<LinkPage> createState() => _LinkPageState();
}

class _LinkPageState extends State<LinkPage> {
  final liens = [
    {
      "icon": FontAwesomeIcons.youtube,
      "href": "https://www.youtube.com/@Grandpublic2024",
      "label": "YouTube",
    },
    {
      "icon": FontAwesomeIcons.facebook,
      "href": "https://www.facebook.com/grandpublicofficiel/",
      "label": "Facebook",
    },
    {
      "icon": FontAwesomeIcons.instagram,
      "href": "https://www.instagram.com/grandpublic1/",
      "label": "Instagram",
    },
    {
      "icon": FontAwesomeIcons.xTwitter,
      "href": "https://x.com/grandpublictv",
      "label": "X (Twitter)",
    },
    {
      "icon": FontAwesomeIcons.whatsapp,
      "href": "https://wa.me/+2290163634444",
      "label": "WhatsApp",
    },
    {"icon": FontAwesomeIcons.snapchat, "href": "#", "label": "Snapchat"},
    {
      "icon": FontAwesomeIcons.tiktok,
      "href": "https://www.tiktok.com/@grandpublic",
      "label": "TikTok",
    },
  ];

  Future<void> _launchUrl(String url) async {
    if (url == "#") {
      Fluttertoast.showToast(
        msg: "Lien Snapchat indisponible",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      return;
    }

    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Fluttertoast.showToast(
        msg: "Impossible d'ouvrir le lien",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            "LIENS",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          ListView.separated(
            padding: const EdgeInsets.all(15),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: liens.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),

            itemBuilder: (context, index) {
              final lien = liens[index];

              return Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),

                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: AlignmentGeometry.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    child: FaIcon(
                      lien["icon"] as FaIconData,
                      size: 25,
                      color: SectionHelper.color,
                    ),
                  ),

                  title: Text(
                    lien["label"] as String,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  onTap: () => _launchUrl(lien["href"] as String),

                  trailing: Icon(
                    Icons.arrow_outward_rounded,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
