import 'package:flutter/material.dart';

class CountryHelper {
  static const Map<String, String> _flagMap = {
    'Afghanistan': 'Assets/flags/Afghanistan.png',
    'Albania': 'Assets/flags/Albania.png',
    'Algeria': 'Assets/flags/Algeria.png',
    'Andorra': 'Assets/flags/Andorra.png',
    'Angola': 'Assets/flags/Angola.png',
    'Antigua and Barbuda': 'Assets/flags/Antigua and Barbuda.png',
    'Argentina': 'Assets/flags/Argentina.png',
    'Armenia': 'Assets/flags/Armenia.png',
    'Australia': 'Assets/flags/Australia.png',
    'Austria': 'Assets/flags/Austria.png',
    'Azerbaijan': 'Assets/flags/Azerbaijan.png',
    'Bahamas': 'Assets/flags/Bahamas.png',
    'Bahrain': 'Assets/flags/Bahrain.png',
    'Bangladesh': 'Assets/flags/Bangladesh.png',
    'Barbados': 'Assets/flags/Barbados.png',
    'Belarus': 'Assets/flags/Belarus.png',
    'Belgium': 'Assets/flags/Belgium.png',
    'Belize': 'Assets/flags/Belize.png',
    'Benin': 'Assets/flags/Benin.png',
    'Bhutan': 'Assets/flags/Bhutan.png',
    'Bolivia': 'Assets/flags/Bolivia.png',
    'Bosnia and Herzegovina': 'Assets/flags/Bosnia and Herzegovina.png',
    'Botswana': 'Assets/flags/Botswana.png',
    'Brazil': 'Assets/flags/Brazil.png',
    'Brunei': 'Assets/flags/Brunei.png',
    'Bulgaria': 'Assets/flags/Bulgaria.png',
    'Burkina Faso': 'Assets/flags/Burkina Faso.png',
    'Burundi': 'Assets/flags/Burundi.png',
    'Cabo Verde': 'Assets/flags/Cabo Verde.png',
    'Cambodia': 'Assets/flags/Cambodia.png',
    'Cameroon': 'Assets/flags/Cameroon.png',
    'Canada': 'Assets/flags/Canada.png',
    'Central African Republic': 'Assets/flags/Central African Republic.png',
    'Chad': 'Assets/flags/Chad.png',
    'Chile': 'Assets/flags/Chile.png',
    'China': 'Assets/flags/China.png',
    'Colombia': 'Assets/flags/Colombia.png',
    'Comoros': 'Assets/flags/Comoros.png',
    'Costa Rica': 'Assets/flags/Costa Rica.png',
    "Cote d'Ivoire": "Assets/flags/Côte d’Ivoire .png",
    'Croatia': 'Assets/flags/Croatia .png',
    'Cuba': 'Assets/flags/Cuba .png',
    'Cyprus': 'Assets/flags/Cyprus .png',
    'Czechia': 'Assets/flags/Czechia .png',
    'Democratic Republic of the Congo':
        'Assets/flags/Democratic Republic of the Congo.png',
    'Denmark': 'Assets/flags/Denmark .png',
    'Djibouti': 'Assets/flags/Djibouti .png',
    'Dominica': 'Assets/flags/Dominica .png',
    'Dominican Republic': 'Assets/flags/Dominican Republic .png',
    'Ecuador': 'Assets/flags/Ecuador .png',
    'Egypt': 'Assets/flags/Egypt .png',
    'El Salvador': 'Assets/flags/El Salvador (1).png',
    'Equatorial Guinea': 'Assets/flags/Equatorial Guinea (1).png',
    'Eritrea': 'Assets/flags/Eritrea (1).png',
    'Estonia': 'Assets/flags/Estonia (1).png',
    'Eswatini': 'Assets/flags/Eswatini (1).png',
    'Ethiopia': 'Assets/flags/Ethiopia (1).png',
    'Fiji': 'Assets/flags/Fiji (1).png',
    'Finland': 'Assets/flags/Finland (1).png',
    'France': 'Assets/flags/France (1).png',
    'Gabon': 'Assets/flags/Gabon (1).png',
    'Gambia': 'Assets/flags/Gambia (1).png',
    'Georgia': 'Assets/flags/Georgia (1).png',
    'Germany': 'Assets/flags/Germany (1).png',
    'Ghana': 'Assets/flags/Ghana (1).png',
    'Greece': 'Assets/flags/Greece (1).png',
    'Grenada': 'Assets/flags/Grenada (1).png',
    'Guatemala': 'Assets/flags/Guatemala (1).png',
    'Guinea': 'Assets/flags/Guinea (1).png',
    'Guinea-Bissau': 'Assets/flags/Guinea-Bissau (1).png',
    'Guyana': 'Assets/flags/Guyana (1).png',
    'Haiti': 'Assets/flags/Haiti (1).png',
    'Holy See': 'Assets/flags/Holy See (1).png',
    'Honduras': 'Assets/flags/Honduras .png',
    'Hungary': 'Assets/flags/Hungary (1).png',
    'Iceland': 'Assets/flags/Iceland (1).png',
    'India': 'Assets/flags/India (1).png',
    'Indonesia': 'Assets/flags/Indonesia (1).png',
    'Iran': 'Assets/flags/Iran.png',
    'Iraq': 'Assets/flags/Iraq.png',
    'Ireland': 'Assets/flags/Ireland.png',
    'Italy': 'Assets/flags/Italy.png',
    'Jamaica': 'Assets/flags/Jamaica.png',
    'Japan': 'Assets/flags/Japan.png',
    'Jordan': 'Assets/flags/Jordan.png',
    'Kazakhstan': 'Assets/flags/Kazakhstan.png',
    'Kenya': 'Assets/flags/Kenya.png',
    'Kiribati': 'Assets/flags/Kiribati.png',
    'Kuwait': 'Assets/flags/Kuwait.png',
    'Kyrgyzstan': 'Assets/flags/Kyrgyzstan.png',
    'Laos': 'Assets/flags/Laos.png',
    'Latvia': 'Assets/flags/Latvia.png',
    'Lebanon': 'Assets/flags/Lebanon.png',
    'Lesotho': 'Assets/flags/Lesotho.png',
    'Liberia': 'Assets/flags/Liberia.png',
    'Libya': 'Assets/flags/Libya.png',
    'Liechtenstein': 'Assets/flags/Liechtenstein.png',
    'Lithuania': 'Assets/flags/Lithuania.png',
    'Luxembourg': 'Assets/flags/Luxembourg.png',
    'Madagascar': 'Assets/flags/Madagascar.png',
    'Malawi': 'Assets/flags/Malawi.png',
    'Malaysia': 'Assets/flags/Malaysia.png',
    'Maldives': 'Assets/flags/Maldives.png',
    'Mali': 'Assets/flags/Mali.png',
    'Malta': 'Assets/flags/Malta.png',
    'Marshall Islands': 'Assets/flags/Marshall Islands.png',
    'Mauritania': 'Assets/flags/Mauritania.png',
    'Mauritius': 'Assets/flags/Mauritius.png',
    'Mexico': 'Assets/flags/Mexico.png',
    'Micronesia': 'Assets/flags/Micronesia.png',
    'Moldova': 'Assets/flags/Moldova.png',
    'Monaco': 'Assets/flags/Monaco.png',
    'Mongolia': 'Assets/flags/Mongolia.png',
    'Montenegro': 'Assets/flags/Montenegro.png',
    'Morocco': 'Assets/flags/Morocco.png',
    'Mozambique': 'Assets/flags/Mozambique.png',
    'Myanmar': 'Assets/flags/Myanmar.png',
    'Namibia': 'Assets/flags/Namibia.png',
    'Nauru': 'Assets/flags/Nauru.png',
    'Nepal': 'Assets/flags/Nepal.png',
    'Netherlands': 'Assets/flags/Netherlands.png',
    'New Zealand': 'Assets/flags/New Zealand.png',
    'Nicaragua': 'Assets/flags/Nicaragua.png',
    'Niger': 'Assets/flags/Niger.png',
    'Nigeria': 'Assets/flags/Nigeria.png',
    'North Korea': 'Assets/flags/North Korea.png',
    'North Macedonia': 'Assets/flags/North Macedonia.png',
    'Norway': 'Assets/flags/Norway.png',
    'Oman': 'Assets/flags/Oman.png',
    'Pakistan': 'Assets/flags/Pakistan.png',
    'Palau': 'Assets/flags/Palau.png',
    'Palestine': 'Assets/flags/Palestine.png',
    'Panama': 'Assets/flags/Panama.png',
    'Papua New Guinea': 'Assets/flags/Papua New Guinea.png',
    'Paraguay': 'Assets/flags/Paraguay.png',
    'Peru': 'Assets/flags/Peru.png',
    'Philippines': 'Assets/flags/Philippines.png',
    'Poland': 'Assets/flags/Poland.png',
    'Portugal': 'Assets/flags/Portugal.png',
    'Qatar': 'Assets/flags/Qatar.png',
    'Republic Of The Congo': 'Assets/flags/Republic Of The Congo.png',
    'Romania': 'Assets/flags/Romania.png',
    'Russia': 'Assets/flags/Russia.png',
    'Rwanda': 'Assets/flags/Rwanda.png',
    'Saint Kitts And Nevis': 'Assets/flags/Saint Kitts And Nevis.png',
    'Saint Lucia': 'Assets/flags/Saint Lucia.png',
    'Saint Vincent and the Grenadines':
        'Assets/flags/Saint Vincent and the Grenadines.png',
    'Samoa': 'Assets/flags/Samoa.png',
    'San Marino': 'Assets/flags/San Marino.png',
    'Sao Tome and Principe': 'Assets/flags/Sao Tome and Principe.png',
    'Saudi Arabia': 'Assets/flags/Saudi Arabia.png',
    'Senegal': 'Assets/flags/Senegal.png',
    'Serbia': 'Assets/flags/Serbia.png',
    'Seychelles': 'Assets/flags/Seychelles.png',
    'Sierra Leone': 'Assets/flags/Sierra Leone.png',
    'Singapore': 'Assets/flags/Singapore.png',
    'Slovakia': 'Assets/flags/Slovakia.png',
    'Slovenia': 'Assets/flags/Slovenia.png',
    'Solomon Islands': 'Assets/flags/Solomon Islands.png',
    'Somalia': 'Assets/flags/Somalia.png',
    'South Africa': 'Assets/flags/South Africa.png',
    'South Korea': 'Assets/flags/South Korea.png',
    'South Sudan': 'Assets/flags/South Sudan.png',
    'Spain': 'Assets/flags/Spain.png',
    'Sri Lanka': 'Assets/flags/Sri Lanka.png',
    'Sudan': 'Assets/flags/Sudan.png',
    'Suriname': 'Assets/flags/Suriname.png',
    'Sweden': 'Assets/flags/Sweden.png',
    'Switzerland': 'Assets/flags/Switzerland.png',
    'Syria': 'Assets/flags/Syria.png',
    'Tajikistan': 'Assets/flags/Tajikistan.png',
    'Tanzania': 'Assets/flags/Tanzania.png',
    'Thailand': 'Assets/flags/Thailand.png',
    'Timor-Leste': 'Assets/flags/Timor-Leste.png',
    'Togo': 'Assets/flags/Togo.png',
    'Tonga': 'Assets/flags/Tonga.png',
    'Trinidad and Tobago': 'Assets/flags/Trinidad and Tobago.png',
    'Tunisia': 'Assets/flags/Tunisia.png',
    'Turkey': 'Assets/flags/Turkey.png',
    'Turkmenistan': 'Assets/flags/Turkmenistan.png',
    'Tuvalu': 'Assets/flags/Tuvalu.png',
    'Uganda': 'Assets/flags/Uganda.png',
    'Ukraine': 'Assets/flags/Ukraine.png',
    'United Arab Emirates': 'Assets/flags/United Arab Emirates.png',
    'United Kingdom': 'Assets/flags/United Kingdom.png',
    'United States': 'Assets/flags/United States.png',
    'Uruguay': 'Assets/flags/Uruguay.png',
    'Uzbekistan': 'Assets/flags/Uzbekistan.png',
    'Vanuatu': 'Assets/flags/Vanuatu.png',
    'Venezuela': 'Assets/flags/Venezuela.png',
    'Vietnam': 'Assets/flags/Vietnam.png',
    'Yemen': 'Assets/flags/Yemen.png',
    'Zambia': 'Assets/flags/Zambia.png',
    'Zimbabwe': 'Assets/flags/Zimbabwe.png',
  };

  /// ISO 3166-1 alpha-2 values stored in `profiles.public_country_code`.
  ///
  /// Keep these mapped to the canonical names used by [_flagMap] so every
  /// profile flag is rendered from the bundled asset instead of an emoji.
  static const Map<String, String> _isoAlpha2Aliases = {
    'AF': 'Afghanistan',
    'AL': 'Albania',
    'DZ': 'Algeria',
    'AD': 'Andorra',
    'AO': 'Angola',
    'AG': 'Antigua and Barbuda',
    'AR': 'Argentina',
    'AM': 'Armenia',
    'AU': 'Australia',
    'AT': 'Austria',
    'AZ': 'Azerbaijan',
    'BS': 'Bahamas',
    'BH': 'Bahrain',
    'BD': 'Bangladesh',
    'BB': 'Barbados',
    'BY': 'Belarus',
    'BE': 'Belgium',
    'BZ': 'Belize',
    'BJ': 'Benin',
    'BT': 'Bhutan',
    'BO': 'Bolivia',
    'BA': 'Bosnia and Herzegovina',
    'BW': 'Botswana',
    'BR': 'Brazil',
    'BN': 'Brunei',
    'BG': 'Bulgaria',
    'BF': 'Burkina Faso',
    'BI': 'Burundi',
    'CV': 'Cabo Verde',
    'KH': 'Cambodia',
    'CM': 'Cameroon',
    'CA': 'Canada',
    'CF': 'Central African Republic',
    'TD': 'Chad',
    'CL': 'Chile',
    'CN': 'China',
    'CO': 'Colombia',
    'KM': 'Comoros',
    'CR': 'Costa Rica',
    'CI': "Cote d'Ivoire",
    'HR': 'Croatia',
    'CU': 'Cuba',
    'CY': 'Cyprus',
    'CZ': 'Czechia',
    'CD': 'Democratic Republic of the Congo',
    'DK': 'Denmark',
    'DJ': 'Djibouti',
    'DM': 'Dominica',
    'DO': 'Dominican Republic',
    'EC': 'Ecuador',
    'EG': 'Egypt',
    'SV': 'El Salvador',
    'GQ': 'Equatorial Guinea',
    'ER': 'Eritrea',
    'EE': 'Estonia',
    'SZ': 'Eswatini',
    'ET': 'Ethiopia',
    'FJ': 'Fiji',
    'FI': 'Finland',
    'FR': 'France',
    'GA': 'Gabon',
    'GM': 'Gambia',
    'GE': 'Georgia',
    'DE': 'Germany',
    'GH': 'Ghana',
    'GR': 'Greece',
    'GD': 'Grenada',
    'GT': 'Guatemala',
    'GN': 'Guinea',
    'GW': 'Guinea-Bissau',
    'GY': 'Guyana',
    'HT': 'Haiti',
    'VA': 'Holy See',
    'HN': 'Honduras',
    'HU': 'Hungary',
    'IS': 'Iceland',
    'IN': 'India',
    'ID': 'Indonesia',
    'IR': 'Iran',
    'IQ': 'Iraq',
    'IE': 'Ireland',
    'IT': 'Italy',
    'JM': 'Jamaica',
    'JP': 'Japan',
    'JO': 'Jordan',
    'KZ': 'Kazakhstan',
    'KE': 'Kenya',
    'KI': 'Kiribati',
    'KW': 'Kuwait',
    'KG': 'Kyrgyzstan',
    'LA': 'Laos',
    'LV': 'Latvia',
    'LB': 'Lebanon',
    'LS': 'Lesotho',
    'LR': 'Liberia',
    'LY': 'Libya',
    'LI': 'Liechtenstein',
    'LT': 'Lithuania',
    'LU': 'Luxembourg',
    'MG': 'Madagascar',
    'MW': 'Malawi',
    'MY': 'Malaysia',
    'MV': 'Maldives',
    'ML': 'Mali',
    'MT': 'Malta',
    'MH': 'Marshall Islands',
    'MR': 'Mauritania',
    'MU': 'Mauritius',
    'MX': 'Mexico',
    'FM': 'Micronesia',
    'MD': 'Moldova',
    'MC': 'Monaco',
    'MN': 'Mongolia',
    'ME': 'Montenegro',
    'MA': 'Morocco',
    'MZ': 'Mozambique',
    'MM': 'Myanmar',
    'NA': 'Namibia',
    'NR': 'Nauru',
    'NP': 'Nepal',
    'NL': 'Netherlands',
    'NZ': 'New Zealand',
    'NI': 'Nicaragua',
    'NE': 'Niger',
    'NG': 'Nigeria',
    'KP': 'North Korea',
    'MK': 'North Macedonia',
    'NO': 'Norway',
    'OM': 'Oman',
    'PK': 'Pakistan',
    'PW': 'Palau',
    'PS': 'Palestine',
    'PA': 'Panama',
    'PG': 'Papua New Guinea',
    'PY': 'Paraguay',
    'PE': 'Peru',
    'PH': 'Philippines',
    'PL': 'Poland',
    'PT': 'Portugal',
    'QA': 'Qatar',
    'CG': 'Republic Of The Congo',
    'RO': 'Romania',
    'RU': 'Russia',
    'RW': 'Rwanda',
    'KN': 'Saint Kitts And Nevis',
    'LC': 'Saint Lucia',
    'VC': 'Saint Vincent and the Grenadines',
    'WS': 'Samoa',
    'SM': 'San Marino',
    'ST': 'Sao Tome and Principe',
    'SA': 'Saudi Arabia',
    'SN': 'Senegal',
    'RS': 'Serbia',
    'SC': 'Seychelles',
    'SL': 'Sierra Leone',
    'SG': 'Singapore',
    'SK': 'Slovakia',
    'SI': 'Slovenia',
    'SB': 'Solomon Islands',
    'SO': 'Somalia',
    'ZA': 'South Africa',
    'KR': 'South Korea',
    'SS': 'South Sudan',
    'ES': 'Spain',
    'LK': 'Sri Lanka',
    'SD': 'Sudan',
    'SR': 'Suriname',
    'SE': 'Sweden',
    'CH': 'Switzerland',
    'SY': 'Syria',
    'TJ': 'Tajikistan',
    'TZ': 'Tanzania',
    'TH': 'Thailand',
    'TL': 'Timor-Leste',
    'TG': 'Togo',
    'TO': 'Tonga',
    'TT': 'Trinidad and Tobago',
    'TN': 'Tunisia',
    'TR': 'Turkey',
    'TM': 'Turkmenistan',
    'TV': 'Tuvalu',
    'UG': 'Uganda',
    'UA': 'Ukraine',
    'AE': 'United Arab Emirates',
    'GB': 'United Kingdom',
    'US': 'United States',
    'UY': 'Uruguay',
    'UZ': 'Uzbekistan',
    'VU': 'Vanuatu',
    'VE': 'Venezuela',
    'VN': 'Vietnam',
    'YE': 'Yemen',
    'ZM': 'Zambia',
    'ZW': 'Zimbabwe',
  };

  static const Map<String, String> _aliases = {
    'AE': 'United Arab Emirates',
    'UAE': 'United Arab Emirates',
    'U.A.E.': 'United Arab Emirates',
    'UAE 🇦🇪': 'United Arab Emirates',
    'EMIRATES': 'United Arab Emirates',
    'UNITED ARAB EMIRATES': 'United Arab Emirates',
    'SA': 'Saudi Arabia',
    'KSA': 'Saudi Arabia',
    'SAUDI ARABIA': 'Saudi Arabia',
    'EG': 'Egypt',
    'EGYPT': 'Egypt',
    'KW': 'Kuwait',
    'KUWAIT': 'Kuwait',
    'QA': 'Qatar',
    'QATAR': 'Qatar',
    'BH': 'Bahrain',
    'BAHRAIN': 'Bahrain',
    'OM': 'Oman',
    'OMAN': 'Oman',
    'JO': 'Jordan',
    'JORDAN': 'Jordan',
    'LB': 'Lebanon',
    'LEBANON': 'Lebanon',
    'SY': 'Syria',
    'SYRIA': 'Syria',
    'IQ': 'Iraq',
    'IRAQ': 'Iraq',
    'IR': 'Iran',
    'IRAN': 'Iran',
    'USA': 'United States',
    'US': 'United States',
    'UNITED STATES': 'United States',
    'AMERICA': 'United States',
    'UK': 'United Kingdom',
    'GB': 'United Kingdom',
    'UNITED KINGDOM': 'United Kingdom',
    'ENGLAND': 'United Kingdom',
    'CA': 'Canada',
    'CANADA': 'Canada',
    'FR': 'France',
    'FRANCE': 'France',
    'DE': 'Germany',
    'GERMANY': 'Germany',
    'IT': 'Italy',
    'ITALY': 'Italy',
    'ES': 'Spain',
    'SPAIN': 'Spain',
    'TR': 'Turkey',
    'TURKEY': 'Turkey',
    'MA': 'Morocco',
    'MOROCCO': 'Morocco',
    'DZ': 'Algeria',
    'ALGERIA': 'Algeria',
    'TN': 'Tunisia',
    'TUNISIA': 'Tunisia',
    'LY': 'Libya',
    'LIBYA': 'Libya',
    'SD': 'Sudan',
    'SUDAN': 'Sudan',
    'YE': 'Yemen',
    'YEMEN': 'Yemen',
    'PS': 'Palestine',
    'PALESTINE': 'Palestine',
    'DR CONGO': 'Democratic Republic of the Congo',
    'CONGO': 'Republic Of The Congo',
    'IVORY COAST': "Cote d'Ivoire",
  };

  static List<String> get allCountries => _flagMap.keys.toList();

  static List<String> get supportedCountryCodes =>
      _isoAlpha2Aliases.keys.toList(growable: false);

  static String? getCountryCode(String? countryName) {
    if (countryName == null || countryName.trim().isEmpty) return null;
    final trimmed = countryName.trim();
    final upper = trimmed.toUpperCase();

    if (_isoAlpha2Aliases.containsKey(upper)) return upper;

    final aliasCountry = _aliases[upper];
    final canonicalName = aliasCountry ?? _canonicalCountryName(trimmed);
    if (canonicalName != null) {
      for (final entry in _isoAlpha2Aliases.entries) {
        if (entry.value == canonicalName) return entry.key;
      }
    }

    final parts = trimmed
        .split(RegExp(r'[,/|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length > 1) {
      for (final part in parts.reversed) {
        final code = getCountryCode(part);
        if (code != null) return code;
      }
    }
    return null;
  }

  static String? _canonicalCountryName(String value) {
    if (_flagMap.containsKey(value)) return value;
    final lower = value.toLowerCase();
    for (final country in _flagMap.keys) {
      if (country.toLowerCase() == lower) return country;
    }
    return null;
  }

  static const Set<String> _nonCountryValues = {
    'no',
    'yes',
    'none',
    'n/a',
    'not specified',
    'false',
    'true',
    'null',
    'undefined',
    '—',
    '-',
    'never',
    'socially',
    'frequently',
    'occasionally',
    'regularly',
    'daily',
    'sometimes',
    'always',
  };

  static const Set<String> _commonTwoLetterWords = {
    'no',
    'in',
    'is',
    'it',
    'at',
    'be',
    'by',
    'do',
    'me',
    'my',
    'or',
    'so',
    'to',
    'us',
    'if',
    'of',
    'on',
    'an',
    'as',
    'hi',
    'he',
    'we',
    'go',
    'am',
  };

  static String? getFlagAsset(String? countryName) {
    if (countryName == null || countryName.trim().isEmpty) return null;
    final trimmed = countryName.trim();
    final trimmedLower = trimmed.toLowerCase();

    // 1. Direct exact match
    if (_flagMap.containsKey(trimmed)) return _flagMap[trimmed];

    // 2. ISO alpha-2 code match (the format stored on profiles, e.g. "NO", "AE", "US").
    final upper = trimmed.toUpperCase();
    if (_isoAlpha2Aliases.containsKey(upper)) {
      final is2Letter = trimmed.length == 2;
      // 2-letter strings that collide with common words (e.g. "No" vs "NO") must be strictly uppercase
      // to be treated as ISO 3166-1 alpha-2 country codes.
      if (!is2Letter || trimmed == upper || !_commonTwoLetterWords.contains(trimmedLower)) {
        final isoCountry = _isoAlpha2Aliases[upper];
        if (isoCountry != null && _flagMap.containsKey(isoCountry)) {
          return _flagMap[isoCountry];
        }
      }
    }

    // 3. Filter out non-country values (e.g. "No", "Yes", "None", "Not specified")
    if (_nonCountryValues.contains(trimmedLower)) return null;

    // 4. Common alias match (e.g. "UAE", "USA", "England").
    if (_aliases.containsKey(upper)) {
      final target = _aliases[upper]!;
      if (_flagMap.containsKey(target)) return _flagMap[target];
    }

    // 5. Case-insensitive exact match in _flagMap.
    for (final entry in _flagMap.entries) {
      if (entry.key.toLowerCase() == trimmedLower) {
        return entry.value;
      }
    }

    // 5. Resolve combined values such as "Dubai, AE" or "Cairo / Egypt".
    final parts = trimmed
        .split(RegExp(r'[,/|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length > 1) {
      for (final part in parts.reversed) {
        final asset = getFlagAsset(part);
        if (asset != null) return asset;
      }
    }

    // 6. Safe sub-name match only for names 4+ letters.
    if (trimmedLower.length >= 4) {
      for (final entry in _flagMap.entries) {
        final keyLower = entry.key.toLowerCase();
        if (keyLower.contains(trimmedLower)) {
          return entry.value;
        }
      }
    }

    return null;
  }
}

class CountryFlagWidget extends StatelessWidget {
  final String? country;
  final double width;
  final double height;

  const CountryFlagWidget({
    super.key,
    required this.country,
    this.width = 20,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = CountryHelper.getFlagAsset(country);
    if (assetPath == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(2.5),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}
