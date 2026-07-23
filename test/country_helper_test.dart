import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loverage/core/utils/country_helper.dart';

void main() {
  test('CountryHelper flag mappings for UAE and security checks', () {
    expect(
      CountryHelper.getFlagAsset('United Arab Emirates'),
      'Assets/flags/United Arab Emirates.png',
    );
    expect(
      CountryHelper.getFlagAsset('UAE'),
      'Assets/flags/United Arab Emirates.png',
    );
    expect(
      CountryHelper.getFlagAsset('AE'),
      'Assets/flags/United Arab Emirates.png',
    );
    expect(
      CountryHelper.getFlagAsset('U.A.E.'),
      'Assets/flags/United Arab Emirates.png',
    );
    expect(
      CountryHelper.getFlagAsset('UAE 🇦🇪'),
      'Assets/flags/United Arab Emirates.png',
    );
    expect(CountryHelper.getFlagAsset('Israel'), null);
    expect(CountryHelper.getFlagAsset('israel'), null);
  });

  test('every supported profile country code resolves to an asset', () {
    expect(CountryHelper.supportedCountryCodes.length, 194);
    for (final code in CountryHelper.supportedCountryCodes) {
      expect(
        CountryHelper.getFlagAsset(code),
        isNotNull,
        reason: '$code should resolve to a bundled flag asset',
      );
    }
  });

  test('every country mapping points to a real bundled flag file', () {
    for (final country in CountryHelper.allCountries) {
      final asset = CountryHelper.getFlagAsset(country);
      expect(asset, isNotNull, reason: '$country should have a flag mapping');
      expect(
        File(asset!).existsSync(),
        isTrue,
        reason: '$country is mapped to a missing asset: $asset',
      );
    }
  });

  test('country resolver accepts full names and combined location values', () {
    expect(CountryHelper.getFlagAsset('PH'), 'Assets/flags/Philippines.png');
    expect(
      CountryHelper.getFlagAsset('Dubai, AE'),
      'Assets/flags/United Arab Emirates.png',
    );
    expect(
      CountryHelper.getFlagAsset('England'),
      'Assets/flags/United Kingdom.png',
    );
    expect(CountryHelper.getCountryCode('Indonesia'), 'ID');
    expect(CountryHelper.getCountryCode('Dubai, AE'), 'AE');
    expect(CountryHelper.getCountryCode('England'), 'GB');
  });

  test('non-country strings like No, Yes, None do not resolve to country flags', () {
    expect(CountryHelper.getFlagAsset('No'), null);
    expect(CountryHelper.getFlagAsset('no'), null);
    expect(CountryHelper.getFlagAsset('Yes'), null);
    expect(CountryHelper.getFlagAsset('yes'), null);
    expect(CountryHelper.getFlagAsset('None'), null);
    expect(CountryHelper.getFlagAsset('Not specified'), null);
    expect(CountryHelper.getFlagAsset('N/A'), null);

    // Uppercase NO is the ISO-2 code for Norway
    expect(CountryHelper.getFlagAsset('NO'), 'Assets/flags/Norway.png');
  });
}
