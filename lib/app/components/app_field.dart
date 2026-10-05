// lib/app/components/app_field.dart
//
// SOURCE UNIQUE du design des champs de saisie et des listes déroulantes.
// Tout se règle dans [AppFieldStyle] : AppField, AppDropdown, AppDateField ET
// le `inputDecorationTheme` global (app_theme.dart) en dérivent, donc un
// TextFormField « nu » a exactement le même rendu qu'un AppField.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

class AppFieldStyle {
  AppFieldStyle._();

  // ── Variables de design (à modifier ICI uniquement) ──────────────────────
  static const double radius = 50;
  static const double iconSize = 20;
  static const double borderWidth = 1;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 18, vertical: 16);
  static const Color fill = Colors.white;
  static const Color text = Color(0xFF111111);
  static const Color hint = Color(0xFF8A8A93);
  static const Color icon = Color(0xFF5B5B66);
  static const Color border = Color(0xFFD9D9E0);
  static const Color focus = Color(0xFF111111);
  static const Color error = Color(0xFFE5484D);
  static const Color errorOnPrimary = Color(0xFFFFE08A);
  static const TextStyle textStyle = TextStyle(color: text, fontSize: 15);
  static const TextStyle hintStyle = TextStyle(color: hint, fontSize: 15);

  static OutlineInputBorder _b(Color c, [double w = borderWidth]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: c, width: w),
      );

  /// Thème global : utilisé par ThemeData.inputDecorationTheme.
  static InputDecorationTheme get theme => InputDecorationTheme(
        filled: true,
        fillColor: fill,
        isDense: false,
        contentPadding: padding,
        hintStyle: hintStyle,
        labelStyle: const TextStyle(color: hint, fontSize: 14),
        errorStyle: const TextStyle(color: errorOnPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        errorMaxLines: 2,
        iconColor: icon,
        prefixIconColor: icon,
        suffixIconColor: icon,
        border: _b(border),
        enabledBorder: _b(border),
        disabledBorder: _b(border),
        focusedBorder: _b(focus, 1.6),
        errorBorder: _b(error),
        focusedErrorBorder: _b(error, 1.6),
      );

  static InputDecoration decoration({
    required String hint,
    IconData? icon,
    Widget? prefix,
    Widget? suffix,
    String? errorText,
  }) =>
      InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefix ?? (icon == null ? null : Icon(icon, size: iconSize)),
        suffixIcon: suffix,
      );
}

/// Champ texte standard.
class AppField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? icon;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final bool obscure;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final int maxLines;
  final TextInputAction? action;
  final ValueChanged<String>? onChanged;

  const AppField({
    super.key,
    this.controller,
    required this.hint,
    this.icon,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.obscure = false,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.formatters,
    this.maxLines = 1,
    this.action,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        obscureText: obscure,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        inputFormatters: formatters,
        maxLines: maxLines,
        textInputAction: action,
        onChanged: onChanged,
        style: AppFieldStyle.textStyle,
        decoration: AppFieldStyle.decoration(hint: hint, icon: icon, prefix: prefix, suffix: suffix),
      );
}

/// Champ date (sélecteur natif). Valeur stockée au format yyyy-MM-dd.
class AppDateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initial;
  final String? Function(String?)? validator;
  const AppDateField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon = Icons.cake_outlined,
    this.firstDate,
    this.lastDate,
    this.initial,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => AppField(
        controller: controller,
        hint: hint,
        icon: icon,
        readOnly: true,
        validator: validator,
        suffix: const Icon(Icons.expand_more_rounded, size: AppFieldStyle.iconSize),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(controller.text) ?? initial ?? DateTime(now.year - 25, 1, 1),
            firstDate: firstDate ?? DateTime(1920),
            lastDate: lastDate ?? now,
            helpText: hint.replaceAll('*', '').trim(),
          );
          if (picked != null) {
            controller.text =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          }
        },
      );
}

/// Liste déroulante : même apparence qu'un AppField, sélection dans une
/// feuille modale (avec recherche au-delà de [searchFrom] éléments).
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String hint;
  final IconData? icon;
  final String? Function(T?)? validator;
  final bool loading;
  final VoidCallback? onRetry;
  final int searchFrom;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    required this.hint,
    this.icon,
    this.validator,
    this.loading = false,
    this.onRetry,
    this.searchFrom = 10,
  });

  Future<void> _open(BuildContext context, FormFieldState<T> field) async {
    FocusScope.of(context).unfocus();
    if (items.isEmpty) {
      onRetry?.call();
      return;
    }
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DropdownSheet<T>(
        title: hint.replaceAll('*', '').trim(),
        items: items,
        labelOf: labelOf,
        selected: value,
        searchable: items.length >= searchFrom,
      ),
    );
    if (picked != null) {
      field.didChange(picked);
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) => FormField<T>(
        key: ValueKey('dd_${value}_${items.length}'),
        initialValue: value,
        validator: validator,
        builder: (field) {
          final label = value == null ? null : labelOf(value as T);
          return InkWell(
            borderRadius: BorderRadius.circular(AppFieldStyle.radius),
            onTap: loading ? null : () => _open(context, field),
            child: InputDecorator(
              isEmpty: label == null,
              decoration: AppFieldStyle.decoration(
                hint: hint,
                icon: icon,
                errorText: field.errorText,
                suffix: loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Icon(items.isEmpty ? Icons.refresh_rounded : Icons.expand_more_rounded, size: AppFieldStyle.iconSize),
              ),
              child: Text(
                label ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: label == null ? AppFieldStyle.hintStyle : AppFieldStyle.textStyle,
              ),
            ),
          );
        },
      );
}

class _DropdownSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final T? selected;
  final bool searchable;
  const _DropdownSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.selected,
    required this.searchable,
  });

  @override
  State<_DropdownSheet<T>> createState() => _DropdownSheetState<T>();
}

class _DropdownSheetState<T> extends State<_DropdownSheet<T>> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF1A1A1A) : Colors.white;
    final fg = dark ? Colors.white : Colors.black87;
    final list = widget.items.where((e) => widget.labelOf(e).toLowerCase().contains(q.toLowerCase())).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .75),
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: .4), borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.title, style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppField(
                  hint: 'Rechercher',
                  icon: Icons.search_rounded,
                  onChanged: (v) => setState(() => q = v),
                ),
              ),
            Flexible(
              child: list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text('Aucun résultat', style: TextStyle(color: fg.withValues(alpha: .6))),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        final sel = e == widget.selected;
                        return ListTile(
                          title: Text(widget.labelOf(e),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: fg, fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
                          trailing: sel ? Icon(Icons.check_rounded, color: fg) : null,
                          onTap: () => Navigator.pop(context, e),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicateur d'étapes (1 — 2 — …) pour les formulaires en plusieurs pages.
class AppStepper extends StatelessWidget {
  final List<String> labels;
  final int current; // 0-based
  final Color color; // couleur des éléments actifs
  final Color onColor; // texte/icône dans une pastille active
  const AppStepper({
    super.key,
    required this.labels,
    required this.current,
    this.color = Colors.white,
    this.onColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final off = color.withValues(alpha: .35);
    final children = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      final done = i < current, active = i == current;
      children.add(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (done || active) ? color : Colors.transparent,
              border: Border.all(color: (done || active) ? color : off, width: 1.6),
            ),
            child: Center(
              child: done
                  ? Icon(Icons.check_rounded, size: 18, color: onColor)
                  : Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: active ? onColor : off)),
            ),
          ),
          const SizedBox(height: 6),
          Text(labels[i],
              style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: (done || active) ? color : off)),
        ],
      ));
      if (i < labels.length - 1) {
        children.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18, left: 8, right: 8),
            child: Container(height: 2, decoration: BoxDecoration(color: done ? color : off, borderRadius: BorderRadius.circular(2))),
          ),
        ));
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}
