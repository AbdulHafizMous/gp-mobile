import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grand_public_v2/app/data/models/promotion.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

/// Dessine les marqueurs de la carte du Club (pin or Grandpublic + logo du partenaire + pastille d'offres)
/// et le marqueur de l'utilisateur (point rouge pulsé, volontairement différent des pins).
class ClubMarkerFactory {
  ClubMarkerFactory._();

  static const double _ratio = 3.0;
  static final Map<String, BitmapDescriptor> _cache = {};
  static final Map<String, ui.Image?> _logos = {};

  static Future<ui.Image?> _logo(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (_logos.containsKey(url)) return _logos[url];
    try {
      final f = await DefaultCacheManager().getSingleFile(url);
      final codec = await ui.instantiateImageCodec(await f.readAsBytes(), targetWidth: 160);
      final img = (await codec.getNextFrame()).image;
      _logos[url] = img;
      return img;
    } catch (_) {
      _logos[url] = null;
      return null;
    }
  }

  static Future<BitmapDescriptor> partner(PartnerFiche p, {bool selected = false}) async {
    final key = 'p${p.id}_${p.offers.length}_${p.logoUrl}_$selected';
    final hit = _cache[key];
    if (hit != null) return hit;
    final logo = await _logo(p.logoUrl);
    const w = 64.0, h = 80.0;
    final scale = selected ? 1.18 : 1.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(_ratio * scale);
    final cx = w / 2, cy = 30.0, r = 26.0;

    // ombre portée
    c.drawOval(Rect.fromCenter(center: Offset(cx, h - 3), width: 22, height: 7), Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // goutte
    final pin = Path()
      ..moveTo(cx, h - 2)
      ..cubicTo(cx - 8, h - 14, cx - r, cy + 16, cx - r, cy)
      ..arcToPoint(Offset(cx + r, cy), radius: Radius.circular(r), clockwise: true)
      ..cubicTo(cx + r, cy + 16, cx + 8, h - 14, cx, h - 2)
      ..close();
    c.drawPath(pin, Paint()..shader = ui.Gradient.linear(Offset(cx, 0), Offset(cx, h), [ GPTheme.clubColor, const Color(0xFFE0A800)]));
    c.drawPath(pin, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = const Color(0xFF1A1A1A));

    // disque blanc + logo / icône
    c.drawCircle(Offset(cx, cy), 19.5, Paint()..color = Colors.white);
    if (logo != null) {
      c.save();
      c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: 17.5)));
      c.drawImageRect(logo, Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()), Rect.fromCircle(center: Offset(cx, cy), radius: 17.5), Paint()..filterQuality = FilterQuality.high);
      c.restore();
    } else {
      final ic = Icons.storefront_rounded;
      final tp = TextPainter(
        text: TextSpan(text: String.fromCharCode(ic.codePoint), style: TextStyle(fontSize: 26, fontFamily: ic.fontFamily, package: ic.fontPackage, color: const Color(0xFF1A1A1A))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }

    // pastille nombre d'offres
    if (p.offers.isNotEmpty) {
      final bc = Offset(cx + 20, cy - 20);
      c.drawCircle(bc, 10, Paint()..color = Colors.white);
      c.drawCircle(bc, 8.4, Paint()..color = GPTheme.primaryColor);
      final tp = TextPainter(
        text: TextSpan(text: '${math.min(p.offers.length, 9)}', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, bc - Offset(tp.width / 2, tp.height / 2));
    }
    final img = await rec.endRecording().toImage((w * _ratio * scale).round(), (h * _ratio * scale).round());
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    final d = BitmapDescriptor.bytes(bytes, imagePixelRatio: _ratio);
    return _cache[key] = d;
  }

  /// Ma position : point rouge Grandpublic avec halo et anneau blanc.
  static Future<BitmapDescriptor> me() async {
    const key = 'me';
    final hit = _cache[key];
    if (hit != null) return hit;
    const s = 72.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(_ratio);
    const ctr = Offset(s / 2, s / 2);
    c.drawCircle(ctr, 34, Paint()..color = GPTheme.primaryColor.withValues(alpha: 0.16));
    c.drawCircle(ctr, 24, Paint()..color = GPTheme.primaryColor.withValues(alpha: 0.22));
    c.drawCircle(ctr, 14, Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    c.drawCircle(ctr, 13, Paint()..color = Colors.white);
    c.drawCircle(ctr, 9.5, Paint()..color = GPTheme.primaryColor);
    c.drawCircle(ctr, 3.2, Paint()..color = Colors.white);
    final img = await rec.endRecording().toImage((s * _ratio).round(), (s * _ratio).round());
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return _cache[key] = BitmapDescriptor.bytes(bytes, imagePixelRatio: _ratio);
  }

  /// Drapeau d'arrivée pour l'itinéraire.
  static Future<BitmapDescriptor> flag() async {
    const key = 'flag';
    final hit = _cache[key];
    if (hit != null) return hit;
    const w = 44.0, h = 56.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(_ratio);
    c.drawLine(const Offset(12, 6), const Offset(12, h - 4), Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = 3..strokeCap = StrokeCap.round);
    final f = Path()..moveTo(13, 7)..lineTo(38, 14)..lineTo(13, 24)..close();
    c.drawPath(f, Paint()..color = GPTheme.primaryColor);
    c.drawPath(f, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0xFF1A1A1A));
    final img = await rec.endRecording().toImage((w * _ratio).round(), (h * _ratio).round());
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    return _cache[key] = BitmapDescriptor.bytes(bytes, imagePixelRatio: _ratio);
  }
}
