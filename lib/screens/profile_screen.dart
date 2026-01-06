import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _ageController = TextEditingController();
  final _heightController = TextEditingController(); 
  final _weightController = TextEditingController();
  final _addressController = TextEditingController();
  final _regionController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String? _selectedGender;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false; // Toggle for Read/Edit mode
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final result = await ApiService.getProfile();
    
    if (!mounted) return;
    
    if (result['success']) {
      final profile = result['profile'];
      setState(() {
        _username = profile['username'];
        if (profile['profile'] != null) {
          final p = profile['profile'];
          _ageController.text = p['age']?.toString() ?? '';
          _heightController.text = p['height_cm']?.toString() ?? '';
          _weightController.text = p['weight_kg']?.toString() ?? '';
          _selectedGender = p['gender'];
          _addressController.text = p['address'] ?? '';
          _regionController.text = p['region'] ?? '';
          _pincodeController.text = p['pincode'] ?? '';
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to load profile')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await ApiService.updateProfile(
      age: int.tryParse(_ageController.text),
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      gender: _selectedGender,
      address: _addressController.text,
      region: _regionController.text,
      pincode: _pincodeController.text,
    );

    if (!mounted) return;
    
    setState(() {
      _isSaving = false;
    });

    if (result['success']) {
      setState(() => _isEditing = false); // Exit edit mode on success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Update failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF0F2F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   // 1. Header Section
                   _buildHeader(),
                   const SizedBox(height: 24),
                   
                   // 2. Physical Metrics
                   _buildSectionTitle("Physical Metrics"),
                   _buildPhysicalMetricsCard(),
                   const SizedBox(height: 24),

                   // 3. Personal Info
                   _buildSectionTitle("Personal Details"),
                   _buildPersonalInfoCard(),
                   const SizedBox(height: 24),

                   // 4. Contact Info
                   _buildSectionTitle("Contact Info"),
                   _buildContactCard(),
                   const SizedBox(height: 32),
                   
                   // Save Button
                   if (_isEditing)
                     SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, // Premium Black
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                     ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    
                   if (_isEditing)
                     Padding(
                       padding: const EdgeInsets.only(top: 16),
                       child: TextButton(
                         onPressed: () => setState(() {
                            _isEditing = false;
                            _loadProfile(); // Reset changes
                         }),
                         child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                       ),
                     ),

                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
         const SizedBox(height: 10),
         Container(
           padding: const EdgeInsets.all(4),
           decoration: const BoxDecoration(
             shape: BoxShape.circle,
             gradient: LinearGradient(colors: [Color(0xFF2962FF), Color(0xFF00BFA5)]),
           ),
           child: CircleAvatar(
             radius: 50,
             backgroundColor: Colors.white,
             child: CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFFF5F7FA),
                child: Text(
                  (_username ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
             ),
           ),
         ),
         const SizedBox(height: 16),
         Text(
            '@$_username',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
         ),
         const SizedBox(height: 4),
         Text(
           'Athlete Profile',
           style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
         ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          title, 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildPhysicalMetricsCard() {
    if (_isEditing) {
      return _buildCard(children: [
         Row(
           children: [
             Expanded(
               child: _buildTextField(_heightController, 'Height', suffix: 'cm', icon: Icons.height, isNumeric: true),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: _buildTextField(_weightController, 'Weight', suffix: 'kg', icon: Icons.monitor_weight_outlined, isNumeric: true),
             ),
           ],
         ),
      ]);
    }

    return _buildCard(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricDisplay('Height', _heightController.text.isEmpty ? '-' : _heightController.text, 'cm'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildMetricDisplay('Weight', _weightController.text.isEmpty ? '-' : _weightController.text, 'kg'),
        ],
      ),
    ]);
  }

  Widget _buildMetricDisplay(String label, String value, String unit) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.0)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600])),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    if (_isEditing) {
       return _buildCard(children: [
          Row(
            children: [
              Expanded(child: _buildTextField(_ageController, 'Age', isNumeric: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildGenderDropdown()),
            ],
          ),
       ]);
    }
    
    return _buildCard(children: [
      _buildInfoRow('Age', _ageController.text.isEmpty ? '-' : '${_ageController.text} years'),
      const Divider(height: 24),
      _buildInfoRow('Gender', _selectedGender != null ? _selectedGender![0].toUpperCase() + _selectedGender!.substring(1) : '-'),
    ]);
  }

  Widget _buildContactCard() {
    if (_isEditing) {
      return _buildCard(children: [
         _buildTextField(_addressController, 'Address', maxLines: 2),
         const SizedBox(height: 16),
         _buildTextField(_regionController, 'Region / State'),
         const SizedBox(height: 16),
         _buildTextField(_pincodeController, 'Pincode', isNumeric: true),
      ]);
    }

    return _buildCard(children: [
      _buildInfoRow('Address', _addressController.text.isEmpty ? '-' : _addressController.text),
      const Divider(height: 24),
      _buildInfoRow('Region', _regionController.text.isEmpty ? '-' : _regionController.text),
      const Divider(height: 24),
      _buildInfoRow('Pincode', _pincodeController.text.isEmpty ? '-' : _pincodeController.text),
    ]);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? suffix, IconData? icon, bool isNumeric = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
         if (isNumeric && value != null && value.isNotEmpty) {
            // Simple check for now
            if (double.tryParse(value) == null) return "Invalid";
         }
         return null;
      },
    );
  }
  
  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: (value) => setState(() => _selectedGender = value),
    );
  }
}
