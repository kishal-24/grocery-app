import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/account_storage_service.dart';

class MyDetailsScreen extends StatefulWidget {
  const MyDetailsScreen({super.key});

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  String _selectedGender = 'Prefer not to say';
  int _selectedAvatarIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Color> _avatarColors = [
    AppColors.primaryGreen,
    const Color(0xFF53B175),
    const Color(0xFFF3603F),
    const Color(0xFF5383EC),
    const Color(0xFFD470FF),
    const Color(0xFFF8A44C),
  ];

  final List<IconData> _avatarIcons = [
    Icons.person,
    Icons.face,
    Icons.sentiment_very_satisfied,
    Icons.emoji_emotions,
    Icons.nature_people,
    Icons.account_circle,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final savedData = await AccountStorageService().getUserProfile();

    String name = savedData['name'] ?? '';
    if (name.isEmpty && user?.displayName != null && user!.displayName!.isNotEmpty) {
      name = user.displayName!;
    }
    if (name.isEmpty && user?.email != null) {
      name = user!.email!.split('@').first;
    }

    _nameController.text = name;
    _emailController.text = user?.email ?? 'user@freshbasket.com';
    _phoneController.text = savedData['phone'] ?? '+1 555 123 4567';
    _dobController.text = savedData['dob'] ?? '15 May 1995';
    _selectedGender = savedData['gender'] ?? 'Prefer not to say';
    _selectedAvatarIndex = int.tryParse(savedData['avatar'] ?? '0') ?? 0;
    if (_selectedAvatarIndex >= _avatarColors.length) _selectedAvatarIndex = 0;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();
      final newDob = _dobController.text.trim();

      // Update Firebase user displayName
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && newName.isNotEmpty) {
        try {
          await user.updateDisplayName(newName);
        } catch (_) {}
      }

      // Save to AccountStorageService
      await AccountStorageService().saveUserProfile(
        name: newName,
        phone: newPhone,
        dob: newDob,
        gender: _selectedGender,
        avatar: _selectedAvatarIndex.toString(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile details updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 5, 15),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final formatted = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar selection
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: _avatarColors[_selectedAvatarIndex].withValues(alpha: 0.15),
                            child: Icon(
                              _avatarIcons[_selectedAvatarIndex],
                              size: 54,
                              color: _avatarColors[_selectedAvatarIndex],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose Avatar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: List.generate(_avatarColors.length, (index) {
                              final isSelected = index == _selectedAvatarIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAvatarIndex = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: _avatarColors[index].withValues(alpha: 0.2),
                                    child: Icon(
                                      _avatarIcons[index],
                                      size: 20,
                                      color: _avatarColors[index],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Full Name
                    _buildFieldLabel('Full Name'),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                      decoration: _inputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email Address (Read-only or connected to Firebase)
                    _buildFieldLabel('Email Address'),
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textGrey.withValues(alpha: 0.8)),
                      decoration: _inputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icons.email_outlined,
                        suffixWidget: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreenLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: AppColors.primaryGreen),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Phone Number
                    _buildFieldLabel('Phone Number'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                      decoration: _inputDecoration(
                        hintText: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Date of Birth
                    _buildFieldLabel('Date of Birth'),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(14),
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: _dobController,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                          decoration: _inputDecoration(
                            hintText: 'Select date of birth',
                            prefixIcon: Icons.calendar_today_outlined,
                            suffixWidget: const Icon(Icons.arrow_drop_down, color: AppColors.textGrey),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Gender
                    _buildFieldLabel('Gender'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
                          items: ['Male', 'Female', 'Non-binary', 'Prefer not to say']
                              .map((gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(
                                      gender,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedGender = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixWidget,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
      filled: true,
      fillColor: AppColors.cardBackground,
      prefixIcon: Icon(prefixIcon, color: AppColors.primaryGreen, size: 20),
      suffixIcon: suffixWidget,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    );
  }
}
