// lib/app/data/models/brand_takeover_model.dart
//
// "FullAppAd" — quand un sponsor (ex: MTN) paie pour rebrander toute
// l'application pendant une période donnée : logo, couleurs, motif de fond.
// Voir BrandTakeoverService pour la récupération + application globale.

import 'package:flutter/material.dart';

class BrandTakeover {
  final int id;
  final String advertiserName;
  final Color? primaryColor;
  final Color? secondaryColor;
  final String? logoUrl;
  final String? backgroundUrl;
  final DateTime? endsAt;

  const BrandTakeover({
    required this.id,
    required this.advertiserName,
    this.primaryColor,
    this.secondaryColor,
    this.logoUrl,
    this.backgroundUrl,
    this.endsAt,
  });

  factory BrandTakeover.fromJson(Map<String, dynamic> json) {
    return BrandTakeover(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      advertiserName: json['advertiser_name']?.toString() ?? '',
      primaryColor: _colorFromHex(json['brand_primary_color']?.toString()),
      secondaryColor: _colorFromHex(json['brand_secondary_color']?.toString()),
      logoUrl: json['brand_logo_url']?.toString(),
      backgroundUrl: json['brand_background_url']?.toString(),
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at'].toString()) : null,
    );
  }

  static Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16);
    return value != null ? Color(value) : null;
  }
}
