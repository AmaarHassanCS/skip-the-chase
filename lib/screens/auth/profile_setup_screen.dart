import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Male';
  final List<String> _interests = [];

  final List<String> _availableInterests = [
    'Music', 'Movies', 'Sports', 'Travel', 'Food', 'Art', 'Books', 'Gaming',
    'Fitness', 'Photography', 'Dancing', 'Cooking', 'Nature', 'Technology'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'First name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Last name is required' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Birth Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _birthDate != null
                      ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                      : 'Select birth date',
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: ['Male', 'Female', 'Other'].map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (value) => setState(() => _gender = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                hintText: 'Tell others about yourself...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Interests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableInterests.map((interest) {
                final isSelected = _interests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _interests.add(interest);
                      } else {
                        _interests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _createProfile,
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Profile'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (date != null) {
      setState(() => _birthDate = date);
    }
  }

  Future<void> _createProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your birth date')),
        );
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final profile = UserProfile(
        id: '',
        userId: authProvider.user!.id,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        birthDate: _birthDate!,
        gender: _gender,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        interests: _interests,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await authProvider.createProfile(profile);
      if (success && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create profile')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}