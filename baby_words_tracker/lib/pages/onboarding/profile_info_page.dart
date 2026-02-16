import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Collects basic profile information required for all users.
class ProfileInfoPage extends StatefulWidget {
  static const routeName = '/onboarding/profile-info';

  const ProfileInfoPage({super.key});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<UserProfileModelService>(context, listen: false)
        .userProfile;
    _firstNameController =
        TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();

    try {
      final userProfileService =
          Provider.of<UserProfileService>(context, listen: false);
      final userProfileModelService =
          Provider.of<UserProfileModelService>(context, listen: false);
      final profile = userProfileModelService.userProfile;

      if (profile == null) {
        throw Exception('No profile available to update');
      }

      await userProfileService.updateUserProfile(
          profile.id,
          {
            'firstName': firstName,
            'lastName': lastName,
            'name': fullName,
          },
          isDemo: userProfileModelService.isDemoUser);

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(fullName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('ProfileInfoPage: Error saving profile $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return to Sign In'),
        content: const Text(
          'Signing out will take you back to the sign-in screen so you can start over.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthenticationService>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Up Your Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Sign In',
          onPressed: _confirmSignOut,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthenticationService>().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Tell us who you are',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We use your name for communication and research records.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label:
                            Text(_isSaving ? 'Saving...' : 'Save and Continue'),
                      ),
                    ],
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
