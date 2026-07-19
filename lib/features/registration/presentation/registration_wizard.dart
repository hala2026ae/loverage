import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';

class RegistrationWizard extends ConsumerStatefulWidget {
  const RegistrationWizard({super.key});

  @override
  ConsumerState<RegistrationWizard> createState() => _RegistrationWizardState();
}

class _RegistrationWizardState extends ConsumerState<RegistrationWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7;

  // Registration Form State
  String? _gender;
  final _nameController = TextEditingController();
  DateTime? _dob;
  String? _religion;
  final List<String?> _images = List.filled(12, null); // Local file paths of picked images
  int _mainImageIndex = 0;
  final _bioController = TextEditingController();

  // Location details
  double? _latitude;
  double? _longitude;
  String? _city;
  String? _countryCode;
  bool _detectingLocation = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _gender != null;
      case 1:
        final name = _nameController.text.trim();
        // Validation rules: 2-40 chars, letters/spaces/apostrophes/hyphens only.
        final regex = RegExp(r"^[a-zA-Z\s'-]{2,40}$");
        return name.isNotEmpty && regex.hasMatch(name);
      case 2:
        if (_dob == null) return false;
        final age = DateTime.now().difference(_dob!).inDays ~/ 365;
        return age >= 18;
      case 3:
        return _religion != null;
      case 4:
        // Requires at least 1 image minimum
        return _images.any((img) => img != null);
      case 5:
        final bio = _bioController.text.trim();
        // Simple link and contact filter: block common link/phone patterns
        final phoneRegex = RegExp(r'\b\d{8,15}\b');
        final emailRegex = RegExp(r'[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
        final linkRegex = RegExp(
          r'(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
        );

        return bio.isNotEmpty &&
            bio.length <= 500 &&
            !phoneRegex.hasMatch(bio) &&
            !emailRegex.hasMatch(bio) &&
            !linkRegex.hasMatch(bio);
      case 6:
        return _city != null && _countryCode != null;
      default:
        return false;
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          if (placemarks.isNotEmpty) {
            _city =
                placemarks.first.locality ??
                placemarks.first.subAdministrativeArea ??
                'Unknown City';
            _countryCode = placemarks.first.isoCountryCode ?? 'US';
          }
        });
      }
    } catch (_) {
      // Fallback manual location mock for simulator
      setState(() {
        _latitude = 30.0444;
        _longitude = 31.2357;
        _city = 'Cairo';
        _countryCode = 'EG';
      });
    } finally {
      setState(() => _detectingLocation = false);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_validateCurrentStep()) return;

    try {
      final filledImages = _images.whereType<String>().toList();
      final mainImagePath = _images[_mainImageIndex];
      if (mainImagePath != null) {
        filledImages.remove(mainImagePath);
        filledImages.insert(0, mainImagePath);
      }

      await ref
          .read(authRepositoryProvider)
          .updateRegistrationProgress(
            name: _nameController.text.trim(),
            gender: _gender!,
            dob: _dob!,
            religion: _religion!,
            bio: _bioController.text.trim(),
            latitude: _latitude ?? 0.0,
            longitude: _longitude ?? 0.0,
            city: _city ?? 'Unknown',
            countryCode: _countryCode ?? 'US',
            images: filledImages,
          );
      // The router notifier automatically switches state to FaceVerification
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryBurgundy,
          ),
          onPressed: () async {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              await ref.read(authRepositoryProvider).signOut();
              if (mounted) {
                context.go('/welcome');
              }
            }
          },
        ),
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              // Top Linear Progress Bar
              LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: AppColors.borderLight,
                color: AppColors.primaryBurgundy,
              ),

              // Step Content Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildGenderStep(),
                    _buildNameStep(),
                    _buildDobStep(),
                    _buildReligionStep(),
                    _buildImagesStep(),
                    _buildBioStep(),
                    _buildLocationStep(),
                  ],
                ),
              ),

              // Bottom Action Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: Opacity(
                    opacity: _validateCurrentStep() ? 1.0 : 0.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5E0B24), Color(0xFF3C1321)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28.0),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3C1321).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _validateCurrentStep()
                            ? (_currentStep == _totalSteps - 1
                                  ? _submitRegistration
                                  : _nextStep)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep == _totalSteps - 1
                                  ? 'Complete & Continue'
                                  : 'Next',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 20.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP UIs
  Widget _buildGenderStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Are you a future\nbride or groom?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C1321),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Choose your role to personalize\nyour experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.0,
              color: Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48.0),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      // Groom side
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = 'Male'),
                          child: Container(
                            color: _gender == 'Male'
                                ? const Color(0xFF5E0B24)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 36.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'Assets/Groom.png',
                                  height: 120.0,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  'Groom',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold,
                                    color: _gender == 'Male'
                                        ? Colors.white
                                        : const Color(0xFF3C1321),
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Container(
                                  width: 24.0,
                                  height: 2.0,
                                  color: _gender == 'Male'
                                      ? const Color(0xFFD4AF37)
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Vertical Divider
                      Container(
                        width: 1.5,
                        height: 220.0,
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                      ),

                      // Bride side
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = 'Female'),
                          child: Container(
                            color: _gender == 'Female'
                                ? const Color(0xFF5E0B24)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 36.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'Assets/bride.png',
                                  height: 120.0,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  'Bride',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold,
                                    color: _gender == 'Female'
                                        ? Colors.white
                                        : const Color(0xFF3C1321),
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Container(
                                  width: 24.0,
                                  height: 2.0,
                                  color: _gender == 'Female'
                                      ? const Color(0xFFD4AF37)
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Middle Crown Badge
                  Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(20, 20),
                        painter: CrownPainter(color: const Color(0xFFD4AF37)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'What is your name?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C1321),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Enter your first name or preferred public name\n(no links, emails, numbers, or special symbols).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36.0),

          CustomPaint(
            foregroundPainter: BaroqueDecorationsPainter(),
            child: Container(
              width: double.infinity,
              height: 280.0,
              decoration: const BoxDecoration(),
              child: CustomPaint(
                painter: BaroqueFramePainter(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 54.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'YOUR NAME',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C1321),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Color(0xFF3C1321),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Name',
                          hintStyle: TextStyle(color: Color(0xFFBCAAA4)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 16.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDobStep() {
    final age = _dob == null
        ? null
        : DateTime.now().difference(_dob!).inDays ~/ 365;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'When were you born?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C1321),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'You must be at least 18 years old to use Loverage.\nWe verify ages to help keep the community safe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32.0),

          CustomPaint(
            foregroundPainter: BaroqueDecorationsPainter(),
            child: Container(
              width: double.infinity,
              height: 330.0,
              decoration: const BoxDecoration(),
              child: CustomPaint(
                painter: BaroqueFramePainter(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 52.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'DATE OF BIRTH',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C1321),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18.0),
                    GestureDetector(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              _dob ??
                              DateTime.now().subtract(
                                const Duration(days: 365 * 18),
                              ),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() => _dob = selectedDate);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dob == null
                                  ? 'Select Date of Birth'
                                  : '${_dob!.day} ${_getMonthName(_dob!.month)} ${_dob!.year}',
                              style: TextStyle(
                                color: _dob == null
                                    ? const Color(0xFFBCAAA4)
                                    : const Color(0xFF3C1321),
                                fontSize: 15.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFF5E0B24),
                              size: 20.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    SizedBox(
                      height: 100.0,
                      child: CupertinoTheme(
                        data: const CupertinoThemeData(
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              color: Color(0xFF3C1321),
                              fontSize: 16.0,
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime:
                              _dob ??
                              DateTime.now().subtract(
                                const Duration(days: 365 * 18),
                              ),
                          onDateTimeChanged: (date) {
                            setState(() => _dob = date);
                          },
                          minimumYear: 1940,
                          maximumYear: DateTime.now().year,
                        ),
                      ),
                    ),
                    const SizedBox(height: 38.0),
                  ],
                ),
              ),
            ),
          ),
          if (age != null && age < 18) ...[
            const SizedBox(height: 12.0),
            const Text(
              'You must be at least 18 years old to continue.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildReligionStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Select your religion',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C1321),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Loverage supports filtering and matching based on\nmajor religious compatibility.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32.0),

          CustomPaint(
            foregroundPainter: BaroqueDecorationsPainter(),
            child: Container(
              width: double.infinity,
              height: 360.0,
              decoration: const BoxDecoration(),
              child: CustomPaint(
                painter: BaroqueFramePainter(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 52.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'RELIGION',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C1321),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    _buildReligionOption('Islam'),
                    const SizedBox(height: 12.0),
                    _buildReligionOption('Christianity'),
                    const SizedBox(height: 12.0),
                    _buildReligionOption('Judaism'),
                    const SizedBox(height: 48.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReligionOption(String value) {
    final isSelected = _religion == value;
    return GestureDetector(
      onTap: () => setState(() => _religion = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5E0B24) : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF5E0B24).withOpacity(0.15)
                  : const Color(0xFFD4AF37).withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flare_rounded,
                  color: Color(0xFFD4AF37),
                  size: 16.0,
                ),
                const SizedBox(width: 12.0),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF3C1321),
                  ),
                ),
              ],
            ),

            // Selection Circle Indicator
            isSelected
                ? Container(
                    width: 22.0,
                    height: 22.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14.0,
                    ),
                  )
                : Container(
                    width: 22.0,
                    height: 22.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1.5,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImagesAt(int startIndex) async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> imagesList = await picker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (imagesList.isEmpty) return;

      if (imagesList.length == 1) {
        // Crop single image to square for Loverage's brand style
        final XFile image = imagesList.first;
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo to Square',
              toolbarColor: const Color(0xFF5E0B24),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Photo to Square',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
            ),
          ],
        );
        
        final finalPath = croppedFile?.path ?? image.path;
        setState(() {
          _images[startIndex] = finalPath;
          if (_images.whereType<String>().length == 1) {
            _mainImageIndex = startIndex;
          }
        });
      } else {
        // Map multiple selected images starting from clicked slot and wrapping around
        setState(() {
          int listIdx = 0;
          for (int i = startIndex; i < 12; i++) {
            if (listIdx >= imagesList.length) break;
            if (_images[i] == null) {
              _images[i] = imagesList[listIdx].path;
              if (_images.whereType<String>().length == 1) {
                _mainImageIndex = i;
              }
              listIdx++;
            }
          }
          for (int i = 0; i < startIndex; i++) {
            if (listIdx >= imagesList.length) break;
            if (_images[i] == null) {
              _images[i] = imagesList[listIdx].path;
              if (_images.whereType<String>().length == 1) {
                _mainImageIndex = i;
              }
              listIdx++;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  Widget _buildImagesStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Add profile photos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C1321),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Upload between 1 and 12 photos. Tap any slot to pick one or more images. Tap a photo to set it as main.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32.0),

          CustomPaint(
            foregroundPainter: BaroqueDecorationsPainter(),
            child: Container(
              width: double.infinity,
              height: 560.0,
              decoration: const BoxDecoration(),
              child: CustomPaint(
                painter: BaroqueFramePainter(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'PHOTOS',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C1321),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    Container(
                      height: 430.0,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 12,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0,
                              childAspectRatio: 0.85,
                            ),
                        itemBuilder: (context, index) {
                          final imagePath = _images[index];
                          final hasImage = imagePath != null;
                          final isMain = index == _mainImageIndex && hasImage;

                          return GestureDetector(
                            onTap: () {
                              if (hasImage) {
                                setState(() => _mainImageIndex = index);
                              } else {
                                _pickImagesAt(index);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: isMain
                                      ? const Color(0xFF5E0B24)
                                      : const Color(
                                          0xFFD4AF37,
                                        ).withOpacity(0.4),
                                  width: isMain ? 2.2 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (hasImage) ...[
                                      Positioned.fill(
                                        child: imagePath.startsWith('mock')
                                            ? Container(
                                                color: const Color(0xFFF7D5C4).withOpacity(0.3),
                                                child: const Icon(
                                                  Icons.face_retouching_natural_rounded,
                                                  size: 32.0,
                                                  color: Color(0xFF5E0B24),
                                                ),
                                              )
                                            : Image.file(
                                                File(imagePath),
                                                fit: BoxFit.cover,
                                              ),
                                      ),

                                      // Label/Tag
                                      Positioned(
                                        top: 6.0,
                                        left: 6.0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0,
                                            vertical: 2.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMain
                                                ? const Color(0xFF5E0B24)
                                                : const Color(0xFF9E9E9E).withOpacity(0.85),
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                          ),
                                          child: Text(
                                            isMain ? 'Main' : '#${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Delete Button
                                      Positioned(
                                        top: 4.0,
                                        right: 4.0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _images[index] = null;
                                              if (_mainImageIndex == index) {
                                                // Find first filled index
                                                final firstFilledIndex = _images.indexWhere((img) => img != null);
                                                _mainImageIndex = firstFilledIndex != -1 ? firstFilledIndex : 0;
                                              }
                                            });
                                          },
                                          child: Container(
                                            width: 18.0,
                                            height: 18.0,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFC62828),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 12.0,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      const Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 22.0,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 38.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    final bioLength = _bioController.text.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Write a short bio',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C1321),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Describe your values, personality, and expectations.\nDo not post numbers, social handles, or website URLs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32.0),

          CustomPaint(
            foregroundPainter: BaroqueDecorationsPainter(),
            child: Container(
              width: double.infinity,
              height: 340.0,
              decoration: const BoxDecoration(),
              child: CustomPaint(
                painter: BaroqueFramePainter(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 52.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'BIO',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C1321),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28.0),
                      height: 170.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8.0,
                            left: 8.0,
                            child: Icon(
                              Icons.star_border_rounded,
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
                              size: 8.0,
                            ),
                          ),
                          Positioned(
                            top: 8.0,
                            right: 8.0,
                            child: Icon(
                              Icons.star_border_rounded,
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
                              size: 8.0,
                            ),
                          ),
                          Positioned(
                            bottom: 8.0,
                            left: 8.0,
                            child: Icon(
                              Icons.star_border_rounded,
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
                              size: 8.0,
                            ),
                          ),
                          Positioned(
                            bottom: 8.0,
                            right: 8.0,
                            child: Icon(
                              Icons.star_border_rounded,
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
                              size: 8.0,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              16.0,
                              16.0,
                              36.0,
                            ),
                            child: TextFormField(
                              controller: _bioController,
                              maxLines: null,
                              maxLength: 500,
                              buildCounter:
                                  (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) => null,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Color(0xFF3C1321),
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Share a little about your lifestyle, career, values, and what you seek in a future partner...',
                                hintStyle: TextStyle(color: Color(0xFFBCAAA4)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12.0,
                            right: 16.0,
                            child: Text(
                              '$bioLength/500',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: const Color(0xFF3C1321).withOpacity(0.6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 38.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Share your location',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C1321),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Loverage requires location access to find\ncompatible partners within your approximate area.\nWe will never share your exact address publicly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Color(0xFF9E9E9E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32.0),

          CustomPaint(
            foregroundPainter: LocationCrestPainter(),
            child: Container(
              width: double.infinity,
              height: 340.0,
              decoration: const BoxDecoration(),
              child: CustomPaint(
                painter: BaroqueFramePainter(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'YOUR LOCATION',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C1321),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.star_border_rounded,
                          color: Color(0xFFD4AF37),
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 0.8,
                          color: const Color(0xFFD4AF37).withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    const Text(
                      'We use your approximate location\nto find the best matches near you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Color(0xFF9E9E9E),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5E0B24), Color(0xFF3C1321)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25.0),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3C1321).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _detectingLocation
                                ? null
                                : _detectLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                            ),
                            icon: _detectingLocation
                                ? const SizedBox(
                                    height: 18.0,
                                    width: 18.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.location_on,
                                    color: Color(0xFFD4AF37),
                                    size: 20.0,
                                  ),
                            label: Text(
                              _detectingLocation
                                  ? 'Detecting...'
                                  : (_city == null
                                        ? 'Detect Current Location'
                                        : 'Update Location'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_city != null && !_detectingLocation) ...[
                      const SizedBox(height: 16.0),
                      Text(
                        'Detected: $_city, $_countryCode',
                        style: const TextStyle(
                          color: Color(0xFF5E0B24),
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 48.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CrownPainter extends CustomPainter {
  final Color color;
  CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Draw the crown shape
    path.moveTo(size.width * 0.15, size.height * 0.75);
    path.lineTo(size.width * 0.85, size.height * 0.75);
    path.lineTo(size.width * 0.9, size.height * 0.45);
    path.lineTo(size.width * 0.7, size.height * 0.55);
    path.lineTo(size.width * 0.5, size.height * 0.3);
    path.lineTo(size.width * 0.3, size.height * 0.55);
    path.lineTo(size.width * 0.1, size.height * 0.45);
    path.close();

    canvas.drawPath(path, paint);

    // Draw a small line just below the base for elegance
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.83),
      Offset(size.width * 0.75, size.height * 0.83),
      paint,
    );

    // Draw little circles at the three main tips
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.45),
      2.0,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      2.0,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.45),
      2.0,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BaroqueFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFFFF7F2) // very light cream fill
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
          .withOpacity(0.5) // gold outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final w = size.width;
    final h = size.height;
    const r = 24.0; // corner radius/notch size
    const offset = 12.0; // corner inset offset

    // Start from top-left, drawing clockwise
    path.moveTo(offset + r, offset);

    // Top line
    path.lineTo(w - offset - r, offset);

    // Top-right notched corner
    path.arcToPoint(
      Offset(w - offset, offset + r),
      radius: const Radius.circular(r),
      clockwise: false,
    );

    // Right line
    path.lineTo(w - offset, h - offset - r);

    // Bottom-right notched corner
    path.arcToPoint(
      Offset(w - offset - r, h - offset),
      radius: const Radius.circular(r),
      clockwise: false,
    );

    // Bottom line
    path.lineTo(offset + r, h - offset);

    // Bottom-left notched corner
    path.arcToPoint(
      Offset(offset, h - offset - r),
      radius: const Radius.circular(r),
      clockwise: false,
    );

    // Left line
    path.lineTo(offset, offset + r);

    // Top-left notched corner
    path.arcToPoint(
      Offset(offset + r, offset),
      radius: const Radius.circular(r),
      clockwise: false,
    );

    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.15), 10, true);

    // Draw fill
    canvas.drawPath(path, paint);

    // Draw gold border
    canvas.drawPath(path, borderPaint);

    // Draw an inner border with a small offset for elegance
    final innerPath = Path();
    const inset = 4.0;
    innerPath.moveTo(offset + r + inset, offset + inset);
    innerPath.lineTo(w - offset - r - inset, offset + inset);
    innerPath.arcToPoint(
      Offset(w - offset - inset, offset + r + inset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    innerPath.lineTo(w - offset - inset, h - offset - r - inset);
    innerPath.arcToPoint(
      Offset(w - offset - r - inset, h - offset - inset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    innerPath.lineTo(offset + r + inset, h - offset - inset);
    innerPath.arcToPoint(
      Offset(offset + inset, h - offset - r - inset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    innerPath.lineTo(offset + inset, offset + r + inset);
    innerPath.arcToPoint(
      Offset(offset + r + inset, offset + inset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    innerPath.close();

    canvas.drawPath(innerPath, borderPaint..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BaroqueDecorationsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // 1. Top Crown (centered at w/2)
    final cx = w / 2;
    const cy = 40.0;
    const cw = 30.0;
    const ch = 20.0;

    final crownPath = Path()
      ..moveTo(cx - cw / 2, cy + ch / 2)
      ..lineTo(cx + cw / 2, cy + ch / 2)
      ..lineTo(cx + cw / 2 + 2, cy - ch / 2 + 4)
      ..lineTo(cx + cw / 4, cy - ch / 4)
      ..lineTo(cx, cy - ch / 2)
      ..lineTo(cx - cw / 4, cy - ch / 4)
      ..lineTo(cx - cw / 2 - 2, cy - ch / 2 + 4)
      ..close();
    canvas.drawPath(crownPath, paint);

    // Crown base line
    canvas.drawLine(
      Offset(cx - cw / 3, cy + ch / 2 + 3),
      Offset(cx + cw / 3, cy + ch / 2 + 3),
      paint,
    );

    // Crown tips dots
    canvas.drawCircle(Offset(cx - cw / 2 - 2, cy - ch / 2 + 4), 1.5, fillPaint);
    canvas.drawCircle(Offset(cx, cy - ch / 2), 1.5, fillPaint);
    canvas.drawCircle(Offset(cx + cw / 2 + 2, cy - ch / 2 + 4), 1.5, fillPaint);

    // Small diamond star under crown
    final starPath = Path()
      ..moveTo(cx, cy + ch / 2 + 10)
      ..lineTo(cx + 3, cy + ch / 2 + 14)
      ..lineTo(cx, cy + ch / 2 + 18)
      ..lineTo(cx - 3, cy + ch / 2 + 14)
      ..close();
    canvas.drawPath(starPath, fillPaint);

    // 2. Laurel Branches (Top leaves flanking the crown)
    // Left Branch
    final leftLaurel = Path()
      ..moveTo(cx - cw / 2 - 10, cy + 2)
      ..quadraticBezierTo(cx - cw / 2 - 25, cy + 5, cx - cw / 2 - 45, cy + 10);
    canvas.drawPath(leftLaurel, paint);
    // Draw left leaves
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - cw / 2 - 20, cy + 1),
        width: 6,
        height: 3,
      ),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - cw / 2 - 32, cy + 4),
        width: 6,
        height: 3,
      ),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - cw / 2 - 42, cy + 8),
        width: 5,
        height: 3,
      ),
      fillPaint,
    );

    // Right Branch
    final rightLaurel = Path()
      ..moveTo(cx + cw / 2 + 10, cy + 2)
      ..quadraticBezierTo(cx + cw / 2 + 25, cy + 5, cx + cw / 2 + 45, cy + 10);
    canvas.drawPath(rightLaurel, paint);
    // Draw right leaves
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + cw / 2 + 20, cy + 1),
        width: 6,
        height: 3,
      ),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + cw / 2 + 32, cy + 4),
        width: 6,
        height: 3,
      ),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + cw / 2 + 42, cy + 8),
        width: 5,
        height: 3,
      ),
      fillPaint,
    );

    // 3. Bottom Rose Scroll (Centered at w/2, h - 30)
    final rx = w / 2;
    final ry = h - 30.0;

    // Draw rose center
    canvas.drawCircle(Offset(rx, ry), 4.0, paint);
    canvas.drawCircle(Offset(rx, ry), 2.0, fillPaint);

    // Draw rose petals
    final petal1 = Path()
      ..addArc(Rect.fromCircle(center: Offset(rx, ry), radius: 6.0), 0.0, 3.14);
    canvas.drawPath(petal1, paint);
    final petal2 = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(rx, ry), radius: 8.0),
        3.14,
        3.14,
      );
    canvas.drawPath(petal2, paint);

    // Left scroll swirl
    final leftScroll = Path()
      ..moveTo(rx - 8, ry)
      ..quadraticBezierTo(rx - 30, ry - 10, rx - 55, ry)
      ..quadraticBezierTo(rx - 70, ry + 10, rx - 80, ry);
    canvas.drawPath(leftScroll, paint);
    // Leaves on left scroll
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx - 30, ry - 6), width: 6, height: 3),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx - 55, ry + 2), width: 5, height: 3),
      fillPaint,
    );

    // Right scroll swirl
    final rightScroll = Path()
      ..moveTo(rx + 8, ry)
      ..quadraticBezierTo(rx + 30, ry - 10, rx + 55, ry)
      ..quadraticBezierTo(rx + 70, ry + 10, rx + 80, ry);
    canvas.drawPath(rightScroll, paint);
    // Leaves on right scroll
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx + 30, ry - 6), width: 6, height: 3),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx + 55, ry + 2), width: 5, height: 3),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LocationCrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const cy = 40.0;
    const r = 26.0;

    // 1. Draw concentric gold circle shield
    canvas.drawCircle(Offset(cx, cy), r, paint..strokeWidth = 1.5);
    canvas.drawCircle(Offset(cx, cy), r - 4, paint..strokeWidth = 0.8);

    // 2. Draw map pin inside shield
    final pinPath = Path()
      ..moveTo(cx, cy + 10)
      ..cubicTo(cx - 8, cy - 2, cx - 8, cy - 10, cx, cy - 10)
      ..cubicTo(cx + 8, cy - 10, cx + 8, cy - 2, cx, cy + 10)
      ..close();
    canvas.drawPath(pinPath, fillPaint);

    // Inner dot of pin
    canvas.drawCircle(
      Offset(cx, cy - 3),
      2.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // 3. Leaf branches flanking the shield
    final leftBranch = Path()
      ..moveTo(cx - r - 4, cy + 10)
      ..quadraticBezierTo(cx - r - 15, cy + 5, cx - r - 25, cy - 10);
    canvas.drawPath(leftBranch, paint..strokeWidth = 1.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r - 10, cy + 8), width: 5, height: 3),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r - 18, cy + 3), width: 5, height: 3),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r - 23, cy - 4), width: 4, height: 3),
      fillPaint,
    );

    final rightBranch = Path()
      ..moveTo(cx + r + 4, cy + 10)
      ..quadraticBezierTo(cx + r + 15, cy + 5, cx + r + 25, cy - 10);
    canvas.drawPath(rightBranch, paint..strokeWidth = 1.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r + 10, cy + 8), width: 5, height: 3),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r + 18, cy + 3), width: 5, height: 3),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + r + 23, cy - 4), width: 4, height: 3),
      fillPaint,
    );

    // Diamond star at bottom
    final starPath = Path()
      ..moveTo(cx, cy + r + 6)
      ..lineTo(cx + 3, cy + r + 10)
      ..lineTo(cx, cy + r + 14)
      ..lineTo(cx - 3, cy + r + 10)
      ..close();
    canvas.drawPath(starPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
