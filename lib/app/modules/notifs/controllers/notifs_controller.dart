import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:grand_public_v2/app/data/mocks/notif_mock.dart';
import 'package:grand_public_v2/app/data/models/notification.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';

class NotifsPageController extends GetxController {
  //TODO: Implement SearchController

  final notifications = <CustomNotification>[].obs;

  //
  // Notifications
  //
  Future<List<CustomNotification>> fetchNotifications() async {
    try {
      if (!useMock) {
        // Génération de fausses données
        final mockData = List.generate(50, (index) {
          return CustomNotification(
            title: "${mockTitles[index % mockTitles.length]} #${index + 1}",
            description: mockDescriptions[index % mockDescriptions.length],
          );
        });

        debugPrint("MOCK notifications: ${mockData.length}");
        notifications.value = mockData;
        return mockData;
      }

      // API réelle
      final response = await RequestService().get('/notifications');

      notifications.value = (response.data["data"] as List)
          .map((e) => CustomNotification.fromJson(e))
          .toList();

      debugPrint("API notifications: ${notifications.length}");
      return notifications;
    } catch (e) {
      debugPrint(e.toString());
    }

    return [];
  }
}
