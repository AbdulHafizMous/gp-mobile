// lib/app/modules/shop/controllers/shop_controller.dart

import 'dart:io';
import 'package:dio/dio.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:grand_public_v2/app/data/models/chat_models.dart';
import 'package:grand_public_v2/app/data/models/shop_models.dart';
import 'package:grand_public_v2/app/modules/social/views/chat_room_view.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class ShopController extends GetxController {
  // ── Catégories ──────────────────────────────────────────────────────────
  final categories = <ShopCategory>[].obs;
  final selectedCategoryId = Rxn<int>();

  // ── Feed (pagination par curseur) ──────────────────────────────────────
  final listings = <ShopListing>[].obs;
  final isLoadingFeed = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int? _cursor;
  final searchQuery = ''.obs;

  // ── Détail ──────────────────────────────────────────────────────────────
  final currentListing = Rxn<ShopListing>();
  final isLoadingDetail = false.obs;
  final comments = <ShopComment>[].obs;
  final isLoadingComments = false.obs;
  final isPostingComment = false.obs;
  final commentController = TextEditingController();

  // ── Mes annonces ──────────────────────────────────────────────────────
  final myListings = <ShopListing>[].obs;
  final isLoadingMyListings = false.obs;

  // ── Création ──────────────────────────────────────────────────────────
  final isSubmitting = false.obs;
  final isContacting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchFeed(reset: true);
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  CATÉGORIES
  // ══════════════════════════════════════════════════════════════════════
  Future<void> fetchCategories() async {
    try {
      final response = await RequestService().get('/shop/categories');
      final data = response.data['data'] as List<dynamic>;
      categories.value = data
          .map((e) => ShopCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchCategories error: $e');
    }
  }

  void selectCategory(int? categoryId) {
    if (selectedCategoryId.value == categoryId) return;
    selectedCategoryId.value = categoryId;
    fetchFeed(reset: true);
  }

  void search(String query) {
    searchQuery.value = query;
    fetchFeed(reset: true);
  }

  // ══════════════════════════════════════════════════════════════════════
  //  FEED — pagination par curseur (fluide même avec des milliers d'annonces)
  // ══════════════════════════════════════════════════════════════════════
  Future<void> fetchFeed({bool reset = false}) async {
    if (reset) {
      _cursor = null;
      hasMore.value = true;
      isLoadingFeed.value = true;
    }
    if (!hasMore.value && !reset) return;

    try {
      final response = await RequestService().get(
        '/shop/listings',
        queryParameters: {
          if (_cursor != null) 'cursor': _cursor,
          if (selectedCategoryId.value != null)
            'category_id': selectedCategoryId.value,
          if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final items = (data['listings'] as List<dynamic>)
          .map((e) => ShopListing.fromJson(e as Map<String, dynamic>))
          .toList();

      listings.value = reset ? items : [...listings, ...items];
      _cursor = data['next_cursor'] is int ? data['next_cursor'] : null;
      hasMore.value = data['has_more'] == true;
    } catch (e) {
      debugPrint('fetchFeed error: $e');
      ToastHelper.showToast(
        'Impossible de charger les annonces.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isLoadingFeed.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Appelé quand l'utilisateur approche de la fin de la liste (scroll infini).
  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoadingFeed.value || !hasMore.value) return;
    isLoadingMore.value = true;
    await fetchFeed();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  DÉTAIL
  // ══════════════════════════════════════════════════════════════════════
  Future<void> fetchListing(int id) async {
    isLoadingDetail.value = true;
    try {
      final response = await RequestService().get('/shop/listings/$id');
      currentListing.value = ShopListing.fromJson(response.data['data']);
      await fetchComments(id);
    } catch (e) {
      debugPrint('fetchListing error: $e');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> toggleLike(int listingId) async {
    final listing = currentListing.value;
    if (listing == null) return;
    final wasLiked = listing.isLiked;
    currentListing.value = listing.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked ? listing.likesCount - 1 : listing.likesCount + 1,
    );
    final idx = listings.indexWhere((l) => l.id == listingId);
    if (idx != -1) {
      listings[idx] = listings[idx].copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked
            ? listings[idx].likesCount - 1
            : listings[idx].likesCount + 1,
      );
    }
    try {
      await RequestService().post('/shop/listings/$listingId/like');
    } catch (e) {
      currentListing.value = listing; // rollback
      debugPrint('toggleLike error: $e');
    }
  }

  Future<void> fetchComments(int listingId) async {
    isLoadingComments.value = true;
    try {
      final response = await RequestService().get(
        '/shop/listings/$listingId/comments',
      );
      final data = response.data['data'] as List<dynamic>;
      comments.value = data
          .map((e) => ShopComment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchComments error: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> postComment(int listingId) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;
    isPostingComment.value = true;
    try {
      final response = await RequestService().post(
        '/shop/listings/$listingId/comments',
        data: {'content': text},
      );
      comments.insert(0, ShopComment.fromJson(response.data['data']));
      commentController.clear();
      if (currentListing.value != null) {
        currentListing.value = currentListing.value!.copyWith(
          commentsCount: currentListing.value!.commentsCount + 1,
        );
      }
    } catch (e) {
      ToastHelper.showToast(
        'Impossible de publier le commentaire.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      isPostingComment.value = false;
    }
  }

  /// Contacte le vendeur : réutilise le chat Social existant (une conversation
  /// privée par paire acheteur/vendeur), puis ouvre directement l'écran de chat.
  Future<void> contactSeller(BuildContext context, ShopListing listing) async {
    isContacting.value = true;
    try {
      final response = await RequestService().post(
        '/shop/listings/${listing.id}/contact',
      );
      final conv = PrivateConversation.fromJson(response.data['data']);
      Get.to(
        () => ChatRoomView(privateConv: conv),
        transition: Transition.rightToLeft,
      );
    } on DioException catch (e) {
      final message =
          e.response?.data['message']?.toString() ??
          'Impossible de contacter le vendeur pour le moment.';
      ToastHelper.showToast(
        message,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('contactSeller error: $e');
    } finally {
      isContacting.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  MES ANNONCES
  // ══════════════════════════════════════════════════════════════════════
  Future<void> fetchMyListings() async {
    isLoadingMyListings.value = true;
    try {
      final response = await RequestService().get('/shop/my-listings');
      final data = response.data['data'] as Map<String, dynamic>;
      myListings.value = (data['listings'] as List<dynamic>)
          .map((e) => ShopListing.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchMyListings error: $e');
    } finally {
      isLoadingMyListings.value = false;
    }
  }

  Future<void> updateListingStatus(int listingId, String status) async {
    try {
      await RequestService().patch(
        '/shop/listings/$listingId/status',
        data: {'status': status},
      );
      await fetchMyListings();
    } catch (e) {
      debugPrint('updateListingStatus error: $e');
    }
  }

  Future<void> deleteListing(int listingId) async {
    try {
      await RequestService().delete('/shop/listings/$listingId');
      myListings.removeWhere((l) => l.id == listingId);
    } catch (e) {
      ToastHelper.showToast(
        "Impossible de supprimer l'annonce.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  CRÉATION D'ANNONCE — max 3 photos + 1 vidéo (15 Mo)
  // ══════════════════════════════════════════════════════════════════════
  Future<bool> createListing({
    required int categoryId,
    required String title,
    required String description,
    double? price,
    String? city,
    required List<File> photos,
    File? video,
  }) async {
    if (photos.length > 3) {
      ToastHelper.showToast(
        '3 photos maximum par annonce.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
    if (video != null) {
      final sizeInMb = await video.length() / (1024 * 1024);
      if (sizeInMb > 15) {
        ToastHelper.showToast(
          'La vidéo ne doit pas dépasser 15 Mo.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }
    }

    isSubmitting.value = true;
    try {
      final formData = FormData.fromMap({
        'shop_category_id': categoryId,
        'title': title,
        'description': description,
        'price': ?price,
        if (city != null && city.isNotEmpty) 'city': city,
        'photos[]': [
          for (final photo in photos)
            await MultipartFile.fromFile(
              photo.path,
              filename: photo.path.split('/').last,
            ),
        ],
        if (video != null)
          'video': await MultipartFile.fromFile(
            video.path,
            filename: video.path.split('/').last,
          ),
      });

      debugPrint(
        'createListing formData: ${formData.fields} + ${formData.files}',
      );

      var response = await RequestService().post(
        '/shop/listings',
        data: formData,
      );

      debugPrint('createListing response: ${response.data}');

      ToastHelper.showToast(
        'Annonce publiée !',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await fetchFeed(reset: true);
      return true;
    } on DioException catch (e) {
      final message =
          e.response?.data['message']?.toString() ??
          "Impossible de publier l'annonce.";
      debugPrint('createListing DioException: ${e.response?.data}');
      ToastHelper.showToast(
        message,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    } catch (e) {
      debugPrint('createListing error: $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
