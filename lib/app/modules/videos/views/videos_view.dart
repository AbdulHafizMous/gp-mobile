// lib/app/modules/videos/views/videos_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/pages/vid_detail.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import '../controllers/videos_controller.dart';

class VideosView extends StatelessWidget {
  const VideosView({super.key, this.videoId});

  final int? videoId;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VideosController());
    final id = videoId ?? int.tryParse(Get.parameters['id'] ?? '') ?? 1;

    if (id <= 0) {
      return const Scaffold(
          body: Center(child: Text('ID vidéo invalide')));
    }

    return Scaffold(
      // backgroundColor: Colors.black,
      body: FutureBuilder<SpaceVideo>(
        future: ctrl.fetchVideoById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur'));
          }
          if (snapshot.hasData) {
            return VidDetail(video: snapshot.data!);
          }
          return const Center(child: Text('Vidéo introuvable'));
        },
      ),
    );
  }
}