import 'package:flutter/material.dart';

import '../core/constants/nepal_geo.dart';
import '../core/theme/app_theme.dart';

/// City + Province dropdown pair, restricted to what GoDelivery currently
/// serves: any Kathmandu-valley city, only Bagmati province (the rest are
/// shown, disabled, to signal coverage coming later).
class CityProvinceFields extends StatelessWidget {
  const CityProvinceFields({
    required this.city,
    required this.province,
    required this.onCityChanged,
    required this.onProvinceChanged,
    super.key,
  });

  final String city;
  final String province;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onProvinceChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LabeledDropdown(
            label: 'City',
            value: city,
            items: NepalGeo.kathmanduValleyCities,
            onChanged: onCityChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LabeledDropdown(
            label: 'Province',
            value: province,
            items: NepalGeo.provinces,
            enabledItems: const {NepalGeo.defaultProvince},
            onChanged: onProvinceChanged,
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabledItems,
  });

  final String label;
  final String value;
  final List<String> items;
  final Set<String>? enabledItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.colors.cardAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: [
                for (final item in items)
                  DropdownMenuItem(
                    value: item,
                    enabled: enabledItems?.contains(item) ?? true,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: (enabledItems?.contains(item) ?? true)
                            ? context.colors.text
                            : context.colors.textMuted,
                      ),
                    ),
                  ),
              ],
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ),
      ],
    );
  }
}
