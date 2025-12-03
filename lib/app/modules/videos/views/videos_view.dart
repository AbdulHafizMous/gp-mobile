import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:grand_public_v2/app/components/app_bar_wi.dart';
import 'package:grand_public_v2/app/components/bottom_bar.dart';
import 'package:grand_public_v2/app/modules/pages/vid_detail.dart';
import 'package:grand_public_v2/app/data/models/video.dart';

import '../controllers/videos_controller.dart';

class VideosView extends GetView<VideosController> {
  // VideosView now expects a videoId to be provided by the caller. The view
  // fetches the Video via VideosController and then renders VidDetail with
  // the fetched Video.
  const VideosView({super.key, this.videoId});

  final int? videoId;

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available
    final ctrl = Get.put(VideosController());

    // Get videoId from route parameters if not provided directly
    final id = videoId ?? int.tryParse(Get.parameters['id'] ?? '') ?? 0;

    debugPrint(
      'VideosView.build: videoId param=$videoId, Get.parameters=${Get.parameters}, final id=$id',
    );

    if (id <= 0) {
      return const Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(75),
          child: AppBarWi(),
        ),
        bottomNavigationBar: BottomBarWi(),
        body: Center(child: Text('ID vidéo invalide')),
      );
    }

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: AppBarWi(),
      ),
      bottomNavigationBar: const BottomBarWi(),
      body: FutureBuilder<Video>(
        future: ctrl.fetchVideoById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erreur lors du chargement de la vidéo'),
            );
          }
          if (snapshot.hasData && snapshot.data!.id > 0) {
            final video = snapshot.data!;
            return VidDetail(video: video);
          }
          return const Center(child: Text('Vidéo introuvable'));
        },
      ),
    );
  }
}
