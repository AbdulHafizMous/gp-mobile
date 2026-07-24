// lib/app/modules/videos/controllers/videos_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kkiapay_flutter_sdk/kkiapay_flutter_sdk.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:grand_public_v2/app/data/models/space_model.dart';
import 'package:grand_public_v2/app/data/models/video_comment.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/services/web_account_link_service.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';

class VideosController extends GetxController {
  // ── État principal ─────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final isVideoLoading = false.obs;
  final currentVideo = Rxn<SpaceVideo>();

  // ── Commentaires ───────────────────────────────────────────────────────────
  final comments = <VideoComment>[].obs;
  final isLoadingComments = false.obs;
  final isPostingComment = false.obs;
  final commentController = TextEditingController();
  final replyingTo = Rxn<VideoComment>();

  // ── Player ─────────────────────────────────────────────────────────────────
  final isPlaying = false.obs;
  final isMuted = false.obs;
  final volume = 1.0.obs;
  final playbackSpeed = 1.0.obs;
  final isFullscreen = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final isBuffering = false.obs;

  // ── PPV ────────────────────────────────────────────────────────────────────
  final isPurchasing = false.obs;
  final _uuid = const Uuid();
  final _storage = GetStorage();

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FETCH VIDEO
  // ══════════════════════════════════════════════════════════════════════════

  Future<SpaceVideo> fetchVideoById(int id) async {
    isVideoLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 800));
        final video = _mockVideos().firstWhere(
          (v) => v.id == id,
          orElse: () => _mockVideos().first,
        );
        currentVideo.value = video;
        return video;
      }

      final response = await RequestService().get('/videos/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final video = SpaceVideo.fromJson(data);
        currentVideo.value = video;
        return video;
      }
    } on DioException catch (e) {
      debugPrint('fetchVideoById DioError: ${e.message}');
    } catch (e) {
      debugPrint('fetchVideoById Error: $e');
    } finally {
      isVideoLoading.value = false;
    }

    final fallback = _mockVideos().first;
    currentVideo.value = fallback;
    return fallback;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LIKE / DISLIKE / SAVE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> toggleLike(int videoId) async {
    final video = currentVideo.value;
    if (video == null) return;
    final wasLiked = video.isLiked;
    currentVideo.value = video.copyWith(
      isLiked: !wasLiked,
      isDisliked: false,
      likesCount: wasLiked ? video.likesCount - 1 : video.likesCount + 1,
      dislikesCount:
          video.isDisliked ? video.dislikesCount - 1 : video.dislikesCount,
    );
    try {
      if (!useMock) {
        await RequestService().post('/videos/$videoId/like');
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      currentVideo.value = video;
    }
  }

  Future<void> toggleDislike(int videoId) async {
    final video = currentVideo.value;
    if (video == null) return;
    final wasDisliked = video.isDisliked;
    currentVideo.value = video.copyWith(
      isDisliked: !wasDisliked,
      isLiked: false,
      dislikesCount:
          wasDisliked ? video.dislikesCount - 1 : video.dislikesCount + 1,
      likesCount: video.isLiked ? video.likesCount - 1 : video.likesCount,
    );
    try {
      if (!useMock) {
        await RequestService().post('/videos/$videoId/dislike');
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      currentVideo.value = video;
    }
  }

  Future<void> toggleSave(int videoId) async {
    final video = currentVideo.value;
    if (video == null) return;
    currentVideo.value = video.copyWith(isSaved: !video.isSaved);
    try {
      if (!useMock) {
        await RequestService().post('/videos/$videoId/save');
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      currentVideo.value = video;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  COMMENTAIRES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchComments(int videoId) async {
    isLoadingComments.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        comments.value = _mockComments(videoId);
        return;
      }
      final response =
          await RequestService().get('/videos/$videoId/comments');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        comments.value = data
            .map((e) => VideoComment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('fetchComments error: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> postComment(int videoId) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;
    isPostingComment.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        final newComment = VideoComment(
          id: DateTime.now().millisecondsSinceEpoch,
          videoId: videoId,
          userId: 1,
          userName: 'Moi',
          content: text,
          createdAt: 'À l\'instant',
        );
        if (replyingTo.value != null) {
          final parentIdx =
              comments.indexWhere((c) => c.id == replyingTo.value!.id);
          if (parentIdx != -1) {
            final parent = comments[parentIdx];
            comments[parentIdx] = VideoComment(
              id: parent.id,
              videoId: parent.videoId,
              userId: parent.userId,
              userName: parent.userName,
              userAvatar: parent.userAvatar,
              content: parent.content,
              likesCount: parent.likesCount,
              isLiked: parent.isLiked,
              createdAt: parent.createdAt,
              replies: [...parent.replies, newComment],
            );
          }
        } else {
          comments.insert(0, newComment);
          if (currentVideo.value != null) {
            currentVideo.value = currentVideo.value!
                .copyWith(commentsCount: currentVideo.value!.commentsCount + 1);
          }
        }
        commentController.clear();
        replyingTo.value = null;
        return;
      }
      final body = {
        'content': text,
        if (replyingTo.value != null) 'parent_id': replyingTo.value!.id,
      };
      final response =
          await RequestService().post('/videos/$videoId/comments', data: body);
      if (response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>;
        comments.insert(0, VideoComment.fromJson(data));
        commentController.clear();
        replyingTo.value = null;
        if (currentVideo.value != null) {
          currentVideo.value = currentVideo.value!
              .copyWith(commentsCount: currentVideo.value!.commentsCount + 1);
        }
      }
    } catch (e) {
      ToastHelper.showToast('Impossible de publier le commentaire.',
          backgroundColor: Colors.red, textColor: Colors.white);
    } finally {
      isPostingComment.value = false;
    }
  }

  Future<void> toggleCommentLike(int commentId) async {
    final idx = comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final comment = comments[idx];
    comments[idx] = comment.copyWith(
      isLiked: !comment.isLiked,
      likesCount:
          comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
    );
    try {
      if (!useMock) await RequestService().post('/comments/$commentId/like');
    } catch (_) {
      comments[idx] = comment;
    }
  }

  void setReplyingTo(VideoComment? comment) {
    replyingTo.value = comment;
    if (comment != null) commentController.text = '@${comment.userName} ';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  POINT D'ENTRÉE UNIQUE — appelé depuis les vues (vid_detail.dart)
  //  iOS  -> RevenueCat / StoreKit (obligatoire, Guideline 3.1.1)
  //  Autres plateformes -> Kkiapay natif OU redirection web, selon
  //  `useExternalPaywall` (lib/app/constants/index.dart)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> handlePayPerView({
    required BuildContext context,
    required SpaceVideo video,
    required VoidCallback onPurchaseSuccess,
  }) {
    if (!kIsWeb && Platform.isIOS) {
      return _purchaseVideoWithRevenueCat(
        context: context,
        video: video,
        onSuccess: onPurchaseSuccess,
      );
    }
    if (useExternalPaywall) {
      return handlePayPerViewOnWeb(
        context: context,
        video: video,
        onPurchaseSuccess: onPurchaseSuccess,
      );
    }
    return _purchaseVideoWithKkiapay(
      context: context,
      video: video,
      onSuccess: onPurchaseSuccess,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PAY-PER-VIEW — RevenueCat (Apple StoreKit)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _purchaseVideoWithRevenueCat({
    required BuildContext context,
    required SpaceVideo video,
    required VoidCallback onSuccess,
  }) async {
    final appleProductId = video.appleProductId;
    if (appleProductId == null || appleProductId.isEmpty) {
      _showPurchaseFailedDialog(
        context,
        'Cette vidéo n\'est pas encore disponible à l\'achat sur l\'App Store.',
      );
      return;
    }

    isPurchasing.value = true;
    try {
      final products = await Purchases.getProducts([appleProductId]);
      if (products.isEmpty) {
        _showPurchaseFailedDialog(context, 'Produit introuvable sur l\'App Store.');
        return;
      }

      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(products.first),
      );
      final transactionId = result.storeTransaction.transactionIdentifier;

      await _doPurchaseVideoBackend(
        context: context,
        video: video,
        transactionId: transactionId,
        metadata: {
          'gateway': 'apple_storekit_revenuecat',
          'apple_product_id': appleProductId,
        },
        onSuccess: onSuccess,
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _showPurchaseFailedDialog(
          context,
          e.message ?? 'Le paiement Apple a échoué. Réessayez.',
        );
      }
    } catch (e) {
      debugPrint('RevenueCat PPV error: $e');
      _showPurchaseFailedDialog(context, 'Une erreur inattendue est survenue.');
    } finally {
      isPurchasing.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PAY-PER-VIEW — Kkiapay natif (Android / non-iOS quand useExternalPaywall=false)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _purchaseVideoWithKkiapay({
    required BuildContext context,
    required SpaceVideo video,
    required VoidCallback onSuccess,
  }) async {
    if (video.ppvPrice == null) return;

    final kkiapay = KKiaPay(
      callback: (dynamic response, BuildContext ctx) async {
        final status = response['status']?.toString() ?? '';
        try {
          switch (status) {
            case 'PAYMENT_CANCELLED':
              try { Get.back(); } catch (_) {}
              break;
            case 'PAYMENT_SUCCESS':
              try { Get.back(); } catch (_) {}
              final transactionId =
                  response['transactionId']?.toString() ?? '';
              await _doPurchaseVideoBackend(
                context: context,
                video: video,
                transactionId: transactionId,
                metadata: {'kkiapay_response': response},
                onSuccess: onSuccess,
              );
              break;
            default:
              debugPrint('KKiaPay PPV EVENT: $status');
          }
        } catch (e) {
          debugPrint('KKiaPay PPV callback error: $e');
        }
      },
      amount: video.ppvPrice!.toInt(),
      apikey: FEEX_API_KEY,
      sandbox: true,
      data: jsonEncode({
        'trans_key': _uuid.v4(),
        'video_id': video.id,
        'type': 'ppv',
      }),
      phone: _storage.read('phone') ?? '',
      name: _storage.read('username') ?? '',
      reason: 'Accès vidéo : ${video.title}',
      email: _storage.read('email') ?? '',
      countries: const ['BJ'],
    );

    Get.to(() => kkiapay);
  }

  Future<void> _doPurchaseVideoBackend({
    required BuildContext context,
    required SpaceVideo video,
    required String transactionId,
    Map<String, dynamic>? metadata,
    required VoidCallback onSuccess,
  }) async {
    isPurchasing.value = true;
    try {
      final response = await RequestService().post(
        '/videos/${video.id}/purchase',
        data: {
          'transaction_id': transactionId,
          if (metadata != null) 'metadata': metadata,
        },
      );

      if (response.statusCode == 200) {
        currentVideo.value =
            currentVideo.value?.copyWith(canRead: true) ?? video.copyWith(canRead: true);
        if (context.mounted) {
          _showPurchaseSuccessDialog(context, video);
          onSuccess();
        }
      } else {
        final message =
            response.data['message']?.toString() ?? 'Une erreur est survenue.';
        if (context.mounted) _showPurchaseFailedDialog(context, message);
      }
    } on DioException catch (e) {
      final reason = e.response?.data?['message']?.toString() ??
          e.message ??
          'Erreur réseau';
      if (context.mounted) _showPurchaseFailedDialog(context, reason);
    } catch (e) {
      if (context.mounted) {
        _showPurchaseFailedDialog(context, 'Une erreur inattendue est survenue.');
      }
    } finally {
      isPurchasing.value = false;
    }
  }

  void _showPurchaseSuccessDialog(BuildContext context, SpaceVideo video) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Accès débloqué !',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Vous pouvez maintenant regarder "${video.title}".',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Regarder maintenant'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseFailedDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.cancel_rounded,
                  color: Colors.red.shade600, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Paiement échoué',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(reason,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Réessayer plus tard'),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PAY-PER-VIEW — redirection vers le site web pour le paiement
  //  (Apple Guideline 3.1.1 : plus de paiement in-app pour du contenu digital)
  // ══════════════════════════════════════════════════════════════════════════

  /// Redirige vers le site pour payer l'accès à une vidéo à l'unité.
  /// L'utilisateur est automatiquement connecté sur le site via un lien à
  /// usage unique. Le déblocage effectif se fait côté serveur ; on rafraîchit
  /// simplement l'état localement au retour (best effort).
  Future<void> handlePayPerViewOnWeb({
    required BuildContext context,
    required SpaceVideo video,
    required VoidCallback onPurchaseSuccess,
  }) async {
    if (video.ppvPrice == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.open_in_new_rounded),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Paiement sur le site',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Pour débloquer "${video.title}" (${video.ppvPrice!.toStringAsFixed(0)} FCFA), '
          'vous allez être redirigé(e) vers notre site pour finaliser le paiement en '
          'toute sécurité. Vous serez automatiquement connecté(e).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isPurchasing.value = true;
    try {
      await WebAccountLinkService.openWebAccount(
        intent: 'media',
        mediaId: video.id,
      );
    } finally {
      isPurchasing.value = false;
      // Rafraîchit au mieux l'état d'accès de la vidéo (utile si l'achat
      // avait déjà été fait récemment sur le site).
      unawaited(_refreshCurrentVideoAccess(video, onPurchaseSuccess));
    }
  }

  Future<void> _refreshCurrentVideoAccess(
    SpaceVideo video,
    VoidCallback onPurchaseSuccess,
  ) async {
    try {
      if (useMock) return;
      final response = await RequestService().get('/videos/${video.id}');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final refreshed = SpaceVideo.fromJson(data);
        currentVideo.value = refreshed;
        if (refreshed.canRead) onPurchaseSuccess();
      }
    } catch (e) {
      debugPrint('_refreshCurrentVideoAccess error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOCKS
  // ══════════════════════════════════════════════════════════════════════════

  List<SpaceVideo> _mockVideos() {
    final rand = Random();
    // IDs YouTube réels pour le player
    final ytIds = [
      '3shs6DYjXtY',
      'R_HVJUUtNMc',
      'dQw4w9WgXcQ',
      '9bZkp7q19f0',
      'kJQP7kiw5Fk',
    ];

    return [
      SpaceVideo(
        id: 1,
        title:
            'WELOVeya Dadju & Gims met le feu à la place de l\'amazone...Edition 2024',
        description:
            'Un concert exceptionnel qui a réuni des milliers de fans. '
            'Dadju et Gims ont offert une performance mémorable à Cotonou.',
        thumbnail: 'https://img.youtube.com/vi/3shs6DYjXtY/maxresdefault.jpg',
        youtubeId: "3shs6DYjXtY",
        // videoUrl contient l'ID YouTube — le player l'extrait
        videoUrl: 'https://www.youtube.com/watch?v=3shs6DYjXtY',
        views: 213000,
        likesCount: 12800,
        dislikesCount: 10,
        commentsCount: 19,
        publicationDate: 'Il y a trois jours',
        isPremium: true,
        ppvPrice: 500,
        canRead: true,
        isLiked: false,
        isSaved: false,
      ),
      SpaceVideo(
        id: 2,
        title: 'Grand Public Event – Exclusivité Premium',
        description: 'Contenu réservé aux abonnés premium.',
        thumbnail: 'https://img.youtube.com/vi/R_HVJUUtNMc/maxresdefault.jpg',
        videoUrl: 'https://www.youtube.com/watch?v=R_HVJUUtNMc',
          youtubeId: "3shs6DYjXtY",
        views: 45000,
        likesCount: 3200,
        dislikesCount: 5,
        commentsCount: 7,
        publicationDate: 'Il y a une semaine',
        isPremium: true,
        ppvPrice: 1000,
        canRead: false, // verrouillé pour tester le dialogue
        isLiked: false,
        isSaved: false,
      ),
      ...List.generate(48, (i) {
        final isPrem = rand.nextBool();
        final ytId = ytIds[rand.nextInt(ytIds.length)];
        return SpaceVideo(
          id: i + 3,
          title: 'Vidéo Grand Public #${i + 3}',
          description: 'Description de la vidéo ${i + 3}',
          thumbnail: 'https://img.youtube.com/vi/$ytId/maxresdefault.jpg',
          videoUrl: 'https://www.youtube.com/watch?v=$ytId',
          youtubeId: ytId,
          views: rand.nextInt(100000),
          likesCount: rand.nextInt(5000),
          dislikesCount: rand.nextInt(50),
          commentsCount: rand.nextInt(200),
          publicationDate: 'Il y a ${rand.nextInt(30) + 1} jours',
          isPremium: isPrem,
          ppvPrice: isPrem ? (rand.nextInt(5) + 1) * 200.0 : null,
          canRead: !isPrem || rand.nextBool(),
        );
      }),
    ];
  }

  List<VideoComment> _mockComments(int videoId) {
    return [
      VideoComment(
        id: 1,
        videoId: videoId,
        userId: 10,
        userName: 'Hans DOSSOU',
        content:
            'Une histoire touchante et pleine d\'inspiration ! Son parcours de vie m\'a profondément émue.',
        likesCount: 23,
        isLiked: false,
        createdAt: 'Il y a 5 minutes',
        replies: [
          VideoComment(
            id: 11,
            videoId: videoId,
            userId: 10,
            userName: 'Hans DOSSOU',
            content: 'c\'est vraiment top wsh',
            likesCount: 23,
            isLiked: false,
            createdAt: 'Il y a 5 minutes',
          ),
        ],
      ),
      VideoComment(
        id: 2,
        videoId: videoId,
        userId: 11,
        userName: 'Aïcha Koffi',
        content: 'Incroyable ! Merci Grand Public pour ce contenu de qualité.',
        likesCount: 15,
        isLiked: true,
        createdAt: 'Il y a 12 minutes',
      ),
      VideoComment(
        id: 3,
        videoId: videoId,
        userId: 12,
        userName: 'Kofi Mensah',
        content: 'J\'attends la prochaine édition avec impatience !',
        likesCount: 8,
        isLiked: false,
        createdAt: 'Il y a 30 minutes',
      ),
      VideoComment(
        id: 4,
        videoId: videoId,
        userId: 13,
        userName: 'Fatou Diallo',
        content:
            'Une histoire touchante et pleine d\'inspiration ! Son parcours de vie m\'a profondément émue.',
        likesCount: 23,
        isLiked: false,
        createdAt: 'Il y a 1 heure',
      ),
      VideoComment(
        id: 5,
        videoId: videoId,
        userId: 14,
        userName: 'Moussa Traoré',
        content:
            'Une histoire touchante et pleine d\'inspiration ! Son parcours de vie m\'a profondément émue.',
        likesCount: 23,
        isLiked: false,
        createdAt: 'Il y a 2 heures',
      ),
    ];
  }
}