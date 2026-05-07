// lib/app/modules/profile/controllers/profile_controller.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:grand_public_v2/app/data/mocks/interest_mock.dart';
import 'package:grand_public_v2/app/data/models/avatar.dart';
import 'package:grand_public_v2/app/data/models/profile_interest.dart';
import 'package:grand_public_v2/app/globals/index.dart';
import 'package:grand_public_v2/app/data/models/user.dart';
import 'package:grand_public_v2/app/services/dio.services.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:image_picker/image_picker.dart';

// ── Sub-pages ─────────────────────────────────────────────────────────────────
enum ProfileSubPage { main, editInfo, changePassword, avatarPicker, interests, manageSubscriptions, favorites }

class ProfileController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final isDark = false.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final subPage = ProfileSubPage.main.obs;
  final avatars = <Avatar>[].obs;
  final isAvatarLoading = false.obs;

  // ── Form controllers ───────────────────────────────────────────────────────
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final descController = TextEditingController();
  final cityController = TextEditingController();
  final birthdayController = TextEditingController();

  // Read-only display (non modifiable)
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKeyEdit = GlobalKey<FormState>();
  final formKeyPassword = GlobalKey<FormState>();

  final isOldObscure = true.obs;
  final isNewObscure = true.obs;
  final isConfirmObscure = true.obs;

  // ── Gender dropdowns ────────────────────────────────────────────────────────
  final selectedGender = RxnString(); // 'male' | 'female' | 'other'
  final selectedLookingFor = RxnString(); // 'male' | 'female' | 'both'

  static const genderOptions = [
    {'value': 'male', 'label': 'Homme'},
    {'value': 'female', 'label': 'Femme'},
    {'value': 'other', 'label': 'Autre'},
  ];
  static const lookingForOptions = [
    {'value': 'male', 'label': 'Hommes'},
    {'value': 'female', 'label': 'Femmes'},
    {'value': 'both', 'label': 'Les deux'},
  ];

  // ── Avatar ─────────────────────────────────────────────────────────────────
  final pickedAvatarPath = ''.obs;
  final selectedAvatarIndex = (-1).obs;

  // ── Interests ──────────────────────────────────────────────────────────────
  final interests = <ProfileInterest>[].obs;
  final isInterestsLoading = false.obs;

  // ── Getters ────────────────────────────────────────────────────────────────
  String get displayName => activeUser.value.name;
  String get displayEmail => activeUser.value.email;
  String get displayAvatar => activeUser.value.avatarUrl ?? '';

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    isDark.value = GetStorage().read('isDark') ?? false;
    _loadUserFromStorage();
    loadProfile();
    loadAvatars();
  }

  void _loadUserFromStorage() {
    emailController.text = GetStorage().read<String>('email') ?? '';
    nameController.text = GetStorage().read<String>('username') ?? '';
  }

  void _syncFormFromUser(User u) {
    nameController.text = u.name;
    emailController.text = u.email;
    phoneController.text = u.phone ?? '';
    usernameController.text = u.username ?? '';
    descController.text = u.description ?? '';
    cityController.text = u.city ?? '';
    birthdayController.text = u.birthday ?? '';
    selectedGender.value = u.gender;
    selectedLookingFor.value = u.lookingForGender;
  }

  // ── Sub-page navigation ────────────────────────────────────────────────────
  void goTo(ProfileSubPage page) => subPage.value = page;
  void goBack() => subPage.value = ProfileSubPage.main;

  // ── Load profile ───────────────────────────────────────────────────────────
  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        final u = User.fromJson({
          "id": 1,
          "name": GetStorage().read('username') ?? "Hafiz MOUSTAPHA",
          "email": GetStorage().read('email') ?? "hafizmoustapha64@gmail.com",
          "username": "hafiz64",
          "phone": "+2290161648007",
          "avatar_url": null,
          "birthday": "1998-05-12",
          "city": "Cotonou",
          "gender": "male",
          "description": "Passionné de tech et de médias.",
          "looking_for_gender": "female",
          "role": GetStorage().read('role') ?? "user",
          "country_code": "BJ",
          "is_active": true,
          "created_at": "2026-03-16T10:30:00.000000Z",
          "updated_at": "2026-03-16T10:30:00.000000Z",
        });
        activeUser.value = u;
        _syncFormFromUser(u);
      } else {
        final r = await RequestService().get('/auth/me');
        final u = User.fromJson(r.data['data']['user']);
        activeUser.value = u;
        _syncFormFromUser(u);
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      debugPrint('loadProfile error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Update profile ─────────────────────────────────────────────────────────
  Future<void> updateProfile() async {
    if (!formKeyEdit.currentState!.validate()) return;
    isSaving.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        GetStorage().write('username', nameController.text.trim());
        await ToastHelper.showToast(
          'Profil mis à jour !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        goBack();
      } else {
        await RequestService().post(
          '/users/update-profile',
          data: {
            'name': nameController.text.trim(),
            'username': usernameController.text.trim(),
            'description': descController.text.trim(),
            'city': cityController.text.trim(),
            'birthday': birthdayController.text.trim(),
            'gender': selectedGender.value,
            'looking_for_gender': selectedLookingFor.value,
          },
        );
        GetStorage().write('username', nameController.text.trim());
        await loadProfile();
        await ToastHelper.showToast(
          'Profil mis à jour !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        goBack();
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isSaving.value = false;
    }
  }

  // ── Change password ────────────────────────────────────────────────────────
  Future<void> changePassword() async {
    if (!formKeyPassword.currentState!.validate()) return;
    if (newPasswordController.text != confirmPasswordController.text) {
      await ToastHelper.showToast(
        'Les mots de passe ne correspondent pas',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    isSaving.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 600));
        await ToastHelper.showToast(
          'Mot de passe modifié !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        goBack();
      } else {
        await RequestService().post(
          '/users/update-password',
          data: {
            'current_password': oldPasswordController.text,
            'password': newPasswordController.text,
            'password_confirmation': confirmPasswordController.text,
          },
        );
        await ToastHelper.showToast(
          'Mot de passe modifié !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
        goBack();
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isSaving.value = false;
    }
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Future<void> pickAvatarFromGallery() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      pickedAvatarPath.value = file.path;
      await uploadAvatar(filePath: file.path);
    } catch (e) {
      debugPrint('pickAvatar error: $e');
    }
  }

  Future<void> loadAvatars() async {
    debugPrint("Loading Avatars");
    isAvatarLoading.value = true;
    try {
      if (useMock) {
        // fallback mock (randomuser)
        avatars.value = List.generate(
          24,
          (i) => Avatar(
            id: i + 1,
            name: "Avatar ${i + 1}",
            url: i < 12
                ? 'https://randomuser.me/api/portraits/men/${i + 10}.jpg'
                : 'https://randomuser.me/api/portraits/women/${i - 12 + 10}.jpg',
          ),
        );
      } else {
        final r = await RequestService().get('/users/avatars');

        final list = r.data['data']['avatars'] as List;

        debugPrint("Liste Avatars : $list");

        avatars.value = list.map((e) => Avatar.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('loadAvatars error: $e');
    } finally {
      isAvatarLoading.value = false;
    }
  }

  Future<void> selectPresetAvatar(Avatar avatar) async {
    selectedAvatarIndex.value = avatar.id;

    isSaving.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        await ToastHelper.showToast(
          'Avatar mis à jour !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        goBack();
      } else {
        await RequestService().post(
          '/users/avatar/select',
          data: {'avatar_id': avatar.id},
        );
        await loadProfile();
        await ToastHelper.showToast(
          'Avatar mis à jour !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        goBack();
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> uploadAvatar({required String filePath}) async {
    isSaving.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 700));
        await ToastHelper.showToast(
          'Photo de profil mise à jour !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        goBack();
      } else {
        // 1. Extraire l'extension pour définir le subtype (jpg, png, etc.)
        String extension = filePath.split('.').last.toLowerCase();
        if (extension == 'jpg') extension = 'jpeg';

        // 2. Créer le FormData avec le MediaType explicite
        final formData = FormData.fromMap({
          'avatar': await MultipartFile.fromFile(
            filePath,
            filename: filePath.split('/').last,
            // CRITIQUE : Préciser le type pour que Laravel le reconnaisse bien
            // contentType: DioMediaType('image', extension),
          ),
        });

        // 3. Appel au service
        await RequestService().post('/users/avatar/upload', data: formData);

        await loadProfile();
        await ToastHelper.showToast(
          'Photo de profil mise à jour !',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        goBack();
      }
    } on DioException catch (e) {
      // Affiche le log complet pour voir l'erreur SQL ou PHP exacte renvoyée par Laravel
      debugPrint("SERVER ERROR DATA: ${e.response?.data}");
      _handleDioError(e);
    } finally {
      isSaving.value = false;
    }
  }

  // ── Interests ──────────────────────────────────────────────────────────────
  Future<void> loadInterests() async {
    isInterestsLoading.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        interests.value = List.generate(
          mockInterests.length,
          (i) => ProfileInterest(
            id: i + 1,
            name: mockInterests[i],
            isSelected: i < 3, // 3 sélectionnés par défaut en mock
          ),
        );
      } else {
        final r = await RequestService().get('/interest-centers');
        final list = r.data['data']['interest_centers'] as List<dynamic>;
        interests.value = list
            .map(
              (e) => ProfileInterest(
                id: e['id'],
                name: e['name'],
                isSelected: e['is_selected'] == true,
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('loadInterests error: $e');
    } finally {
      isInterestsLoading.value = false;
    }
  }

  void toggleInterest(ProfileInterest interest) {
    interest.isSelected = !interest.isSelected;
    interests.refresh();
  }

  Future<void> saveInterests() async {
    final selected = interests.where((e) => e.isSelected).toList();
    if (selected.isEmpty) {
      await ToastHelper.showToast(
        "Choisissez au moins un centre d'intérêt",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }
    isSaving.value = true;
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        await ToastHelper.showToast(
          "Centres d'intérêt enregistrés !",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        goBack();
      } else {
        await RequestService().post(
          '/interest-centers',
          data: {'interest_center_ids': selected.map((e) => e.id).toList()},
        );
        await ToastHelper.showToast(
          "Centres d'intérêt enregistrés !",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        goBack();
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } finally {
      isSaving.value = false;
    }
  }

  // ── Theme ──────────────────────────────────────────────────────────────────
  void toggleTheme() {
    isDark.value = !isDark.value;
    Get.changeTheme(isDark.value ? GPTheme.dark() : GPTheme.light());
    GetStorage().write('isDark', isDark.value);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  void logout() {
    GetStorage().remove('token');
    GetStorage().remove('isLogged');
    Get.offAllNamed('/login');
  }

  void _handleDioError(DioException e) {
    final msg = e.response != null
        ? 'Erreur ${e.response?.statusCode}'
        : e.message ?? 'Erreur réseau';
    debugPrint('DioError: $msg');
    ToastHelper.showToast(
      msg,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    usernameController.dispose();
    descController.dispose();
    cityController.dispose();
    birthdayController.dispose();
    emailController.dispose();
    phoneController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
