import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/util/policies_and_consent/privacy_policy_information.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy policy acceptance step in onboarding
/// Displays privacy policy and requires acceptance before continuing
class PrivacyPolicyPage extends StatefulWidget {
  static const routeName = '/onboarding/privacy-policy';

  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _hasReadPolicy = false;
  bool _isAccepting = false;

  Future<void> _acceptPrivacyPolicy() async {
    if (!_hasReadPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you have read the privacy policy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    try {
      final userModelService = context.read<UserProfileModelService>();

      await userModelService.acceptPrivacyPolicy(
        policyVersion: PrivacyPolicyInformation.privacyPolicyVersion,
      );

      debugPrint('PrivacyPolicyPage: Privacy policy accepted');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy policy accepted'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // AuthGate will automatically navigate to next step
    } catch (e) {
      debugPrint('PrivacyPolicyPage: Error accepting policy: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting policy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  Future<void> _declinePrivacyPolicy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Privacy Policy'),
        content: const Text(
          'You must accept the privacy policy to use this app. '
          'If you decline, you will be signed out.',
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

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse(PrivacyPolicyInformation.privacyPolicyUrl);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open privacy policy link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('PrivacyPolicyPage: Error opening URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Sign In',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Return to Sign In'),
                content: const Text(
                  'Signing out will take you back to the sign-in screen so you can restart onboarding.',
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

            if (confirmed == true && context.mounted) {
              await context.read<AuthenticationService>().signOut();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthenticationService>().signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  Icons.policy_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Please review and accept our privacy policy to continue',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Privacy policy content card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy Summary',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          PrivacyPolicyInformation.privacyPolicyText,
                          style: TextStyle(height: 1.5),
                        ),

                        const SizedBox(height: 20),

                        // Link to full policy
                        InkWell(
                          onTap: _openPrivacyPolicy,
                          child: Row(
                            children: [
                              Icon(
                                Icons.open_in_new,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Read Full Privacy Policy',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Checkbox to confirm reading
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: CheckboxListTile(
                    value: _hasReadPolicy,
                    onChanged: (value) {
                      setState(() {
                        _hasReadPolicy = value ?? false;
                      });
                    },
                    title: const Text(
                      'I have read and understand the privacy policy',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),

                const SizedBox(height: 32),

                // Accept button
                FilledButton.icon(
                  onPressed: (_isAccepting || !_hasReadPolicy)
                      ? null
                      : _acceptPrivacyPolicy,
                  icon: _isAccepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                      _isAccepting ? 'Accepting...' : 'Accept and Continue'),
                ),

                const SizedBox(height: 16),

                // Decline button
                OutlinedButton.icon(
                  onPressed: _isAccepting ? null : _declinePrivacyPolicy,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side:
                        BorderSide(color: Theme.of(context).colorScheme.error),
                    textStyle: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 24),

                // Info text
                Text(
                  'Version: ${PrivacyPolicyInformation.privacyPolicyVersion}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
