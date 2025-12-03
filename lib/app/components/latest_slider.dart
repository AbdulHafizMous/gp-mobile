import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/main_card.dart';
import 'package:grand_public_v2/app/data/models/video.dart';
import 'package:grand_public_v2/app/modules/home/controllers/home_controller.dart';

class LatestSlider extends StatefulWidget {
  const LatestSlider({super.key, required this.cat});

  final String cat;

  @override
  State<LatestSlider> createState() => _LatestSliderState();
}

class _LatestSliderState extends State<LatestSlider> {
  final _controller = Get.put(HomeController());
  List<Video> video = [];
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: FutureBuilder(
        future: _controller.fetchLatestVideoByCat(widget.cat),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          }
          if (snapshot.hasData) {
            video = snapshot.data as List<Video>;

            if (video.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text("Aucune vidéos récente")),
              );
            } else {
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: video.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return BaseVCard(element: video[index]);
                },
              );
            }
          }

          return const Center(child: Text("No data"));
        },
      ),
    );
  }
}
