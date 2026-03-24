import 'package:country_pickers/country.dart';
import 'package:country_pickers/countries.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:flutter/material.dart';

import 'package:grand_public_v2/app/themes/app_theme.dart';

final List<Country> _countries = countryList;

// ─────────────────────────────────────────────
// Country Picker Widget
// ─────────────────────────────────────────────
class CountryPickerWidget extends StatefulWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onChanged;

  const CountryPickerWidget({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
  });

  @override
  State<CountryPickerWidget> createState() => CountryPickerWidgetState();
}

class CountryPickerWidgetState extends State<CountryPickerWidget> {
  void _openPicker() {
    String search = '';
    List<Country> filtered = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: GPTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choisir un pays',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un pays...',
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          search = val.toLowerCase();
                          filtered = _countries
                              .where(
                                (c) =>
                                    c.name.toLowerCase().contains(search) ||
                                    c.phoneCode.contains(search),
                              )
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // List
                  filtered.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Aucun Résultat",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final country = filtered[i];
                              final isSelected =
                                  country.isoCode ==
                                  widget.selectedCountry.isoCode;
                              return ListTile(
                                leading: CountryPickerUtils.getDefaultFlagImage(
                                  country,
                                ),
                                title: Text(
                                  country.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                trailing: Text(
                                  "+${country.phoneCode}",
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white60,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                tileColor: isSelected
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onTap: () {
                                  widget.onChanged(country);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadiusGeometry.horizontal(
                left: Radius.circular(30),
              ),
              child: CountryPickerUtils.getDefaultFlagImage(
                widget.selectedCountry,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "+${widget.selectedCountry.phoneCode}",
              style: const TextStyle(
                // color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              /* color: Colors.white70, */ size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
