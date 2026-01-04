import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io' show File, Platform;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/photo_permission_helper.dart';
import 'models/user_model.dart';
import 'cubit/user_cubit.dart';
import 'cubit/user_states.dart';
import 'repository/user_repository.dart';
import 'services/image_upload_service.dart';
import 'utils/toast_util.dart';

class BiodataPage extends StatefulWidget {
  const BiodataPage({super.key});

  @override
  State<BiodataPage> createState() => _BiodataPageState();
}

class _BiodataPageState extends State<BiodataPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _streetController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _birthDateText;
  UserModel? _user;
  bool _isLoading = true;
  String _selectedCountryCode = '+60'; // Default to Malaysia
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImageFile;
  String? _uploadedImageUrl;
  bool _acceptedPolicy = false;
  bool _isUploadingImage = false;

  // Common country codes
  final List<Map<String, String>> _countryCodes = [
    {'code': '+60', 'name': 'Malaysia', 'flag': '🇲🇾'},
    {'code': '+65', 'name': 'Singapore', 'flag': '🇸🇬'},
    {'code': '+62', 'name': 'Indonesia', 'flag': '🇮🇩'},
    {'code': '+66', 'name': 'Thailand', 'flag': '🇹🇭'},
    {'code': '+84', 'name': 'Vietnam', 'flag': '🇻🇳'},
    {'code': '+1', 'name': 'USA/Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'UK', 'flag': '🇬🇧'},
    {'code': '+61', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': '+971', 'name': 'UAE', 'flag': '🇦🇪'},
    {'code': '+966', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userRepo = UserRepository();
      final user = await userRepo.getCurrentUser();
      if (user != null) {
        setState(() {
          _user = user;
          _isLoading = false;
          // Pre-fill with existing data if available
          _nameController.text = user.name;
          
          // Parse phone number to extract country code and number
          if (user.phone != 'N/A' && user.phone.isNotEmpty) {
            final phone = user.phone.trim();
            // Try to extract country code (starts with +)
            String? countryCode;
            String phoneNumber = phone;
            
            // Check if phone starts with a known country code
            for (var country in _countryCodes) {
              if (phone.startsWith(country['code']!)) {
                countryCode = country['code'];
                phoneNumber = phone.substring(country['code']!.length).trim();
                break;
              }
            }
            
            // If no country code found, check if it starts with +
            if (countryCode == null && phone.startsWith('+')) {
              // Try to extract the first 1-4 digits after +
              final match = RegExp(r'^\+(\d{1,4})').firstMatch(phone);
              if (match != null) {
                final potentialCode = '+${match.group(1)}';
                // Check if it matches any known code
                for (var country in _countryCodes) {
                  if (country['code'] == potentialCode) {
                    countryCode = potentialCode;
                    phoneNumber = phone.substring(potentialCode.length).trim();
                    break;
                  }
                }
              }
            }
            
            _selectedCountryCode = countryCode ?? '+60';
            _phoneController.text = phoneNumber;
          }
          
          // Parse address if it exists (Map format)
          if (user.address != null) {
            _addressLine1Controller.text = user.address!['line1'] ?? '';
            _streetController.text = user.address!['street'] ?? '';
            _postcodeController.text = user.address!['postcode'] ?? '';
            _cityController.text = user.address!['city'] ?? '';
            _stateController.text = user.address!['state'] ?? '';
            _countryController.text = user.address!['country'] ?? '';
          }
          
          // Set profile image URL if exists
          if (user.profileImage != null) {
            _uploadedImageUrl = user.profileImage;
          }
          _selectedBirthDate = user.birthDate;
          if (_selectedBirthDate != null) {
            _birthDateText = DateFormat('yyyy-MM-dd').format(_selectedBirthDate!);
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _streetController.dispose();
    _postcodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? now.subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateText = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama penuh diperlukan';
    }
    if (value.trim().length < 2) {
      return 'Nama mestilah sekurang-kurangnya 2 aksara';
    }
    if (value.trim().length > 50) {
      return 'Nama mestilah kurang daripada 50 aksara';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nombor telefon diperlukan';
    }
    // Remove spaces, dashes, and parentheses for validation
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 7) {
      return 'Nombor telefon terlalu pendek';
    }
    if (cleaned.length > 15) {
      return 'Nombor telefon terlalu panjang';
    }
    // Check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Nombor telefon hanya boleh mengandungi nombor';
    }
    return null;
  }

  String? _validateBirthDate() {
    if (_selectedBirthDate == null) {
      return 'Birth date is required';
    }
    final now = DateTime.now();
    final age = now.year - _selectedBirthDate!.year;
    if (age < 5 || age > 120) {
      return 'Please enter a valid birth date';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    return await PhotoPermissionHelper.checkAndRequestPhotoPermission(
      context,
      source: source,
    );
  }

  Future<void> _pickProfilePicture() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Sumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Check and request permission
      final hasPermission = await _checkAndRequestPermission(source);
      if (!hasPermission) return;

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _isUploadingImage = true;
      });

      // Upload to Firebase Storage
      final imageUrl = await _imageUploadService.uploadProfilePicture(_selectedImageFile!);

      // Delete old profile picture if exists
      if (_uploadedImageUrl != null && _uploadedImageUrl != _user?.profileImage) {
        try {
          await _imageUploadService.deleteProfilePicture(_uploadedImageUrl!);
        } catch (e) {
        }
      }

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      ToastUtil.showSuccess(context, 'Gambar profil berjaya dimuat naik');
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      ToastUtil.showError(context, 'Gagal memuat naik gambar: $e');
    }
  }

  String? _validatePostcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postcode is required';
    }
    // Basic postcode validation (5-10 alphanumeric characters)
    if (!RegExp(r'^[A-Za-z0-9\s-]{5,10}$').hasMatch(value.trim())) {
      return 'Please enter a valid postcode';
    }
    return null;
  }

  Future<void> _saveBiodata() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if policy is accepted
    if (!_acceptedPolicy) {
      ToastUtil.showError(context, 'Sila bersetuju dengan Dasar Privasi & Terma untuk meneruskan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_user == null) return;
      
      // Combine country code and phone number
      final countryCode = _selectedCountryCode.trim();
      final phoneNumber = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      final fullPhone = '$countryCode$phoneNumber';
      
      // Create address map
      final addressMap = {
        'line1': _addressLine1Controller.text.trim(),
        'street': _streetController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
      };
      
      // Upload profile picture if selected but not yet uploaded
      String? finalImageUrl = _uploadedImageUrl;
      if (_selectedImageFile != null && _uploadedImageUrl == null) {
        try {
          finalImageUrl = await _imageUploadService.uploadProfilePicture(_selectedImageFile!);
        } catch (e) {
          // Continue without profile picture if upload fails
        }
      }

      // Create updated user with completed biodata
      final updatedUser = _user!.copyWith(
        name: _nameController.text.trim(),
        phone: fullPhone,
        birthDate: _selectedBirthDate,
        address: addressMap,
        hasCompletedBiodata: true,
        profileImage: finalImageUrl, // Include profile image if uploaded
      );

      // Update user in Firestore
      await context.read<UserCubit>().updateUser(updatedUser);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biodata saved successfully!'),
            backgroundColor: Colors.green, // Success color - keep as is
          ),
        );

        // Navigate to card info page (optional card collection)
        Navigator.of(context).pushReplacementNamed('/card-info');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save biodata: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Failed to load user data. Please try again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Welcome to Daily Quran!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please complete your profile to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              // Profile Picture Upload (Optional)
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _uploadedImageUrl != null
                              ? NetworkImage(_uploadedImageUrl!)
                              : (_selectedImageFile != null
                                  ? FileImage(_selectedImageFile!)
                                  : null),
                          child: _uploadedImageUrl == null && _selectedImageFile == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isUploadingImage ? null : _pickProfilePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Upload Profile Picture (Optional)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: _validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              // Phone field with country code
              Row(
                children: [
                  // Country code dropdown
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCountryCode,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      items: _countryCodes.map((country) {
                        return DropdownMenuItem<String>(
                          value: country['code'],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(country['flag']!),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  country['code']!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCountryCode = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Phone number field
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: '123456789',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Birth Date field
              GestureDetector(
                onTap: _pickBirthDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Birth Date *',
                      hintText: 'Select your birth date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    controller: TextEditingController(text: _birthDateText ?? ''),
                    validator: (_) => _validateBirthDate(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Address fields
              Text(
                'Address *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // Line 1
              TextFormField(
                controller: _addressLine1Controller,
                decoration: const InputDecoration(
                  labelText: 'Line 1 *',
                  hintText: 'Enter address line 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) => _validateRequired(value, 'Line 1'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Street
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Street *',
                  hintText: 'Enter street name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.streetview),
                ),
                validator: (value) => _validateRequired(value, 'Street'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Postcode and City in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postcode *',
                        hintText: '12345',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.markunread_mailbox),
                      ),
                      validator: _validatePostcode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        hintText: 'Enter city',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) => _validateRequired(value, 'City'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // State and Country in a row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        hintText: 'Enter state',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map),
                      ),
                      validator: (value) => _validateRequired(value, 'State'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country *',
                        hintText: 'Enter country',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public),
                      ),
                      validator: (value) => _validateRequired(value, 'Country'),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Policy and Terms Checkbox
              CheckboxListTile(
                title: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/policy');
                  },
                  child: Text.rich(
                    TextSpan(
                      text: 'Saya bersetuju dengan ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Dasar Privasi & Terma',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            // decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                value: _acceptedPolicy,
                onChanged: (bool? newValue) {
                  setState(() {
                    _acceptedPolicy = newValue ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_acceptedPolicy) ? null : _saveBiodata,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
