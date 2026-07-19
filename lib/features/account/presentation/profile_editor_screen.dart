import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_theme.dart';

class ProfileEditorScreen extends StatefulWidget {
  final String sectionId;

  const ProfileEditorScreen({super.key, required this.sectionId});
  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _db = Supabase.instance.client;
  bool _loading = true, _saving = false, _saveAgain = false;
  String? _saveError;
  String? marital, nationality, residence, raisedIn, body, fitness, dress;
  String? education, study, job, employment, familyValues, religionLevel;
  int? height, weight, childrenCount;
  bool relocate = false, smoking = false, drinking = false, petLover = false;
  bool hasChildren = false, wantsChildren = false;
  RangeValues ageRange = const RangeValues(24, 40);
  List<String> languages = [],
      personality = [],
      interests = [],
      partnerTraits = [];
  List<String> partnerOptions = partnerList;

  static const languageFlags = <String, String>{
    'English': '🇬🇧',
    'Arabic': '🇦🇪',
    'Spanish': '🇪🇸',
    'French': '🇫🇷',
    'German': '🇩🇪',
    'Italian': '🇮🇹',
    'Tagalog': '🇵🇭',
    'Portuguese': '🇵🇹',
    'Turkish': '🇹🇷',
    'Urdu': '🇵🇰',
    'Hindi': '🇮🇳',
    'Dutch': '🇳🇱',
  };
  static const countryNames = <String>[
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Costa Rica',
    'Cote d’Ivoire',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czechia',
    'Democratic Republic of the Congo',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Holy See',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestine',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Republic of the Congo',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];
  static const personalityIcons = <String, String>{
    'Introvert': '🌙',
    'Extrovert': '☀️',
    'Ambivert': '🌓',
    'Calm': '🕊️',
    'Warm': '🤍',
    'Ambitious': '🚀',
    'Playful': '✨',
    'Thoughtful': '💭',
    'Romantic': '🌹',
    'Patient': '🌿',
    'Optimistic': '🌤️',
    'Independent': '🧭',
    'Family-oriented': '🏡',
    'Spiritual': '🤲',
    'Creative': '🎨',
  };
  static const interestIcons = <String, String>{
    'Travel': '✈️',
    'Cooking': '🍳',
    'Reading': '📚',
    'Fitness': '💪',
    'Music': '🎵',
    'Art': '🎨',
    'Nature': '🌿',
    'Photography': '📷',
    'Volunteering': '🤝',
    'Dancing': '💃',
    'Running': '🏃',
    'Swimming': '🏊',
    'Football': '⚽',
    'Basketball': '🏀',
    'Tennis': '🎾',
    'Horse Riding': '🐎',
    'Yoga': '🧘',
    'Pilates': '🧘',
    'Coffee': '☕',
    'Movies': '🎬',
    'Museums': '🏛️',
    'Board Games': '🎲',
    'Hiking': '🥾',
    'Fashion': '👗',
  };
  static const partnerIcons = <String, String>{
    'Kindness': '🤍',
    'Faith': '🤲',
    'Family-minded': '🏡',
    'Loyalty': '💍',
    'Emotional maturity': '🌱',
    'Good communication': '💬',
    'Ambition': '🚀',
    'Sense of humor': '😊',
    'Respect': '🤝',
    'Adventure': '🧭',
  };
  static const personalities = [
    'Introvert',
    'Extrovert',
    'Ambivert',
    'Calm',
    'Warm',
    'Ambitious',
    'Playful',
    'Thoughtful',
    'Romantic',
    'Patient',
    'Optimistic',
    'Independent',
    'Family-oriented',
    'Spiritual',
    'Creative',
  ];
  static const interestsList = [
    'Travel',
    'Cooking',
    'Reading',
    'Fitness',
    'Music',
    'Art',
    'Nature',
    'Photography',
    'Volunteering',
    'Dancing',
    'Running',
    'Swimming',
    'Football',
    'Basketball',
    'Tennis',
    'Horse Riding',
    'Yoga',
    'Pilates',
    'Coffee',
    'Movies',
    'Museums',
    'Board Games',
    'Hiking',
    'Fashion',
  ];
  static const partnerList = [
    'Kindness',
    'Faith',
    'Family-minded',
    'Loyalty',
    'Emotional maturity',
    'Good communication',
    'Ambition',
    'Sense of humor',
    'Respect',
    'Adventure',
  ];

  String get _title => switch (widget.sectionId) {
    'basic' => 'Basic Information',
    'appearance' => 'Appearance',
    'education' => 'Education & Career',
    'personality' => 'Personality',
    'lifestyle' => 'Interests & Lifestyle',
    'family' => 'Family & Children',
    'faith' => 'Faith & Values',
    'partner' => 'Partner Expectations',
    _ => 'Edit Profile',
  };

  String get _subtitle => switch (widget.sectionId) {
    'basic' =>
      'Help us personalize your matches by sharing a few details about you.',
    'appearance' =>
      'Share how you present yourself and what helps you feel your best.',
    'education' => 'Tell us about your studies and professional journey.',
    'personality' => 'Choose the traits that best describe who you are.',
    'lifestyle' =>
      'Share the interests and everyday choices that shape your life.',
    'family' => 'Help matches understand your hopes for family and children.',
    'faith' => 'Share how faith and values guide your life.',
    'partner' =>
      'Describe the qualities and age range you hope to find in a partner.',
    _ => 'Add the details that help us find your best matches.',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final id = _db.auth.currentUser!.id;
      final r = await Future.wait<dynamic>([
        _db
            .from('profiles')
            .select('public_name, gender')
            .eq('id', id)
            .maybeSingle(),
        _db
            .from('profile_optional_details')
            .select()
            .eq('user_id', id)
            .maybeSingle(),
        _db.from('profile_traits').select('trait').eq('user_id', id),
        _db.from('profile_interests').select('interest').eq('user_id', id),
        _db.from('user_filters').select().eq('user_id', id).maybeSingle(),
      ]);
      final d = r[1] as Map<String, dynamic>? ?? {};
      final f = r[4] as Map<String, dynamic>? ?? {};
      final profile = (r[0] as Map<String, dynamic>?) ?? {};
      var options = partnerList;
      try {
        final rows = await _db
            .from('partner_trait_options')
            .select('label')
            .eq('gender', profile['gender'] ?? 'Male')
            .eq('is_active', true)
            .order('sort_order');
        if ((rows as List).isNotEmpty) {
          options = rows.map((row) => row['label'].toString()).toList();
        }
      } catch (_) {
        // Seeded defaults keep the editor usable before the migration runs.
      }
      setState(() {
        partnerOptions = options;
        marital = d['marital_status'];
        nationality = d['nationality'];
        residence = d['country_of_residence'];
        raisedIn = d['raised_in'];
        relocate = d['willing_to_relocate'] == true;
        languages = List<String>.from(d['languages_spoken'] ?? const []);
        height = (d['height'] as num?)?.toInt();
        weight = (d['weight'] as num?)?.toInt();
        body = d['body_type'];
        fitness = d['fitness_level'];
        dress = d['style_of_dress'];
        education = d['education_level'];
        study = d['field_of_study'];
        job = d['job_title'];
        employment = d['employment_status'];
        smoking = d['smoking'] == 'Yes';
        drinking = d['drinking'] == 'Yes';
        petLover = d['pet_lover'] == true;
        hasChildren = d['children'] == 'Yes';
        childrenCount = (d['children_count'] as num?)?.toInt();
        wantsChildren = d['wants_children'] == true;
        familyValues = d['family_values'];
        religionLevel = d['religion_level'];
        personality = _list(r[2], 'trait');
        interests = _list(r[3], 'interest');
        partnerTraits = List<String>.from(
          f['preferred_partner_traits'] ?? const [],
        );
        ageRange = RangeValues(
          (f['min_age'] as num?)?.toDouble() ?? 24,
          (f['max_age'] as num?)?.toDouble() ?? 40,
        );
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load profile details: $e')),
        );
      }
    }
  }

  List<String> _list(dynamic rows, String key) => (rows as List)
      .map((r) => r[key]?.toString())
      .whereType<String>()
      .toList();

  Future<void> _autoSave(VoidCallback update) async {
    setState(update);
    await _save();
  }

  Future<void> _save() async {
    if (_saving) {
      _saveAgain = true;
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      do {
        _saveAgain = false;
        try {
          final id = _db.auth.currentUser!.id;
          await _db.from('profile_optional_details').upsert({
            'user_id': id,
            'marital_status': marital,
            'nationality': nationality,
            'country_of_residence': residence,
            'raised_in': raisedIn,
            'willing_to_relocate': relocate,
            'languages_spoken': languages,
            'height': height,
            'weight': weight,
            'body_type': body,
            'fitness_level': fitness,
            'style_of_dress': dress,
            'education_level': education,
            'field_of_study': study,
            'job_title': job,
            'employment_status': employment,
            'smoking': smoking ? 'Yes' : 'No',
            'drinking': drinking ? 'Yes' : 'No',
            'pet_lover': petLover,
            'children': hasChildren ? 'Yes' : 'No',
            'children_count': childrenCount,
            'wants_children': wantsChildren,
            'family_values': familyValues,
            'religion_level': religionLevel,
          }, onConflict: 'user_id');
          await _replace('profile_traits', 'trait', personality);
          await _replace('profile_interests', 'interest', interests);
          await _db.from('user_filters').upsert({
            'user_id': id,
            'min_age': ageRange.start.round(),
            'max_age': ageRange.end.round(),
            'preferred_partner_traits': partnerTraits,
          }, onConflict: 'user_id');
        } catch (e) {
          if (mounted) {
            setState(() => _saveError = 'Could not save changes');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not save changes: $e')),
            );
          }
          break;
        }
      } while (_saveAgain);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _replace(
    String table,
    String column,
    List<String> values,
  ) async {
    final id = _db.auth.currentUser!.id;
    await _db.from(table).delete().eq('user_id', id);
    if (values.isNotEmpty)
      await _db
          .from(table)
          .insert(values.map((v) => {'user_id': id, column: v}).toList());
  }

  Future<void> _choose(
    String title,
    List<String> options,
    String? current,
    ValueChanged<String> save, {
    Map<String, String>? icons,
    Map<String, String>? assetIcons,
  }) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChoiceSheet(title, options, current, icons, assetIcons),
    );
    if (value != null) await _autoSave(() => save(value));
  }

  Future<void> _multi(
    String title,
    List<String> options,
    List<String> current,
    ValueChanged<List<String>> save, {
    Map<String, String>? icons,
    int? maxSelections,
  }) async {
    final value = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MultiSheet(
        title,
        options,
        current,
        icons,
        maxSelections: maxSelections,
      ),
    );
    if (value != null) await _autoSave(() => save(value));
  }

  Map<String, String> get _countryAssetIcons => {
    for (final country in countryNames) country: _countryFlagAsset(country),
  };

  static String _countryFlagAsset(String country) {
    final slug = country
        .toLowerCase()
        .replaceAll('’', '_')
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'Assets/flags/$slug.png';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _ProfileEditorShimmer(title: _title);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _title,
          style: AppTheme.serifHeadline(
            fontSize: 25,
            color: AppColors.primaryBurgundy,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _saveError == null
                          ? Icons.cloud_done_outlined
                          : Icons.error_outline_rounded,
                      color: _saveError == null
                          ? AppColors.primaryBurgundy
                          : const Color(0xFFB3261E),
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF9), Color(0xFFFFF4EF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
          children: [
            const _HeaderOrnament(),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF665E62),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 26),
            if (widget.sectionId == 'basic')
              _section('Basic Information', Icons.person_outline_rounded, [
                _row(
                  'Marital Status',
                  marital ?? 'Add status',
                  () => _choose(
                    'Marital Status',
                    [
                      'Never married',
                      'Separated',
                      'Divorced',
                      'Annulled',
                      'Widowed',
                      'Prefer not to say',
                    ],
                    marital,
                    (v) => marital = v,
                  ),
                ),
                _countryRow(
                  'Nationality',
                  nationality,
                  'Choose nationality',
                  () => _choose(
                    'Nationality',
                    countryNames,
                    nationality,
                    (v) => nationality = v,
                    assetIcons: _countryAssetIcons,
                  ),
                ),
                _countryRow(
                  'Country of Residence',
                  residence,
                  'Choose country',
                  () => _choose(
                    'Country of Residence',
                    countryNames,
                    residence,
                    (v) => residence = v,
                    assetIcons: _countryAssetIcons,
                  ),
                ),
                _countryRow(
                  'Raised In',
                  raisedIn,
                  'Choose country',
                  () => _choose(
                    'Raised In',
                    countryNames,
                    raisedIn,
                    (v) => raisedIn = v,
                    assetIcons: _countryAssetIcons,
                  ),
                ),
                _switch('Willing to Relocate', relocate, (v) => relocate = v),
                _row(
                  'Languages Spoken',
                  languages.isEmpty
                      ? 'Choose languages'
                      : languages
                            .map((v) => (languageFlags[v] ?? '') + ' ' + v)
                            .join(', '),
                  () => _multi(
                    'Languages Spoken',
                    languageFlags.keys.toList(),
                    languages,
                    (v) => languages = v,
                    icons: languageFlags,
                  ),
                ),
              ]),
            if (widget.sectionId == 'appearance')
              _section('Appearance', Icons.auto_awesome_outlined, [
                _numberRow('Height', height, 'cm', (v) => height = v, 130, 230),
                _row(
                  'Body Type',
                  body ?? 'Add body type',
                  () => _choose(
                    'Body Type',
                    ['Slim', 'Average', 'Athletic', 'Curvy', 'Plus-size'],
                    body,
                    (v) => body = v,
                  ),
                ),
                _row(
                  'Fitness Level',
                  fitness ?? 'Add fitness level',
                  () => _choose(
                    'Fitness Level',
                    [
                      'Rarely active',
                      'Moderately active',
                      'Very active',
                      'Athletic',
                    ],
                    fitness,
                    (v) => fitness = v,
                  ),
                ),
                _numberRow(
                  'Weight · Private',
                  weight,
                  'kg · optional',
                  (v) => weight = v,
                  35,
                  250,
                ),
                _row(
                  'Style of Dress',
                  dress ?? 'Add style',
                  () => _choose(
                    'Style of Dress',
                    [
                      'Classic',
                      'Modest',
                      'Casual',
                      'Elegant',
                      'Sporty',
                      'Creative',
                    ],
                    dress,
                    (v) => dress = v,
                  ),
                ),
              ]),
            if (widget.sectionId == 'education')
              _section('Education & Career', Icons.school_outlined, [
                _row(
                  'Education Level',
                  education ?? 'Add education',
                  () => _choose(
                    'Education Level',
                    [
                      'High school',
                      'Diploma',
                      'Bachelor’s degree',
                      'Master’s degree',
                      'Doctorate',
                      'Vocational education',
                      'Other',
                    ],
                    education,
                    (v) => education = v,
                  ),
                ),
                _textRow('Field of Study', study, (v) => study = v),
                _textRow('Job Title', job, (v) => job = v),
                _row(
                  'Employment Status',
                  employment ?? 'Add status',
                  () => _choose(
                    'Employment Status',
                    [
                      'Employed',
                      'Self-employed',
                      'Business owner',
                      'Student',
                      'Not working',
                      'Retired',
                    ],
                    employment,
                    (v) => employment = v,
                  ),
                ),
              ]),
            if (widget.sectionId == 'personality')
              _section('Personality', Icons.psychology_outlined, [
                _row(
                  'My Personality',
                  personality.isEmpty
                      ? 'Choose traits'
                      : personality.join(', '),
                  () => _multi(
                    'My Personality',
                    personalities,
                    personality,
                    (v) => personality = v,
                    icons: personalityIcons,
                    maxSelections: 8,
                  ),
                ),
              ]),
            if (widget.sectionId == 'lifestyle')
              _section('Interests & Lifestyle', Icons.explore_outlined, [
                _row(
                  'Interests, Hobbies & Activities',
                  interests.isEmpty ? 'Choose interests' : interests.join(', '),
                  () => _multi(
                    'Interests & Activities',
                    interestsList,
                    interests,
                    (v) => interests = v,
                    icons: interestIcons,
                    maxSelections: 15,
                  ),
                ),
                _switch('Smoking', smoking, (v) => smoking = v),
                _switch('Drinking', drinking, (v) => drinking = v),
                _switch('Pet Lover', petLover, (v) => petLover = v),
              ]),
            if (widget.sectionId == 'family')
              _section('Family & Children', Icons.family_restroom_outlined, [
                _switch(
                  'Do You Have Children?',
                  hasChildren,
                  (v) => hasChildren = v,
                ),
                if (hasChildren)
                  _numberRow(
                    'Number of Kids · Optional',
                    childrenCount,
                    '',
                    (v) => childrenCount = v,
                    1,
                    15,
                  ),
                _switch(
                  'Do You Want Children?',
                  wantsChildren,
                  (v) => wantsChildren = v,
                ),
                _row(
                  'Family Values',
                  familyValues ?? 'Add family values',
                  () => _choose(
                    'Family Values',
                    [
                      'Very important',
                      'Important',
                      'Balanced',
                      'Private matter',
                    ],
                    familyValues,
                    (v) => familyValues = v,
                  ),
                ),
              ]),
            if (widget.sectionId == 'faith')
              _section('Faith & Values', Icons.auto_awesome, [
                _row(
                  'Religion Level',
                  religionLevel ?? 'Add level',
                  () => _choose(
                    'Religion Level',
                    [
                      'Slightly Religious',
                      'Moderately Religious',
                      'Practising',
                      'Very Religious',
                    ],
                    religionLevel,
                    (v) => religionLevel = v,
                  ),
                ),
              ]),
            if (widget.sectionId == 'partner')
              _section('Partner Expectations', Icons.favorite_border_rounded, [
                _row(
                  'My Ideal Partner',
                  partnerTraits.isEmpty
                      ? 'Choose partner traits'
                      : partnerTraits.join(', '),
                  () => _multi(
                    'My Ideal Partner',
                    partnerOptions,
                    partnerTraits,
                    (v) => partnerTraits = v,
                    icons: partnerIcons,
                    maxSelections: 8,
                  ),
                ),
                _ageRangeRow(),
              ]),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF2E6E1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120E0306),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(children: _withDividers(children)),
      );

  List<Widget> _withDividers(List<Widget> children) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i != children.length - 1) {
        result.add(
          const Divider(height: 1, indent: 72, color: Color(0xFFF1E4DF)),
        );
      }
    }
    return result;
  }

  Widget _countryRow(
    String label,
    String? value,
    String empty,
    VoidCallback tap,
  ) => InkWell(
    onTap: tap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 17, 16, 17),
      child: Row(
        children: [
          _FieldIcon(icon: _iconFor(label)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2F171C),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: value == null || value.isEmpty
                ? Text(
                    empty,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF987984),
                      fontSize: 13,
                      height: 1.2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _CountryFlag(asset: _countryFlagAsset(value)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF987984),
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: Color(0xFF987984),
          ),
        ],
      ),
    ),
  );

  Widget _row(String label, String value, VoidCallback tap) => InkWell(
    onTap: tap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 17, 16, 17),
      child: Row(
        children: [
          _FieldIcon(icon: _iconFor(label)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2F171C),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF987984),
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: Color(0xFF987984),
          ),
        ],
      ),
    ),
  );
  Widget _switch(String label, bool value, ValueChanged<bool> save) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
    child: Row(
      children: [
        _FieldIcon(icon: _iconFor(label)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2F171C),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_switchHint(label) case final hint?) ...[
                const SizedBox(height: 3),
                Text(
                  hint,
                  style: const TextStyle(
                    color: Color(0xFFA28D94),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        _YesNoToggle(value: value, onChanged: (v) => _autoSave(() => save(v))),
      ],
    ),
  );

  Widget _ageRangeRow() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldIcon(icon: Icons.calendar_month_outlined),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Preferred Age Range',
                      style: TextStyle(
                        color: Color(0xFF2F171C),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${ageRange.start.round()}–${ageRange.end.round()} years',
                    style: const TextStyle(
                      color: AppColors.primaryBurgundy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: ageRange,
                min: 18,
                max: 80,
                divisions: 62,
                activeColor: AppColors.primaryBurgundy,
                inactiveColor: const Color(0xFFF0DCD4),
                onChanged: (v) => setState(() => ageRange = v),
                onChangeEnd: (v) => _autoSave(() => ageRange = v),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String? _switchHint(String label) => switch (label) {
    'Willing to Relocate' => 'Show matches from other locations',
    'Smoking' || 'Drinking' => 'Your lifestyle preference',
    'Pet Lover' => 'Let matches know you enjoy pets',
    'Do You Have Children?' => 'Share your current family situation',
    'Do You Want Children?' => 'Share your plans for the future',
    _ => null,
  };

  IconData _iconFor(String label) => switch (label) {
    'Marital Status' => Icons.favorite_border_rounded,
    'Nationality' => Icons.public_rounded,
    'Country of Residence' => Icons.location_on_outlined,
    'Raised In' => Icons.home_outlined,
    'Willing to Relocate' => Icons.flight_takeoff_rounded,
    'Languages Spoken' => Icons.forum_outlined,
    'Height' => Icons.straighten_rounded,
    'Body Type' => Icons.accessibility_new_rounded,
    'Fitness Level' => Icons.fitness_center_rounded,
    'Weight · Private' => Icons.monitor_weight_outlined,
    'Style of Dress' => Icons.checkroom_outlined,
    'Profile Photos' => Icons.photo_library_outlined,
    'Education Level' => Icons.school_outlined,
    'Field of Study' => Icons.menu_book_outlined,
    'Job Title' => Icons.work_outline_rounded,
    'Employment Status' => Icons.badge_outlined,
    'My Personality' => Icons.psychology_outlined,
    'Interests, Hobbies & Activities' => Icons.explore_outlined,
    'Smoking' => Icons.smoke_free_rounded,
    'Drinking' => Icons.local_bar_outlined,
    'Pet Lover' => Icons.pets_outlined,
    'Do You Have Children?' => Icons.family_restroom_outlined,
    'Number of Kids · Optional' => Icons.child_care_outlined,
    'Do You Want Children?' => Icons.child_friendly_outlined,
    'Family Values' => Icons.diversity_3_outlined,
    'Religion Level' => Icons.auto_awesome_outlined,
    'My Ideal Partner' => Icons.favorite_outline_rounded,
    _ => Icons.edit_outlined,
  };
  Widget _textRow(String label, String? value, ValueChanged<String> save) =>
      _row(label, value ?? 'Add details', () async {
        final c = TextEditingController(text: value);
        final r = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(label),
            content: TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        c.dispose();
        if (r != null && r.isNotEmpty) await _autoSave(() => save(r));
      });
  Widget _numberRow(
    String label,
    int? value,
    String suffix,
    ValueChanged<int> save,
    int min,
    int max,
  ) => _row(
    label,
    value == null ? 'Add value' : value.toString() + ' ' + suffix,
    () async {
      final c = TextEditingController(text: value?.toString());
      final r = await showDialog<int>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(label),
          content: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: min.toString() + '–' + max.toString(),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(c.text);
                if (n != null && n >= min && n <= max)
                  Navigator.pop(context, n);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
      c.dispose();
      if (r != null) await _autoSave(() => save(r));
    },
  );
}

class _HeaderOrnament extends StatelessWidget {
  const _HeaderOrnament();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 46, child: Divider(color: Color(0xFFEBCFC5))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13),
          child: Icon(
            Icons.favorite_border_rounded,
            color: Color(0xFFD9896F),
            size: 25,
          ),
        ),
        SizedBox(width: 46, child: Divider(color: Color(0xFFEBCFC5))),
      ],
    );
  }
}

class _FieldIcon extends StatelessWidget {
  final IconData icon;

  const _FieldIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0EC),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primaryBurgundy, size: 21),
    );
  }
}

class _CountryFlag extends StatelessWidget {
  final String asset;
  final double width;
  final double height;

  const _CountryFlag({required this.asset, this.width = 34, this.height = 22});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EC),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFE7D8D1)),
          ),
        ),
      ),
    );
  }
}

class _ChoiceLeading extends StatelessWidget {
  final String? textIcon;
  final String? assetIcon;

  const _ChoiceLeading({this.textIcon, this.assetIcon});

  @override
  Widget build(BuildContext context) {
    if (assetIcon != null) {
      return _CountryFlag(asset: assetIcon!, width: 42, height: 28);
    }
    if (textIcon != null) {
      return Text(textIcon!, style: const TextStyle(fontSize: 22));
    }
    return const SizedBox.shrink();
  }
}

class _YesNoToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _YesNoToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECE8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7D8D1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _YesNoSegment(
            label: 'No',
            selected: !value,
            onTap: () => onChanged(false),
          ),
          _YesNoSegment(
            label: 'Yes',
            selected: value,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _YesNoSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YesNoSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 48,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBurgundy : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x226B0F2A),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF8A7477),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProfileEditorShimmer extends StatefulWidget {
  final String title;
  const _ProfileEditorShimmer({required this.title});

  @override
  State<_ProfileEditorShimmer> createState() => _ProfileEditorShimmerState();
}

class _ProfileEditorShimmerState extends State<_ProfileEditorShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: AppTheme.serifHeadline(
            fontSize: 25,
            color: AppColors.primaryBurgundy,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final shimmer = Color.lerp(
            const Color(0xFFF1E6E1),
            const Color(0xFFFFFBF9),
            _controller.value,
          )!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _HeaderOrnament(),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  height: 13,
                  width: 250,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  height: 13,
                  width: 190,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF2E6E1)),
                ),
                child: Column(
                  children: List.generate(
                    5,
                    (index) => Column(
                      children: [
                        SizedBox(
                          height: 76,
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: shimmer,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Container(
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: shimmer,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Container(
                                width: 70,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: shimmer,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index != 4)
                          const Divider(
                            height: 1,
                            indent: 54,
                            color: Color(0xFFF1E4DF),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                height: 58,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChoiceSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  final Map<String, String>? icons;
  final Map<String, String>? assetIcons;
  const _ChoiceSheet(
    this.title,
    this.options,
    this.selected,
    this.icons,
    this.assetIcons,
  );
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .56,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final option = options[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _ChoiceLeading(
                      textIcon: icons?[option],
                      assetIcon: assetIcons?[option],
                    ),
                    title: Text(option),
                    trailing: option == selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryBurgundy,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, option),
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

class _MultiSheet extends StatefulWidget {
  final String title;
  final List<String> options, initial;
  final Map<String, String>? icons;
  final int? maxSelections;
  const _MultiSheet(
    this.title,
    this.options,
    this.initial,
    this.icons, {
    this.maxSelections,
  });
  @override
  State<_MultiSheet> createState() => _MultiSheetState();
}

class _MultiSheetState extends State<_MultiSheet> {
  late final Set<String> selected = {...widget.initial};

  String get _selectionLabel {
    if (widget.title.contains('Personality')) return 'traits';
    if (widget.title.contains('Interest')) return 'interests';
    if (widget.title.contains('Partner')) return 'qualities';
    return 'items';
  }

  void _toggle(String option) {
    final active = selected.contains(option);
    if (!active &&
        widget.maxSelections != null &&
        selected.length >= widget.maxSelections!) {
      return;
    }
    setState(() => active ? selected.remove(option) : selected.add(option));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .72,
    minChildSize: .45,
    maxChildSize: .92,
    builder: (_, scroll) => Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (widget.maxSelections != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Select up to ${widget.maxSelections} $_selectionLabel',
                        style: const TextStyle(
                          color: Color(0xFF3A3334),
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selected.toList()),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (selected.isNotEmpty)
            Text(
              '${selected.length}${widget.maxSelections == null ? '' : '/${widget.maxSelections}'} selected',
              style: const TextStyle(
                color: Color(0xFF5F5557),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (selected.isNotEmpty) const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: scroll,
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                children: widget.options.map((option) {
                  final active = selected.contains(option);
                  final disabled =
                      !active &&
                      widget.maxSelections != null &&
                      selected.length >= widget.maxSelections!;
                  return _SelectChip(
                    label: option,
                    icon: widget.icons?[option] ?? '✦',
                    active: active,
                    disabled: disabled,
                    onTap: () => _toggle(option),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SelectChip extends StatelessWidget {
  final String label, icon;
  final bool active, disabled;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? .45 : 1,
      child: Material(
        color: active ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: active ? Colors.black : const Color(0xFFE9E5E2),
              ),
              boxShadow: active
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
