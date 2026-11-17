import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

/// Enregistre des images / une vidéo dans la galerie du téléphone (album « Grandpublic »).
/// À n'appeler que si le créateur a autorisé le téléchargement (`allow_download`).
class MediaDownloader {
  static final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(minutes: 5)));
  static const _album = 'Grandpublic';

  static Future<bool> _ensureAccess() async {
    if (await Gal.hasAccess(toAlbum: true)) return true;
    return Gal.requestAccess(toAlbum: true);
  }

  static void _toast(String m, {bool error = false}) {
    Get.rawSnackbar(message: m, backgroundColor: error ? Colors.red.shade700 : Colors.black87, duration: const Duration(seconds: 3), margin: const EdgeInsets.all(12), borderRadius: 12, snackPosition: SnackPosition.BOTTOM);
  }

  static String _ext(String url, String fallback) {
    final p = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    final m = RegExp(r'\.(jpg|jpeg|png|webp|gif|mp4|mov|m4v)$').firstMatch(p);
    return m?.group(1) ?? fallback;
  }

  /// Retourne le nombre d'images enregistrées.
  static Future<int> saveImages(List<String> urls) async {
    if (urls.isEmpty) return 0;
    if (!await _ensureAccess()) {
      _toast("Autorisez l'accès aux photos pour enregistrer.", error: true);
      return 0;
    }
    final dir = await getTemporaryDirectory();
    var ok = 0;
    for (var i = 0; i < urls.length; i++) {
      try {
        final path = '${dir.path}/gp_${DateTime.now().millisecondsSinceEpoch}_$i.${_ext(urls[i], 'jpg')}';
        await _dio.download(urls[i], path);
        await Gal.putImage(path, album: _album);
        File(path).delete().ignore();
        ok++;
      } catch (e) {
        debugPrint('saveImages: $e');
      }
    }
    _toast(ok > 0 ? (ok == 1 ? 'Image enregistrée dans la galerie.' : '$ok images enregistrées dans la galerie.') : "Téléchargement impossible pour le moment.", error: ok == 0);
    return ok;
  }

  static Future<bool> saveVideo(String url) async {
    if (!await _ensureAccess()) {
      _toast("Autorisez l'accès aux photos pour enregistrer.", error: true);
      return false;
    }
    _toast('Téléchargement de la vidéo…');
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/gp_${DateTime.now().millisecondsSinceEpoch}.${_ext(url, 'mp4')}';
      await _dio.download(url, path);
      await Gal.putVideo(path, album: _album);
      File(path).delete().ignore();
      _toast('Vidéo enregistrée dans la galerie.');
      return true;
    } catch (e) {
      debugPrint('saveVideo: $e');
      _toast('Téléchargement impossible pour le moment.', error: true);
      return false;
    }
  }
}
