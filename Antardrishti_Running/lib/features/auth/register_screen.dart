import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/services/image_storage_service.dart';
import '../../main.dart';
import '../../ui/widgets/app_scaffold.dart';
import '../../ui/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  final ImageStorageService _imageStorage = ImageStorageService();
  
  File? _selectedImage;
  String? _localImagePath;
  bool _loading = false;
  String? _error;
  String? _aadhaarNumber;
  String? _requestId;
  
  // Dropdown values
  String _selectedGender = 'Male';
  String _selectedDisability = 'None';
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _disabilityOptions = [
    'None', 
    'Visual', 
    'Hearing', 
    'Locomotor', 
    'Intellectual', 
    'Multiple'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments passed from OTP verification screen
    if (_aadhaarNumber == null && _requestId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _aadhaarNumber = args['aadhaarNumber'] as String?;
          _requestId = args['requestId'] as String?;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _formatAadhaar(String aadhaar) {
    if (aadhaar.length == 12) {
      return '${aadhaar.substring(0, 4)} XXXX ${aadhaar.substring(8)}';
    }
    return aadhaar;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        
        // Save to local storage
        if (_aadhaarNumber != null) {
          final fileName = _imageStorage.generateFileName(_aadhaarNumber!);
          final savedPath = await _imageStorage.saveImage(file, fileName);
          
          setState(() {
            _selectedImage = file;
            _localImagePath = savedPath;
          });
        } else {
          setState(() {
            _selectedImage = file;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate profile image is selected
    if (_selectedImage == null) {
      setState(() => _error = 'Please select a profile image');
      return;
    }

    if (_aadhaarNumber == null || _requestId == null) {
      setState(() => _error = 'Missing Aadhaar number or OTP verification. Please start over.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AppState>().completeRegistration(
            name: _nameController.text.trim(),
            aadhaarNumber: _aadhaarNumber!,
            requestId: _requestId!,
            age: int.parse(_ageController.text.trim()),
            height: double.parse(_heightController.text.trim()),
            weight: double.parse(_weightController.text.trim()),
            gender: _selectedGender,
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
            disability: _selectedDisability,
            phoneNumber: _phoneController.text.trim(),
            email: _emailController.text.trim().isNotEmpty 
                ? _emailController.text.trim() 
                : null,
            profileImage: _selectedImage,
          );
      
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      appBar: AppBar(title: const Text('Complete Registration')),
      gradient: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              if (_aadhaarNumber != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user, 
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aadhaar: ${_formatAadhaar(_aadhaarNumber!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Profile Image Picker (Mandatory)
              Column(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedImage == null 
                                ? theme.colorScheme.error 
                                : theme.colorScheme.primary,
                            width: _selectedImage == null ? 3 : 2,
                          ),
                          color: theme.colorScheme.surface,
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Photo *',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedImage == null)
                    Text(
                      'Profile image is required for face verification',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Name
              AppTextField(
                controller: _nameController,
                label: 'Full Name *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              
              // Phone Number (Mandatory)
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number *',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length != 10) {
                    return 'Phone number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              
              // Email (Optional)
              AppTextField(
                controller: _emailController,
                label: 'Email (Optional)',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              
              // Age
              AppTextField(
                controller: _ageController,
                label: 'Age *',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return 'Please enter a valid age (1-120)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              
              // Height and Weight in a Row
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _heightController,
                      label: 'Height (cm) *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height < 50 || height > 300) {
                          return '50-300 cm';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _weightController,
                      label: 'Weight (kg) *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 10 || weight > 500) {
                          return '10-500 kg';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              
              // Address
              AppTextField(
                controller: _addressController,
                label: 'Full Address *',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              
              // City
              AppTextField(
                controller: _cityController,
                label: 'City *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              
              // State
              AppTextField(
                controller: _stateController,
                label: 'State *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your state';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              
              // Pincode
              AppTextField(
                controller: _pincodeController,
                label: 'Pincode *',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your pincode';
                  }
                  if (value.length != 6) {
                    return 'Pincode must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              
              // Disability Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDisability,
                decoration: InputDecoration(
                  labelText: 'Disability (if any)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _disabilityOptions.map((disability) {
                  return DropdownMenuItem(
                    value: disability,
                    child: Text(disability),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDisability = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              PrimaryButton(
                label: 'Complete Registration',
                loading: _loading,
                icon: Icons.person_add,
                onPressed: _loading ? null : _handleRegistration,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
