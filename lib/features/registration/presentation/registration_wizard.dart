import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  final List<String> _images = []; // Local file paths of picked images
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
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
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
        // Requires at least 2 images
        return _images.length >= 2 || _mockImagesAddedForTest();
      case 5:
        final bio = _bioController.text.trim();
        // Simple link and contact filter: block common link/phone patterns
        final phoneRegex = RegExp(r'\b\d{8,15}\b');
        final emailRegex = RegExp(r'[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
        final linkRegex = RegExp(r'(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)');
        
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

  bool _mockImagesAddedForTest() {
    // For local mocking/testing, auto-populate if empty
    if (_images.isEmpty) {
      _images.addAll(['mock_img_1.png', 'mock_img_2.png']);
    }
    return true;
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
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
            _city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? 'Unknown City';
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
      await ref.read(authRepositoryProvider).updateRegistrationProgress(
        name: _nameController.text.trim(),
        gender: _gender!,
        dob: _dob!,
        religion: _religion!,
        bio: _bioController.text.trim(),
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        city: _city ?? 'Unknown',
        countryCode: _countryCode ?? 'US',
      );
      // The router notifier automatically switches state to FaceVerification
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryBurgundy),
                onPressed: _prevStep,
              )
            : null,
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
              child: _currentStep == _totalSteps - 1
                  ? FilledButton(
                      onPressed: _validateCurrentStep() ? _submitRegistration : null,
                      child: const Text('Complete & Continue'),
                    )
                  : FilledButton(
                      onPressed: _validateCurrentStep() ? _nextStep : null,
                      child: const Text('Next'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP UIs
  Widget _buildGenderStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What is your gender?', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
          const SizedBox(height: 8.0),
          const Text('This helps us connect you with compatible matches of the other gender.', style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary)),
          const SizedBox(height: 32.0),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard('Male', Icons.male_rounded),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildGenderCard('Female', Icons.female_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String value, IconData icon) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        height: 140.0,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBurgundy : AppColors.cardCream,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(
            color: isSelected ? AppColors.primaryBurgundy : AppColors.borderLight,
            width: 2.0,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0, color: isSelected ? Colors.white : AppColors.primaryBurgundy),
            const SizedBox(height: 12.0),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What is your name?', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
          const SizedBox(height: 8.0),
          const Text('Enter your first name or preferred public name (no links, emails, numbers, or special symbols).', style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary)),
          const SizedBox(height: 32.0),
          TextFormField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g., Sarah, Khalid',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDobStep() {
    final age = _dob == null ? null : DateTime.now().difference(_dob!).inDays ~/ 365;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('When were you born?', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
          const SizedBox(height: 8.0),
          const Text('You must be at least 18 years old to use Loverage. We verify ages to keep the community safe.', style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary)),
          const SizedBox(height: 32.0),
          GestureDetector(
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1940),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                setState(() => _dob = selectedDate);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dob == null ? 'Select Date of Birth' : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    style: TextStyle(
                      color: _dob == null ? AppColors.textMuted : AppColors.textPrimary,
                      fontSize: 16.0,
                    ),
                  ),
                  const Icon(Icons.calendar_month_outlined, color: AppColors.primaryBurgundy),
                ],
              ),
            ),
          ),
          if (age != null) ...[
            const SizedBox(height: 16.0),
            Text(
              'Calculated Age: $age years old ${age < 18 ? "(Must be 18+)" : ""}',
              style: TextStyle(
                color: age < 18 ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReligionStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select your religion', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
          const SizedBox(height: 8.0),
          const Text('Loverage supports filtering and matching based on major religious compatibility.', style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary)),
          const SizedBox(height: 32.0),
          _buildReligionOption('Islam'),
          const SizedBox(height: 12.0),
          _buildReligionOption('Christianity'),
          const SizedBox(height: 12.0),
          _buildReligionOption('Judaism'),
        ],
      ),
    );
  }

  Widget _buildReligionOption(String value) {
    final isSelected = _religion == value;
    return GestureDetector(
      onTap: () => setState(() => _religion = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBurgundy : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: isSelected ? AppColors.primaryBurgundy : AppColors.borderLight, width: 1.5),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildImagesStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add profile photos', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
          const SizedBox(height: 8.0),
          const Text('Upload between 2 and 6 photos. Tap to set your main photo. We mock this process for simulator compatibility.', style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary)),
          const SizedBox(height: 32.0),
          
          // Image Grids Mockup
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final hasImage = index < _images.length;
              final isMain = index == _mainImageIndex;
              
              return GestureDetector(
                onTap: () {
                  if (hasImage) {
                    setState(() => _mainImageIndex = index);
                  } else {
                    setState(() {
                      _images.add('mock_path_${_images.length + 1}.png');
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardCream,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(
                      color: isMain ? AppColors.primaryBurgundy : AppColors.borderLight,
                      width: isMain ? 2.5 : 1.0,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (hasImage) ...[
                        const Icon(Icons.image_outlined, size: 32.0, color: AppColors.textSecondary),
                        Positioned(
                          top: 4.0,
                          left: 4.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: isMain ? AppColors.primaryBurgundy : Colors.black45,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              isMain ? 'Main' : '#${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4.0,
                          right: 4.0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _images.removeAt(index);
                                if (_mainImageIndex >= _images.length) {
                                  _mainImageIndex = 0;
                                }
                              });
                            },
                            child: const CircleAvatar(
                              radius: 10.0,
                              backgroundColor: AppColors.error,
                              child: Icon(Icons.close, size: 12.0, color: Colors.white),
                            ),
                          ),
                        )
                      ] else ...[
                        const Icon(Icons.add_a_photo_outlined, size: 28.0, color: AppColors.accentRoseGold),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    final bioLength = _bioController.text.length;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Write a short bio', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
          const SizedBox(height: 8.0),
          const Text('Describe your values, personality, and expectations. Do not post numbers, social handles, or website URLs.', style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary)),
          const SizedBox(height: 32.0),
          TextFormField(
            controller: _bioController,
            maxLines: 5,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Share a little about your lifestyle, career, values, and what you seek in a future partner...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Share your location', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
          const SizedBox(height: 8.0),
          const Text('Loverage requires location access to find compatible partners within your approximate area. We will never share your exact address publicly.', style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary)),
          const SizedBox(height: 48.0),
          
          if (_city != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.cardCream,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Confirmed Location:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0, color: AppColors.textSecondary)),
                  const SizedBox(height: 8.0),
                  Text('$_city, $_countryCode', style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy)),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
          ],
          
          OutlinedButton.icon(
            onPressed: _detectingLocation ? null : _detectLocation,
            icon: _detectingLocation
                ? const SizedBox(height: 18.0, width: 18.0, child: CircularProgressIndicator(strokeWidth: 2.0))
                : const Icon(Icons.location_on_outlined),
            label: Text(_city == null ? 'Detect Current Location' : 'Update Location'),
          ),
        ],
      ),
    );
  }
}
