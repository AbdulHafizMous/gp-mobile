import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grand_public_v2/app/utils/toast_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grand_public_v2/app/modules/shop/controllers/shop_controller.dart';
import 'package:grand_public_v2/app/themes/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
extension _Tx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get inputBg => isDark ? Colors.white10 : Colors.grey.shade100;
  Color get primary => Theme.of(this).textTheme.bodyLarge!.color!;
  Color get subtle => Theme.of(this).hintColor;
  Color get borderColor =>
      isDark ? Colors.white24 : Colors.grey.shade400;
  Color get appBarBg =>
      isDark ? const Color(0xFF111111) : GPTheme.primaryColor;
}

class ShopCreateView extends GetView<ShopController> {
  const ShopCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final selectedCategory = Rxn<int>();
    final photos = <File>[].obs;
    final video = Rxn<File>();
    final picker = ImagePicker();

    Future<void> pickPhoto() async {
      if (photos.length >= 3) {
        ToastHelper.showToast(
          'Limite atteinte : 3 photos maximum par annonce.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) photos.add(File(file.path));
    }

    Future<void> pickVideo() async {
      final file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      final sizeInMb = await File(file.path).length() / (1024 * 1024);
      if (sizeInMb > 15) {
        ToastHelper.showToast(
          'Vidéo trop lourde : La vidéo ne doit pas dépasser 15 Mo.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      video.value = File(file.path);
    }

    Future<void> submit() async {
      if (selectedCategory.value == null ||
          titleCtrl.text.trim().isEmpty ||
          descCtrl.text.trim().isEmpty) {
        ToastHelper.showToast(
          'Champs manquants : Merci de remplir la catégorie, le titre et la description.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
      final success = await controller.createListing(
        categoryId: selectedCategory.value!,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        price: double.tryParse(priceCtrl.text.trim()),
        city: cityCtrl.text.trim(),
        photos: photos.toList(),
        video: video.value,
      );
      if (success) Get.back();
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Déposer une annonce'),
        backgroundColor: context.appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Catégorie',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.primary,
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => DropdownButtonFormField<int>(
              value: selectedCategory.value,
              dropdownColor: context.isDark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              style: TextStyle(color: context.primary, fontSize: 14),
              items: controller.categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => selectedCategory.value = v,
              decoration: _inputDecoration(context, 'Choisir une catégorie'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Titre',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.primary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: titleCtrl,
            style: TextStyle(color: context.primary, fontSize: 14),
            decoration: _inputDecoration(
              context,
              'Ex: Téléphone Techno Pop 3, bon état',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.primary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: descCtrl,
            maxLines: 4,
            style: TextStyle(color: context.primary, fontSize: 14),
            decoration: _inputDecoration(
              context,
              'Décrivez votre annonce en détail...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.primary, fontSize: 14),
                  decoration: _inputDecoration(
                    context,
                    'Prix (FCFA) — optionnel',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: cityCtrl,
                  style: TextStyle(color: context.primary, fontSize: 14),
                  decoration: _inputDecoration(context, 'Ville'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Photos (3 maximum)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.primary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...photos.map(
                  (f) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          f,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => photos.remove(f),
                        ),
                      ),
                    ],
                  ),
                ),
                if (photos.length < 3)
                  GestureDetector(
                    onTap: pickPhoto,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: context.inputBg,
                        border: Border.all(
                          color: context.borderColor,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        color: context.subtle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vidéo (15 Mo max, optionnel)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.primary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => video.value == null
                ? OutlinedButton.icon(
                    onPressed: pickVideo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primary,
                      side: BorderSide(color: context.borderColor),
                    ),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Ajouter une vidéo'),
                  )
                : Row(
                    children: [
                      const Icon(Icons.videocam, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          video.value!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.primary),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: context.subtle),
                        onPressed: () => video.value = null,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isSubmitting.value ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GPTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Publier l'annonce"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.subtle, fontSize: 14),
      filled: true,
      fillColor: context.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}