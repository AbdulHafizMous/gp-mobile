import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/data/models/video.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class VideosController extends GetxController {
  // Simple controller to fetch a single Video for the VideosView -> VidDetail flow.
  final isLoading = false.obs;

  Future<Video> fetchVideoById(int id) async {
    isLoading.value = true;
    try {
      final response = await RequestService().get('/videos/$id');
      if (response.statusCode == 200) {
        final data = response.data["data"];
        if (data != null) {
          return Video.fromJson(data);
        }
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint(
          'Error fetching video: ${e.response?.statusCode} ${e.response?.statusMessage}',
        );
        await ToastHelper.showToast(
          'Server error: ${e.response?.statusCode}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        debugPrint('Error fetching video: ${e.message}');
        await ToastHelper.showToast(
          'Error: ${e.message}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Unexpected error fetching video: $e');
    } finally {
      isLoading.value = false;
    }

    return Video.empty();
  }
}
