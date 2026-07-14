import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  // Filter settings state
  RangeValues _ageRange = const RangeValues(18, 50);
  RangeValues _heightRange = const RangeValues(140, 210);
  String? _selectedReligion;
  String? _selectedMaritalStatus;
  String? _selectedCountry;
  bool? _hasChildren;
  bool? _smoking;
  bool? _drinking;

  void _reset() {
    setState(() {
      _ageRange = const RangeValues(18, 50);
      _heightRange = const RangeValues(140, 210);
      _selectedReligion = null;
      _selectedMaritalStatus = null;
      _selectedCountry = null;
      _hasChildren = null;
      _smoking = null;
      _drinking = null;
    });
  }

  void _apply() {
    // Save to local settings / preferences
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      child: Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.l),
          topRight: Radius.circular(AppRadius.l),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.m,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Handle
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset All', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16.0),

            // Age Slider
            const Text('Age Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_ageRange.start.round()} years'),
                Text('${_ageRange.end.round()} years'),
              ],
            ),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 90,
              activeColor: AppColors.primaryBurgundy,
              inactiveColor: AppColors.borderLight,
              onChanged: (values) {
                setState(() => _ageRange = values);
              },
            ),
            const SizedBox(height: 16.0),

            // Religion Picker
            const Text('Religion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: ['Islam', 'Christianity', 'Judaism'].map((religion) {
                final isSelected = _selectedReligion == religion;
                return ChoiceChip(
                  label: Text(religion),
                  selected: isSelected,
                  selectedColor: AppColors.primaryBurgundy,
                  backgroundColor: AppColors.cardCream,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedReligion = selected ? religion : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),

            // Height Slider
            const Text('Height Range (cm)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_heightRange.start.round()} cm'),
                Text('${_heightRange.end.round()} cm'),
              ],
            ),
            RangeSlider(
              values: _heightRange,
              min: 120,
              max: 220,
              activeColor: AppColors.primaryBurgundy,
              inactiveColor: AppColors.borderLight,
              onChanged: (values) {
                setState(() => _heightRange = values);
              },
            ),
            const SizedBox(height: 16.0),

            // Marital Status
            const Text('Marital Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: ['Never married', 'Separated', 'Divorced', 'Widowed'].map((status) {
                final isSelected = _selectedMaritalStatus == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: AppColors.primaryBurgundy,
                  backgroundColor: AppColors.cardCream,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedMaritalStatus = selected ? status : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),

            // Country Picker
            const Text('Country', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: ['USA', 'Canada', 'UK', 'Australia', 'UAE', 'Singapore'].map((country) {
                final isSelected = _selectedCountry == country;
                return ChoiceChip(
                  label: Text(country),
                  selected: isSelected,
                  selectedColor: AppColors.primaryBurgundy,
                  backgroundColor: AppColors.cardCream,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCountry = selected ? country : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24.0),

            // Checkbox Lifestyle options
            _buildLifestyleTile('Has Children', _hasChildren, (val) => setState(() => _hasChildren = val)),
            _buildLifestyleTile('Smokes', _smoking, (val) => setState(() => _smoking = val)),
            _buildLifestyleTile('Drinks', _drinking, (val) => setState(() => _drinking = val)),
            
            const SizedBox(height: 32.0),

            FilledButton(
              onPressed: _apply,
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildLifestyleTile(String label, bool? currentValue, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500)),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Yes'),
                selected: currentValue == true,
                selectedColor: AppColors.primaryBurgundy,
                backgroundColor: AppColors.cardCream,
                labelStyle: TextStyle(color: currentValue == true ? Colors.white : AppColors.textPrimary),
                onSelected: (sel) => onChanged(sel ? true : null),
              ),
              const SizedBox(width: 8.0),
              ChoiceChip(
                label: const Text('No'),
                selected: currentValue == false,
                selectedColor: AppColors.primaryBurgundy,
                backgroundColor: AppColors.cardCream,
                labelStyle: TextStyle(color: currentValue == false ? Colors.white : AppColors.textPrimary),
                onSelected: (sel) => onChanged(sel ? false : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
