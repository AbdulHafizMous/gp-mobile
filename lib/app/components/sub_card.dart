import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:grand_public_v2/app/constants/index.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/models/subscription.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:kkiapay_flutter_sdk/kkiapay_flutter_sdk.dart';

class SubCard extends StatefulWidget {
  const SubCard({super.key, required this.subscription});

  final Subscription subscription;
  @override
  State<SubCard> createState() => _SubCardState();
}

class _SubCardState extends State<SubCard> {
  var uuid = const Uuid();


  Future<void> _fetchAndStoreUser() async {
    try {
      final userResp = await RequestService().get('/auth/me');
      if (userResp.statusCode == 200 && userResp.data is Map) {
        debugPrint("data --- ${userResp.data}");
        final data = userResp.data['data']['user'] as Map;
        GetStorage().write('username', data['name']);
        GetStorage().write('email', data['email']);

        // final rawHas = data['has_active_subscriptions'];
        // bool normalized = false;
        // if (rawHas is bool) {
        //   normalized = rawHas;
        // } else if (rawHas is num) {
        //   normalized = rawHas != 0;
        // } else if (rawHas is String) {
        //   normalized = ['1', 'true', 'yes'].contains(rawHas.toLowerCase());
        // }
        // GetStorage().write('has_active_subscriptions', normalized);
      }
    } catch (e) {
      debugPrint('Error fetching user after verify: $e');
    }
  }

  // `KKiaPay` will be instantiated on demand in `onPressed` so we can
  // provide subscription-specific values (amount, data, trans_key, etc.).

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: 300,
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset('assets/images/logo.png', width: 50),
                Text(
                  widget.subscription.duration,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.subscription.price}-XOF',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subscription.shortDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Build a fresh KKiaPay instance with subscription data.
                    final kkiapay = KKiaPay(
                      // make the callback async so we can perform follow-up API calls
                      callback: (dynamic response, BuildContext ctx) async {
                        debugPrint('kkiapay callback: $response');
                        final status = response['status']?.toString() ?? '';
                        try {
                          switch (status) {
                            case 'PAYMENT_CANCELLED':
                              // close the payment view
                              try {
                                Get.back();
                              } catch (_) {}
                              debugPrint('PAYMENT_CANCELLED');
                              break;
                            case 'PAYMENT_INIT':
                              debugPrint('PAYMENT_INIT');
                              break;
                            case 'PENDING_PAYMENT':
                              debugPrint('PENDING_PAYMENT');
                              break;
                            case 'PAYMENT_SUCCESS':
                              // close payment view then navigate to success screen
                              try {
                                Get.back();
                              } catch (_) {}
                              // After a successful payment we must refresh the user
                              // info and store `has_active_subscriptions` in GetStorage.
                              try {
                                await _fetchAndStoreUser();
                              } catch (e, st) {
                                debugPrint(
                                  'Error fetching user after payment: $e\n$st',
                                );
                              }
                              try {
                                Get.toNamed(
                                  '/pay-suc',
                                  arguments: {
                                    'amount':
                                        response['requestData']?['amount'],
                                    'transactionId': response['transactionId'],
                                  },
                                );
                              } catch (_) {}
                              break;
                            default:
                              debugPrint('UNKNOWN_EVENT');
                              break;
                          }
                        } catch (e, st) {
                          debugPrint(
                            'Error handling kkiapay callback: $e\n$st',
                          );
                        }
                      },
                      amount: widget.subscription.price,
                      apikey: FEEX_API_KEY,
                      sandbox: true,
                      // include a trans_key and callback_info in data for backend tracing
                      data: jsonEncode({
                        'trans_key': uuid.v4(),
                        'subscription_id': widget.subscription.id,
                      }),
                      phone: GetStorage().read('phone') ?? '',
                      name: GetStorage().read('username') ?? '',
                      reason: widget.subscription.name,
                      email: GetStorage().read('email') ?? '',
                      countries: const ['BJ'],
                    );

                    // Use GetX navigation to open the payment widget.
                    Get.to(() => kkiapay);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subscription.price >= 10000
                        ? Colors.black
                        : GPTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'S\'abonner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            left: -10,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(15 / 360),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.subscription.price >= 10000
                        ? Colors.black
                        : GPTheme.primaryColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
