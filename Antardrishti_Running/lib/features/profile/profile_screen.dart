import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/image_storage_service.dart';
import '../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImageStorageService _imageStorageService = ImageStorageService();
  String? _localProfileImagePath;
  bool _isLoadingImage = true;

  // Project colors
  static const Color _primaryOrange = Color(0xFFf28d25);
  static const Color _secondaryPurple = Color(0xFF322259);

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final state = context.read<AppState>();
    final user = state.user;
    
    if (user != null) {
      final path = await _imageStorageService.getProfileImagePath(user.aadhaarNumber);
      if (mounted) {
        setState(() {
          _localProfileImagePath = path;
          _isLoadingImage = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
      }
    }
  }

  String _formatAadhaar(String aadhaar) {
    if (aadhaar.length == 12) {
      return '${aadhaar.substring(0, 4)} XXXX ${aadhaar.substring(8)}';
    }
    return aadhaar;
  }

  Widget _buildProfileImage() {
    if (_isLoadingImage) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _primaryOrange,
          ),
        ),
      );
    }

    if (_localProfileImagePath != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _primaryOrange, width: 3),
          boxShadow: [
            BoxShadow(
              color: _primaryOrange.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            File(_localProfileImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderAvatar();
            },
          ),
        ),
      );
    }

    return _buildPlaceholderAvatar();
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _secondaryPurple.withOpacity(0.1),
        border: Border.all(color: _secondaryPurple, width: 2),
      ),
      child: const Icon(
        Icons.person,
        size: 60,
        color: _secondaryPurple,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? _primaryOrange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? _primaryOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _secondaryPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: _secondaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'No user data',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header section with gradient
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: _secondaryPurple,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Profile image
                        _buildProfileImage(),
                        const SizedBox(height: 16),
                        // User name
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Phone number
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+91 ${user.phoneNumber}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Aadhaar number (masked)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_user,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Aadhaar: ${_formatAadhaar(user.aadhaarNumber)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  // Details section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email (if present)
                        if (user.email != null && user.email!.isNotEmpty) ...[
                          _buildInfoCard(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email!,
                            iconColor: Colors.red,
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        const Text(
                          'Physical Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _secondaryPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Age, Height, Weight in a row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.cake_outlined,
                                label: 'Age',
                                value: '${user.age} yrs',
                                iconColor: Colors.pink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.height,
                                label: 'Height',
                                value: '${user.height.toStringAsFixed(1)} cm',
                                iconColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.fitness_center,
                                label: 'Weight',
                                value: '${user.weight.toStringAsFixed(1)} kg',
                                iconColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.person_outline,
                                label: 'Gender',
                                value: user.gender,
                                iconColor: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Disability
                        _buildInfoCard(
                          icon: Icons.accessibility_new,
                          label: 'Disability',
                          value: user.disability,
                          iconColor: Colors.teal,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Location Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _secondaryPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Address
                        _buildInfoCard(
                          icon: Icons.home_outlined,
                          label: 'Address',
                          value: user.address,
                          iconColor: _primaryOrange,
                        ),
                        const SizedBox(height: 12),
                        
                        // City
                        _buildInfoCard(
                          icon: Icons.location_city_outlined,
                          label: 'City',
                          value: user.city,
                          iconColor: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        
                        // State
                        _buildInfoCard(
                          icon: Icons.map_outlined,
                          label: 'State',
                          value: user.state,
                          iconColor: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        
                        // Pincode
                        _buildInfoCard(
                          icon: Icons.pin_drop_outlined,
                          label: 'Pincode',
                          value: user.pincode,
                          iconColor: Colors.purple,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await context.read<AppState>().refreshProfile();
                                    await _loadProfileImage(); // Reload profile image
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Profile refreshed'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primaryOrange,
                                  side: const BorderSide(color: _primaryOrange),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await context.read<AppState>().logout();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/welcome',
                                      (_) => false,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
