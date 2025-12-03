import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/large_card.dart';
import 'package:grand_public_v2/app/data/models/video.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

class LinkList extends StatefulWidget {
  const LinkList({super.key, required this.title, required this.category});

  final String title;
  final String category;
  @override
  State<LinkList> createState() => _LinkListState();
}

class _LinkListState extends State<LinkList> {
  final controller = Get.put(HomeController());

  List<Video> _videos = [];
  bool loading = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: GPTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        FutureBuilder(
          future: controller.fetchVideoByCat(widget.category),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error'));
            }
            if (snapshot.hasData) {
              _videos = snapshot.data as List<Video>;
              return ListView.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  return LargeVCard(element: _videos[index]);
                },
              );
            }
            return const Center(child: Text('No data'));
          },
        ),
      ],
    );
  }
}
