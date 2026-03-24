import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/modules/forgot_password/bindings/forgot_password_binding.dart';
import 'package:grand_public_v2/app/modules/forgot_password/views/forgot_password_view.dart';
import 'package:grand_public_v2/app/modules/main_page/bindings/main_page_binding.dart';
import 'package:grand_public_v2/app/modules/main_page/views/main_page_view.dart';
import 'package:grand_public_v2/app/modules/reset_password/bindings/reset_password_binding.dart';
import 'package:grand_public_v2/app/modules/reset_password/views/reset_password_view.dart';
import 'package:grand_public_v2/app/modules/update_required/bindings/update_required_binding.dart';
import 'package:grand_public_v2/app/modules/update_required/views/update_required_view.dart';

import '../modules/confirm/bindings/confirm_binding.dart';
import '../modules/confirm/views/confirm_view.dart';
import '../modules/events/bindings/events_binding.dart';
import '../modules/events/views/events_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/insolite/bindings/insolite_binding.dart';
import '../modules/insolite/views/insolite_view.dart';
import '../modules/interest/bindings/interest_binding.dart';
import '../modules/interest/views/interest_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/opinion/bindings/opinion_binding.dart';
import '../modules/opinion/views/opinion_view.dart';
import '../modules/pay_fail/bindings/pay_fail_binding.dart';
import '../modules/pay_fail/views/pay_fail_view.dart';
import '../modules/pay_suc/bindings/pay_suc_binding.dart';
import '../modules/pay_suc/views/pay_suc_view.dart';
import '../modules/payement/bindings/payement_binding.dart';
import '../modules/payement/views/payement_view.dart';
import '../modules/portrait/bindings/portrait_binding.dart';
import '../modules/portrait/views/portrait_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/social_about/bindings/social_about_binding.dart';
import '../modules/social_about/views/social_about_view.dart';
import '../modules/social_link/bindings/social_link_binding.dart';
import '../modules/social_link/views/social_link_view.dart';
import '../modules/social_premium/bindings/social_premium_binding.dart';
import '../modules/social_premium/views/social_premium_view.dart';
import '../modules/soon/bindings/soon_binding.dart';
import '../modules/soon/views/soon_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/sucess_page/bindings/sucess_page_binding.dart';
import '../modules/sucess_page/views/sucess_page_view.dart';
import '../modules/videos/bindings/videos_binding.dart';
import '../modules/videos/views/videos_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.UPDATE_REQUIRED,
      page: () => UpdateRequiredView(),
      binding: UpdateRequiredBinding(),
    ),
    GetPage(
      name: _Paths.MAIN_PAGE,
      page: () => MainPageView(),
      binding: MainPageBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.CONFIRM,
      page: () => const ConfirmView(),
      binding: ConfirmBinding(),
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: _Paths.RESET_PASSWORD,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: _Paths.SUCESS_PAGE,
      page: () => const SucessPageView(),
      binding: SucessPageBinding(),
    ),
    GetPage(
      name: _Paths.INTEREST,
      page: () => const InterestView(),
      binding: InterestBinding(),
    ),
    GetPage(
      name: _Paths.PAYEMENT,
      page: () => const PayementView(),
      binding: PayementBinding(),
    ),
    GetPage(
      name: _Paths.PAY_SUC,
      page: () => const PaySucView(),
      binding: PaySucBinding(),
    ),
    GetPage(
      name: _Paths.PAY_FAIL,
      page: () => const PayFailView(),
      binding: PayFailBinding(),
    ),
    GetPage(
      name: '${_Paths.VIDEOS}/:id',
      // VideosView expects an int videoId from route parameters
      page: () {
        final id = int.tryParse(Get.parameters['id'] ?? '') ?? 0;
        debugPrint('VideosView: Received videoId from route = $id');
        return VideosView(videoId: id);
      },
      binding: VideosBinding(),
    ),
    GetPage(
      name: _Paths.PORTRAIT,
      page: () => const PortraitView(),
      binding: PortraitBinding(),
    ),
    GetPage(
      name: _Paths.OPINION,
      page: () => const OpinionView(),
      binding: OpinionBinding(),
    ),
    GetPage(
      name: _Paths.EVENTS,
      page: () => const EventsView(),
      binding: EventsBinding(),
    ),
    GetPage(
      name: _Paths.INSOLITE,
      page: () => const InsoliteView(),
      binding: InsoliteBinding(),
    ),
    GetPage(
      name: _Paths.SOON,
      page: () => const SoonView(),
      binding: SoonBinding(),
    ),
    GetPage(
      name: _Paths.SOCIAL_LINK,
      page: () => const SocialLinkView(),
      binding: SocialLinkBinding(),
    ),
    GetPage(
      name: _Paths.SOCIAL_PREMIUM,
      page: () => const SocialPremiumView(),
      binding: SocialPremiumBinding(),
    ),
    GetPage(
      name: _Paths.SOCIAL_ABOUT,
      page: () => const SocialAboutView(),
      binding: SocialAboutBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
  ];
}
