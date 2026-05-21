import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/club/controllers/club_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PartnerScannerView extends StatefulWidget {
  const PartnerScannerView({super.key});

  @override
  State<PartnerScannerView> createState() => _PartnerScannerViewState();
}

class _PartnerScannerViewState extends State<PartnerScannerView> {
  final ctrl = Get.put(ClubController());
  final _scanCtrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner un code QR'),
        actions: [
          IconButton(
            onPressed: () => _scanCtrl.toggleTorch(),
            icon: const Icon(Icons.flash_on_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scanCtrl,
            onDetect: (capture) async {
              if (_scanned) return;
              final code = capture.barcodes.first.rawValue;
              if (code == null) return;

              setState(() => _scanned = true);
              _scanCtrl.stop();

              final result = await ctrl.validateQrCode(code);

              if (result != null && mounted) {
                _showSuccessDialog(result);
              } else {
                setState(() => _scanned = false);
                _scanCtrl.start();
              }
            },
          ),

          // Overlay viseur
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: GPTheme.primaryColor, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Texte guide
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: const Text(
              'Placez le code QR dans le cadre',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade600, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Promotion validée !',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '${result['user_name']} a bénéficié de :\n"${result['promo_title']}"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() => _scanned = false);
                    _scanCtrl.start();
                  },
                  child: const Text('Scanner un autre code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}